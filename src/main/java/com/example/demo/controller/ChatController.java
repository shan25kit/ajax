package com.example.demo.controller;

import java.time.LocalDateTime;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

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

	public ChatController(ChatService chatService, Req req, MessagePreprocessingService messagePreprocessingService) {
		this.chatService = chatService;
		this.req = req;
		this.messagePreprocessingService = messagePreprocessingService;
	}

	@PostMapping("/message")
	@ResponseBody
	public ChatResponse chat(@RequestBody ChatRequest request) {
		System.out.println("받은 메시지: " + request.getMessage()); // 디버깅
		System.out.println("요청 시간: " + LocalDateTime.now());

		// rawMessage와 memberId 추출
		String rawMessage = request.getMessage();
		int memberId = req.getLoginedMember().getId();// 세션에서 memberId 가져오기

		// 전처리 서비스 호출
		ProcessedMessage processed = messagePreprocessingService.preprocessMessage(rawMessage, memberId);
		// 1. 오류 상황 처리
		if (processed.isHasError()) {
			return new ChatResponse(processed.getErrorMessage());
		}

		// 2. 긴급 상황 처리
		if (processed.isEmergency()) {
			return new ChatResponse(processed.getEmergencyMessage());
		}

		// 3. 정상 상황 - 기존 ChatService 호출
		String response = chatService.sendMessage(request.getMessage());
		return new ChatResponse(response);
	}

	@PostMapping("/message/{botType}")
	@ResponseBody
	public ChatResponse sendMessageWithRole(@PathVariable String botType, @RequestBody ChatRequest request) {
		System.out.println("봇타입: " + botType + " - 받은 메시지: " + request.getMessage());
		System.out.println("요청 시간: " + LocalDateTime.now());
		// rawMessage와 memberId 추출
		String rawMessage = request.getMessage();
		int memberId = req.getLoginedMember().getId();// 세션에서 memberId 가져오기

		// 전처리 서비스 호출
		ProcessedMessage processed = messagePreprocessingService.preprocessMessage(rawMessage, memberId);
		if (processed.isHasError()) {
			return new ChatResponse(processed.getErrorMessage());
		}

		if (processed.isEmergency()) {
			return new ChatResponse(processed.getEmergencyMessage());
		}

		// 정상 상황
		String response = chatService.sendMessageWithRole(request.getMessage(), botType);
		return new ChatResponse(response);
	}
	
}