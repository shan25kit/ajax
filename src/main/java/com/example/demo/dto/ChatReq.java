package com.example.demo.dto;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.stereotype.Component;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.Data;

@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
@Data
public class ChatReq {
	// ===== HTTP REQUEST 관련 정보 =====
	 private final HttpServletRequest chatReq;
	 private final HttpServletResponse chatResp;
	 private final HttpSession session;
	// ===== 채팅 REQUEST 필드들 =====
	    // 기본 채팅 정보
	   private int userId;
	   private String message;           // 사용자 입력 메시지
	   private String botType;           // "Anger Guide", "Hope Companion" 등
	    
	    // 세션 관리 정보
	   private String sessionId;
	   private int phase;                // 현재 단계 (1, 2, 3)
	   private Map<String, Object> context;
	   private LocalDateTime lastActiveAt;
	    
	    // ===== 채팅 RESPONSE 필드들 =====
	    // 응답 정보
	   private String response;          // AI 응답 메시지
	   private long timestamp;           // 응답 시간
	    
	    // 세션 상태 정보
	   private boolean phaseCompleted;   // 현재 단계 완료 여부
	   private boolean sessionCompleted; // 전체 세션 완료 여부
	   private Map<String, Object> updatedContext; // 업데이트된 컨텍스트
	    
	 
	    // 세션 설정
		/* private SessionOptions sessionOptions; */
	   // 세션 상태 관리
	   private boolean sessionActive;
	    
	 // ===== 생성자 - Request Scope 초기화 =====
	    public ChatReq(HttpServletRequest chatReq, HttpServletResponse chatResp) {
	        this.chatReq = chatReq;
	        this.chatResp = chatResp;
	        this.session = chatReq.getSession();
	        
	        initializeDefaults();
	    }

	private void initializeDefaults() {
		this.phase = 1;
        this.context = new HashMap<>();
        this.lastActiveAt = LocalDateTime.now();
        this.sessionActive = true;
        this.phaseCompleted = false;
        this.timestamp = System.currentTimeMillis();
		
	}
	    
// ===== 팩토리 메서드들 (정적 메서드) =====
    
    // 성공 응답 생성 (기존 호환성)
    public static Map<String, Object> successResponse(String response, int phase) {
        Map<String, Object> result = new HashMap<>();
        result.put("response", response.replace("\n", "<br>"));
        result.put("timestamp", System.currentTimeMillis());
        result.put("phase", phase);
        result.put("success", true);
        return result;
    }
    
    // 에러 응답 생성 (기존 호환성)
    public static Map<String, Object> errorResponse(String errorMessage) {
        Map<String, Object> result = new HashMap<>();
        result.put("response", "죄송합니다. " + errorMessage);
        result.put("timestamp", System.currentTimeMillis());
        result.put("success", false);
        result.put("error", errorMessage);
        return result;
    }
    
    // ===== 유틸리티 메서드들 =====
    
    // JSON 응답용 Map 변환
    public Map<String, Object> toResponseMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("message", message);
        map.put("response", response);
        map.put("botType", botType);
        map.put("phase", phase);
        map.put("phaseCompleted", phaseCompleted);
        map.put("sessionCompleted", sessionCompleted);
        map.put("timestamp", timestamp);
        map.put("sessionId", sessionId);
        map.put("userId", userId);
        
        return map;
    }    
}