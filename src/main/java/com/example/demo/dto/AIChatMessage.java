package com.example.demo.dto;

import java.util.Arrays;

import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.annotation.JsonInclude;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AIChatMessage {
	private String message;
	private String botType;
	private String messageType = "normal"; // "normal", "emotion_select", "redirect_choice"
	// 응답용 필드
	private String response;
	private Long timestamp;
	// 감정분석 필드
	private String emotion;
	private int emotionCheckCount;
	// 상담 단계
	private int phase = 1;

	private HttpServletRequest request;
	private HttpSession session;

	public AIChatMessage(HttpServletRequest request) {
		this.request = request;
		this.session = request.getSession();

		// 세션에서 감정 정보 복원
		this.emotion = (String) session.getAttribute("verifiedEmotion");
		if (this.emotion == null) {
			this.emotionCheckCount = 0;
		}

		request.setAttribute("aiChatMessage", this);
	}

	public String extractEmotionFromBotType(String botType) {
		switch (botType) {
		case "Anger":
			return "anger";
		case "Joy":
			return "happy";
		case "Hope":
			return "sad";
		case "Calm":
			return "anxiety";
		case "Zen":
			return "zen";
		default:
			return "unknown";
		}
	}

	public void saveEmotionToSession() {
		if (emotion != null) {
			session.setAttribute("verifiedEmotion", emotion);
		}
	}

	public String extractActualEmotion(String message) {
		if (message == null || message.trim().isEmpty()) {
			return "neutral";
		}

		String lowerMessage = message.toLowerCase();

		// 분노 관련 키워드
		String[] angerKeywords = { "화나", "짜증", "분노", "열받", "빡쳐", "억울", "분해", "약오르", "기가막혀", "열불나" };
		if (Arrays.stream(angerKeywords).anyMatch(lowerMessage::contains)) {
			return "anger";
		}

		// 우울/절망 관련 키워드
		String[] sadKeywords = { "우울", "슬퍼", "절망", "힘들어", "지쳐", "포기", "의미없", "허무", "외로워", "눈물", "죽고싶" };
		if (Arrays.stream(sadKeywords).anyMatch(lowerMessage::contains)) {
			return "sad";
		}

		// 불안/두려움 관련 키워드
		String[] anxietyKeywords = { "불안", "걱정", "두려워", "무서워", "떨려", "긴장", "초조", "공포", "겁나", "스트레스" };
		if (Arrays.stream(anxietyKeywords).anyMatch(lowerMessage::contains)) {
			return "anxiety";
		}

		// 긍정 감정 관련 키워드
		String[] happyKeywords = { "기뻐", "행복", "좋아", "즐거워", "신나", "만족", "감사", "뿌듯", "성취", "희망" };
		if (Arrays.stream(happyKeywords).anyMatch(lowerMessage::contains)) {
			return "happy";
		}

		// 평온/차분 관련 키워드
		String[] zenKeywords = { "평온", "차분", "여유", "편안", "고요", "안정", "평화", "릴랙스", "휴식", "명상", "조용" };
		if (Arrays.stream(zenKeywords).anyMatch(lowerMessage::contains)) {
			return "zen";
		}

		return "neutral";
	}

	public boolean needsEmotionVerification() {
		return emotion != null && !emotion.equals(extractEmotionFromBotType(botType));
	}

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
		AIChatMessage.setResponse(response.replace("\n", "<br>")); // 기존 로직 유지
		AIChatMessage.setTimestamp(System.currentTimeMillis());
		AIChatMessage.setMessageType("normal");
		return AIChatMessage;
	}
}