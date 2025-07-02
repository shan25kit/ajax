package com.example.demo.controller;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.ChatReq;
import com.example.demo.dto.ChatRequest;
import com.example.demo.dto.ChatResponse;
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
	private ChatReq chatReq;

	public ChatController(ChatService chatService, Req req,ChatReq chatReq, MessagePreprocessingService messagePreprocessingService) {
		this.chatService = chatService;
		this.req = req;
		this.chatReq = chatReq;
		this.messagePreprocessingService = messagePreprocessingService;
	}


	@PostMapping("/message/{botType}")
	@ResponseBody
	public ChatReq sendMessageWithRole(@PathVariable String botType, @RequestBody Map<String, String> request) {
		System.out.println("봇타입: " + botType + " - 받은 메시지: " + request.get("message"));
		System.out.println("요청 시간: " + LocalDateTime.now());
		
		// 1. ChatDTO에 요청 정보 설정 (자동 주입된 Request-Scoped Bean)
        chatReq.setMessage(request.get("message"));
        chatReq.setBotType(botType);
		// rawMessage와 userId 추출
		String rawMessage = request.get("message");
		int userId = req.getLoginedMember().getId();// 세션에서 userId 가져오기
		SessionContext sessionContext = sessionService.getOrCreateSession(userId, botType);
        if (sessionContext != null) {
        	ChatReq.setPhaseAndContext(sessionContext.getCurrentPhase(), sessionContext.getContext());
        	ChatReq.setSessionId(sessionContext.getSessionId());
        } else {
            // 새 세션 시작
        	ChatReq.initializeDefaults();
        	ChatReq.setSessionId(UUID.randomUUID().toString());
        }
		int phase;
		Map<String, Object> context;
		// 전처리 서비스 호출
		ProcessedMessage processed = messagePreprocessingService.preprocessMessage(rawMessage, userId);
		if (processed.isHasError()) {
			return new ChatReq(processed.getErrorMessage());
		}

		if (processed.isEmergency()) {
			
			return new ChatReq(processed.getEmergencyMessage());
		}

		// 정상 상황
		String response = chatService.sendMessageWithRole(request.getMessage(), botType, phase, context);
		return new ChatReq(response);
	}
	
}