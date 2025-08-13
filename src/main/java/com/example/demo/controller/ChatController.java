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
	    
	    if (checkCount == 1) {
	        // 1차: 키워드 분석 처리
	        System.out.println("1차 키워드 분석 - 추출된 실제 감정: " + actualEmotion);
	        
	        // 감정 일치 확인
	        boolean emotionMatches = actualEmotion.equals(aiChatMessage.getEmotion());
	        
	        // 감정이 일치하고 명확한 감정이 추출된 경우 (neutral 제외)
	        if (emotionMatches && !actualEmotion.equals("neutral")) {
	            aiChatMessage.setPhase(2); // 감정 확인 완료
	            aiChatMessage.saveEmotionToSession(); // 세션에 저장
	            
	            String confirmMessage = generateEmotionConfirmMessage(actualEmotion);
	            return AIChatMessage.createResponse(confirmMessage);
	        }
	        
	        // 1차에서 확정되지 않으면 2차 이모티콘 선택으로 진행
	        AIChatMessage response = AIChatMessage.createResponse("감정을 선택해주세요.");
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
	                String redirectMessage = generateRedirectSuggestion(selectedEmotion);
	                return AIChatMessage.createResponse(redirectMessage);
	            }
	        }
	        
	        // 유효하지 않은 선택인 경우 현재 맵으로 강제 진행
	        aiChatMessage.setPhase(2);
	        aiChatMessage.saveEmotionToSession();
	        
	        String forceMessage = "현재 " + getEmotionDisplayName(aiChatMessage.getEmotion()) + 
	                            " 상담실에서 상담을 진행하겠습니다.";
	        return AIChatMessage.createResponse(forceMessage);
	        
	    } else {
	        // 3회 이상 (안전장치)
	        aiChatMessage.setPhase(2);
	        aiChatMessage.saveEmotionToSession();
	        
	        String forceMessage = "현재 맵에서 상담을 진행하겠습니다.";
	        return AIChatMessage.createResponse(forceMessage);
	    }
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
	
	private boolean isValidEmotion(String emotion) {
	    return Arrays.asList("anger", "sad", "happy", "anxiety", "zen").contains(emotion);
	}
}