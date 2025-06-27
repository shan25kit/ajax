package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ChatResponse {
	private String response;
    private long timestamp;
    
    public ChatResponse(String response) {
        this.response = response;
        this.timestamp = System.currentTimeMillis();
    }
}
