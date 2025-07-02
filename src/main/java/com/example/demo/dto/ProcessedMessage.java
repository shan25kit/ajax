package com.example.demo.dto;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProcessedMessage {
	 // 원본 정보
    private String rawMessage;
    private int userId;
    private LocalDateTime timestamp;
    
    // 전처리 결과
    private String processedText;  
    private boolean isEmergency;
    private String emergencyMessage;
    private Set<String> detectedKeywords;
    private boolean hasError;            // 오류 여부
    private String errorMessage;   


/**
 * 안전한 메시지 처리 결과 생성
 */
public static ProcessedMessage safe(String rawMessage, String normalizedMessage) {
    return ProcessedMessage.builder()
        .rawMessage(rawMessage)
        .processedText(normalizedMessage)
        .isEmergency(false)
        .detectedKeywords(new HashSet<>())
        .timestamp(LocalDateTime.now())
        .hasError(false)
        .build();
}

/**
 * 긴급상황 메시지 처리 결과 생성
 */
public static ProcessedMessage emergency(String rawMessage, String normalizedMessage, 
                                       Set<String> detectedKeywords) {
	 String emergencyMessage = "당신의 생명은 소중하고 귀중합니다.\n" +
			    "전문 상담사들이 24시간 대기하고 있으니 지금 바로 연락해 주세요.\n\n" +
			    "🚨 24시간 언제든 연락 가능한 전문기관 🚨\n" +
			    "📞 생명의전화: 1588-9191\n" +
			    "📞 정신건강위기상담: 1577-0199\n" +
			    "📞 청소년전화: 1388 (청소년 전용)\n" +
			    "📞 응급상황: 119\n\n" +
			    "상담이 일시 중단됩니다. 전문기관을 통해 적절한 도움을 받으시기 바랍니다.";;
    return ProcessedMessage.builder()
        .rawMessage(rawMessage)
        .processedText(normalizedMessage)
        .isEmergency(true)
        .detectedKeywords(detectedKeywords != null ? detectedKeywords : new HashSet<>())
        .timestamp(LocalDateTime.now())
        .hasError(false)
        .emergencyMessage(emergencyMessage)
        .build();
}

/**
 * 오류 발생 시 처리 결과 생성
 */
public static ProcessedMessage error(String rawMessage, int userId, String errorMessage) {
    return ProcessedMessage.builder()
        .rawMessage(rawMessage)
        .userId(userId)
        .isEmergency(false)
        .detectedKeywords(new HashSet<>())
        .timestamp(LocalDateTime.now())
        .hasError(true)
        .errorMessage(errorMessage)
        .build();
}

}