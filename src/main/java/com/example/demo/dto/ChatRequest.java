package com.example.demo.dto;

import lombok.Data;

@Data
public class ChatRequest {
	private String message;
	private String botType;
}