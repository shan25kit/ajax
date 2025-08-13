package com.example.demo.controller;

import java.time.LocalDateTime;

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
	    System.out.println("추출된 실제 감정: " + actualEmotion);
	    
	    // 감정 일치 확인
	    boolean emotionMatches = actualEmotion.equals(aiChatMessage.getEmotion());
	    
	    // 1. 감정이 일치하고 명확한 감정이 추출된 경우 (neutral 제외)
	    if (emotionMatches && !actualEmotion.equals("neutral")) {
	        aiChatMessage.setPhase(2); // 감정 확인 완료
	        aiChatMessage.saveEmotionToSession(); // 세션에 저장
	        
	        String confirmMessage = generateEmotionConfirmMessage(actualEmotion);
	        return AIChatMessage.createResponse(confirmMessage);
	    }
	    
	    // 2. 감정이 다르고 3회 이상 확인한 경우 - 맵 이동 제안
	    if (!emotionMatches && !actualEmotion.equals("neutral") && checkCount >= 3) {
	        String redirectMessage = generateRedirectSuggestion(actualEmotion);
	        return AIChatMessage.createResponse(redirectMessage);
	    }
	    
	    // 3. 5회 이상 확인해도 결론이 안 나는 경우 - 현재 맵 감정으로 진행
	    if (checkCount >= 5) {
	        aiChatMessage.setPhase(2); // 감정 확인 완료
	        aiChatMessage.saveEmotionToSession(); // 세션에 저장
	        
	        String forceMessage = "충분히 대화해보니 " + getEmotionDisplayName(aiChatMessage.getEmotion()) + 
	                            " 상담을 진행하는 것이 좋겠습니다. 상담을 시작하겠습니다.";
	        return AIChatMessage.createResponse(forceMessage);
	    }
	    
	    // 4. 계속 감정 확인 질문
	    String questionMessage = generateEmotionCheckQuestion(checkCount, botType);
	    return AIChatMessage.createResponse(questionMessage);
	}

	// 감정 확인 완료 메시지 생성
	private String generateEmotionConfirmMessage(String emotion) {
	    String emotionName = getEmotionDisplayName(emotion);
	    return emotionName + " 감정이 확인되었습니다. 이제 " + emotionName + " 상담을 시작하겠습니다.";
	}

	// 맵 이동 제안 메시지 생성
	private String generateRedirectSuggestion(String actualEmotion) {
	    String emotionName = getEmotionDisplayName(actualEmotion);
	    String mapName = getMapNameFromEmotion(actualEmotion);
	    
	    return "대화를 통해 " + emotionName + " 감정이 더 강하게 느껴집니다. " +
	           mapName + "으로 이동해서 전문 상담을 받아보시겠어요?";
	}

	// 점진적 감정 확인 질문 생성
	private String generateEmotionCheckQuestion(int checkCount, String botType) {
	    switch(checkCount) {
	        case 1:
	            return "안녕하세요! 오늘 어떤 일이 있으셨나요?";
	        case 2:
	            return "그 상황에서 어떤 기분이 드셨는지 좀 더 자세히 말씀해주세요.";
	        case 3:
	            return "지금 가장 강하게 느끼시는 감정은 무엇인가요?";
	        case 4:
	            return "마음 속 깊은 곳의 감정을 솔직하게 표현해보세요.";
	        default:
	            return "지금까지 말씀해주신 내용을 바탕으로 상담을 진행하겠습니다.";
	    }
	}
	
	// 감정명 표시용 변환
	private String getEmotionDisplayName(String emotion) {
	    switch(emotion) {
	        case "anger": return "분노";
	        case "sad": return "슬픔";
	        case "happy": return "기쁨";
	        case "anxiety": return "불안";
	        case "zen": return "평온";
	        default: return "시작 맵";
	    }
	}

	// 감정에 따른 맵 이름 반환
	private String getMapNameFromEmotion(String emotion) {
	    switch(emotion) {
	        case "anger": return "분노의 세계";
	        case "sad": return "슬픔의 공간";
	        case "happy": return "행복의 공간";
	        case "anxiety": return "불안의 공간";
	        case "zen": return "평온의 호수";
	        default: return "시작 맵";
	    }
	}
}