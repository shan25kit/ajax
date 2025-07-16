package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AIChatMessage {
    private String message;
    private String botType;
    
    // 응답용 필드
    private String response;
    private Long timestamp;
    
    // === 요청 생성 헬퍼 메서드 ===
    public static AIChatMessage createRequest(String message, String botType) {
    	AIChatMessage AIChatMessage = new AIChatMessage();
    	AIChatMessage.setMessage(message);
    	AIChatMessage.setBotType(botType);
        return AIChatMessage;
    }
    
    // === 응답 생성 헬퍼 메서드 ===
    public static AIChatMessage createResponse(String response) {
    	AIChatMessage AIChatMessage = new AIChatMessage();
    	AIChatMessage.setResponse(response.replace("\n", "<br>"));  // 기존 로직 유지
    	AIChatMessage.setTimestamp(System.currentTimeMillis());
        return AIChatMessage;
    }
}