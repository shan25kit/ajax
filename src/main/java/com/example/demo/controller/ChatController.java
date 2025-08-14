package com.example.demo.controller;

import java.time.LocalDateTime;
import java.util.Arrays;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.AIChatMessage;
import com.example.demo.dto.ProcessedMessage;
import com.example.demo.dto.Req;
import com.example.demo.service.ChatService;
import com.example.demo.service.MessagePreprocessingService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

	private final ChatService chatService;
	private MessagePreprocessingService messagePreprocessingService;
	private Req req;
	private AIChatMessage aiChatMessage;

	public ChatController(ChatService chatService, Req req, MessagePreprocessingService messagePreprocessingService,
			AIChatMessage aiChatMessage) {
		this.chatService = chatService;
		this.req = req;
		this.messagePreprocessingService = messagePreprocessingService;
		this.aiChatMessage = aiChatMessage;
	}

	@PostMapping("/message")
	@ResponseBody
	public AIChatMessage chat(@RequestBody AIChatMessage request) {
		System.out.println("받은 메시지: " + request.getMessage()); // 디버깅
		System.out.println("요청 시간: " + LocalDateTime.now());

		// rawMessage와 memberId 추출
		String rawMessage = request.getMessage();
		int memberId = req.getLoginedMember().getId();// 세션에서 memberId 가져오기

		// 전처리 서비스 호출
		ProcessedMessage processed = messagePreprocessingService.preprocessMessage(rawMessage, memberId);
		// 1. 오류 상황 처리
		if (processed.isHasError()) {
			return AIChatMessage.createResponse(processed.getErrorMessage());
		}

		// 2. 긴급 상황 처리
		if (processed.isEmergency()) {
			return AIChatMessage.createResponse(processed.getEmergencyMessage());
		}

		// 3. 정상 상황 - 기존 ChatService 호출
		String response = chatService.sendMessage(request.getMessage());
		return AIChatMessage.createResponse(response);
	}

	@PostMapping("/message/{botType}")
	@ResponseBody
	public AIChatMessage sendMessageWithRole(@PathVariable String botType, @RequestBody AIChatMessage request) {
		HttpSession session = aiChatMessage.getSession();
		if (session != null) {
			Integer sessionPhase = (Integer) session.getAttribute("phase");
			String sessionEmotion = (String) session.getAttribute("verifiedEmotion");
			Integer sessionCheckCount = (Integer) session.getAttribute("emotionCheckCount");

			if (sessionPhase != null && sessionPhase == 2 && sessionEmotion != null) {
				aiChatMessage.setPhase(2);
				aiChatMessage.setEmotion(sessionEmotion);
				System.out.println("세션에서 상담 상태 복원: phase=" + sessionPhase + ", emotion=" + sessionEmotion);
			}
			if (sessionCheckCount != null) {
	            aiChatMessage.setEmotionCheckCount(sessionCheckCount);
	            System.out.println("세션에서 emotionCheckCount 복원: " + sessionCheckCount);
	        }
		}
		System.out.println("봇타입: " + botType + " - 받은 메시지: " + request.getMessage());
		System.out.println("요청 시간: " + LocalDateTime.now());
		// rawMessage와 memberId 추출
		String rawMessage = request.getMessage();
		int memberId = req.getLoginedMember().getId();// 세션에서 memberId 가져오기

		if (aiChatMessage.getEmotion() == null) {
			String emotion = aiChatMessage.extractEmotionFromBotType(botType);
			aiChatMessage.setEmotion(emotion);
			System.out.println("현재 맵 감정 설정: " + emotion);
		}

		// 전처리 서비스 호출
		ProcessedMessage processed = messagePreprocessingService.preprocessMessage(rawMessage, memberId);
		if (processed.isHasError()) {
			return AIChatMessage.createResponse(processed.getErrorMessage());
		}

		if (processed.isEmergency()) {
			return AIChatMessage.createResponse(processed.getEmergencyMessage());
		}

		// ✨ 맵 이동 선택 대기 중인지 체크
		if (aiChatMessage.isWaitingForRedirectChoice()) {
			return handleRedirectChoice(rawMessage, botType);
		}

		if (aiChatMessage.getPhase() == 1) {
			// PHASE 1: 감정 확인 단계
			String actualEmotion = aiChatMessage.extractActualEmotion(rawMessage);
			System.out.println("추출된 실제 감정: " + actualEmotion);
			return handleEmotionCheck(actualEmotion, rawMessage, botType);

		}
		// 정상 상황
		String response = chatService.sendMessageWithRole(request.getMessage(), botType);
		return AIChatMessage.createResponse(response);
	}

	private AIChatMessage handleEmotionCheck(String actualEmotion, String rawMessage, String botType) {
		// emotionCheckCount 증가
		aiChatMessage.setEmotionCheckCount(aiChatMessage.getEmotionCheckCount() + 1);
		int checkCount = aiChatMessage.getEmotionCheckCount();

		System.out.println("감정 확인 횟수: " + checkCount + "회");
		System.out.println("현재 맵 감정: " + aiChatMessage.getEmotion());

		if (checkCount == 1) {
			// 1차: 키워드 분석 처리
			System.out.println("1차 키워드 분석 - 추출된 실제 감정: " + actualEmotion);

			// 감정 일치 확인
			boolean emotionMatches = actualEmotion.equals(aiChatMessage.getEmotion());

			// 감정이 일치하고 명확한 감정이 추출된 경우 (neutral 제외)
			if (!actualEmotion.equals("neutral") && emotionMatches) {
				aiChatMessage.setPhase(2); // 감정 확인 완료
				aiChatMessage.saveEmotionToSession(); // 세션에 저장

				String confirmMessage = generateEmotionConfirmMessage(actualEmotion);
				return AIChatMessage.createResponse(confirmMessage);
			}

			// 1차에서 확정되지 않으면 2차 이모티콘 선택으로 진행
			AIChatMessage response = AIChatMessage.createResponse("지금 어떤 감정을 느끼나요?");
			response.setMessageType("emotion_select");
			return response;

		} else if (checkCount == 2) {
			// 2차: 직접 감정 선택 받음
			String selectedEmotion = rawMessage; // "anger", "sad", "happy", "anxiety", "zen"
			System.out.println("2차 선택된 감정: " + selectedEmotion);

			// 유효한 감정인지 확인
			if (isValidEmotion(selectedEmotion)) {
				boolean emotionMatches = selectedEmotion.equals(aiChatMessage.getEmotion());

				if (emotionMatches) {
					// 감정 일치 - 상담 시작
					aiChatMessage.setPhase(2);
					aiChatMessage.saveEmotionToSession();

					String confirmMessage = generateEmotionConfirmMessage(selectedEmotion);
					return AIChatMessage.createResponse(confirmMessage);
				} else {
					// 감정 불일치 - 맵 이동 제안
					aiChatMessage.setEmotion(selectedEmotion);
					aiChatMessage.setWaitingForRedirectChoice(true);
					String redirectMessage = generateRedirectSuggestion(selectedEmotion);
					AIChatMessage response = AIChatMessage.createResponse(redirectMessage);
					response.setMessageType("redirect_choice");
					return response;
				}
			}

			// 유효하지 않은 선택인 경우 현재 맵으로 강제 진행
			String originalEmotion = aiChatMessage.extractEmotionFromBotType(botType);
			aiChatMessage.setEmotion(originalEmotion); // 원래 감정으로 복원
			aiChatMessage.setPhase(2);
			aiChatMessage.saveEmotionToSession();

			String forceMessage = "현재 " + getEmotionDisplayName(originalEmotion) + " 감정으로 상담을 진행하겠습니다.";
			return AIChatMessage.createResponse(forceMessage);

		} else {
			// 3회 이상 (안전장치)
			String originalEmotion = aiChatMessage.extractEmotionFromBotType(botType);
			aiChatMessage.setEmotion(originalEmotion); // 원래 감정으로 복원
			aiChatMessage.setPhase(2);
			aiChatMessage.saveEmotionToSession();

			String forceMessage = "현재 감정으로 상담을 진행하겠습니다.";
			return AIChatMessage.createResponse(forceMessage);
		}
	}

	// 감정 맵 추천 이동 처리
	private AIChatMessage handleRedirectChoice(String choice, String botType) {
		// 플래그 초기화
		aiChatMessage.setWaitingForRedirectChoice(false);
		aiChatMessage.setPhase(2);

		if ("yes".equals(choice)) {
			aiChatMessage.saveEmotionToSession();
			// 맵 이동 처리
			AIChatMessage response = AIChatMessage.createResponse("해당 감정 맵으로 이동합니다.");
			response.setMessageType("map_redirect"); // 프론트엔드에서 이동 처리용
			response.setEmotion(aiChatMessage.getEmotion());
			return response;
		} else {
			String originalEmotion = aiChatMessage.extractEmotionFromBotType(botType);
			aiChatMessage.setEmotion(originalEmotion);
			aiChatMessage.saveEmotionToSession();
			// 현재 맵에서 상담 계속
			return AIChatMessage.createResponse("현재 맵에서 상담을 계속하겠습니다.");
		}
	}

	// 감정 확인 완료 메시지 생성
	private String generateEmotionConfirmMessage(String emotion) {
		switch (emotion) {
		case "anger":
			return "화가 나는 상황이셨군요. 마음이 많이 불편하셨을 것 같아요. 함께 이야기해볼까요?";
		case "sad":
			return "힘든 시간을 보내고 계시는군요. 천천히 이야기 나누어봐요.";
		case "happy":
			return "기분 좋은 일이 있으셨나봐요! 더 자세히 들어보고 싶어요.";
		case "anxiety":
			return "불안한 마음이 드시는군요. 차근차근 함께 살펴볼게요.";
		case "zen":
			return "마음의 평화를 찾고 계시는군요. 편안하게 대화해봐요.";
		default:
			return "편안하게 이야기 나누어봐요.";
		}
	}

	// 맵 이동 제안 메시지 생성
	private String generateRedirectSuggestion(String actualEmotion) {
		String emotionName = getEmotionDisplayName(actualEmotion);
		String mapName = getMapNameFromEmotion(actualEmotion);

		return "대화를 통해 " + emotionName + " 감정이 더 강하게 느껴집니다. " + mapName + "으로 이동해서 전문 상담을 받아보시겠어요?";
	}

	// 감정명 표시용 변환
	private String getEmotionDisplayName(String emotion) {
		switch (emotion) {
		case "anger":
			return "분노";
		case "sad":
			return "슬픔";
		case "happy":
			return "기쁨";
		case "anxiety":
			return "불안";
		case "zen":
			return "평온";
		default:
			return "시작 맵";
		}
	}

	// 감정에 따른 맵 이름 반환
	private String getMapNameFromEmotion(String emotion) {
		switch (emotion) {
		case "anger":
			return "분노의 세계";
		case "sad":
			return "슬픔의 공간";
		case "happy":
			return "행복의 공간";
		case "anxiety":
			return "불안의 공간";
		case "zen":
			return "평온의 호수";
		default:
			return "시작 맵";
		}
	}

	private boolean isValidEmotion(String emotion) {
		return Arrays.asList("anger", "sad", "happy", "anxiety", "zen").contains(emotion);
	}
}