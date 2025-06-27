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
import com.example.demo.service.ChatService;

@Controller
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

	private final ChatService chatService;

	public ChatController(ChatService chatService) {
		this.chatService = chatService;
	}

	@PostMapping("/message")
	@ResponseBody
	public ChatResponse chat(@RequestBody ChatRequest request) {
		System.out.println("받은 메시지: " + request.getMessage()); // 디버깅
        System.out.println("요청 시간: " + LocalDateTime.now());
		String response = chatService.sendMessage(request.getMessage());
		return new ChatResponse(response);
	}
	   @PostMapping("/message/{botType}")
	    @ResponseBody
	    public ChatResponse sendMessageWithRole(@PathVariable String botType, 
	                                       @RequestBody ChatRequest request) {
	        System.out.println("봇타입: " + botType + " - 받은 메시지: " + request.getMessage());
	        System.out.println("요청 시간: " + LocalDateTime.now());
	        String response = chatService.sendMessageWithRole(request.getMessage(), botType);
	        return new ChatResponse(response);
	    }
}