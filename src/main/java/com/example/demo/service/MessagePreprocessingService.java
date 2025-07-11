package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import com.example.demo.dto.ProcessedMessage;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class MessagePreprocessingService {
	// 자해 관련 위험 키워드 관리
	private static final Set<String> SELF_HARM_KEYWORDS = Set.of("죽고싶어", "자살", "자해", "죽어버리고", "사라지고싶어", "칼", "독", "목매",
			"뛰어내리", "생을마감", "죽을래", "죽어야지", "자살시도", "목숨을끊");

	private static final List<Pattern> SELF_HARM_PATTERNS = List.of(Pattern.compile(".*죽.*(고싶|하고싶|을래|어야지).*"),
			Pattern.compile(".*자해.*(하고싶|할래|했어|하자).*"), Pattern.compile(".*사라지.*(고싶|을래|버리고).*"),
			Pattern.compile(".*끝내.*(고싶|버리고싶|야겠).*"), Pattern.compile(".*생을.*(마감|끝).*"));

	// 긍정적 표현 예외 (오탐지 방지)
	private static final List<Pattern> POSITIVE_EXCEPTIONS = List.of(Pattern.compile(".*죽을만큼.*(좋|행복|기뻐).*"),
			Pattern.compile(".*죽도록.*(사랑|좋아).*"), Pattern.compile(".*목숨.*(걸고|바쳐|소중).*"));

	public ProcessedMessage preprocessMessage(String rawMessage, int memberId) {

		try {
			String normalizedMessage = validateMessage(rawMessage);
			if (isPositiveException(normalizedMessage)) {
				return ProcessedMessage.safe(rawMessage, normalizedMessage);
			}
			Set<String> detectedKeywords = detectSelfHarmKeywords(normalizedMessage);
			boolean hasRiskyPattern = detectSelfHarmPatterns(normalizedMessage);
			boolean isEmergency = !detectedKeywords.isEmpty() || hasRiskyPattern;

			if (isEmergency) {
				System.err.println("자해 위험 감지 - 키워드: " + detectedKeywords + ", 패턴매칭: " + hasRiskyPattern);

				ProcessedMessage emergencyResult = ProcessedMessage.emergency(rawMessage, normalizedMessage,
						detectedKeywords);
				handleEmergencyCase(memberId, emergencyResult);

				return emergencyResult;
			}

			log.debug("안전한 메시지 처리 완료 - 사용자: {}", memberId);
			return ProcessedMessage.safe(rawMessage, normalizedMessage);
		} catch (IllegalArgumentException e) {
			log.warn("메시지 검증 실패 - 사용자: {}, 오류: {}", memberId, e.getMessage());
			return ProcessedMessage.error(rawMessage, memberId, e.getMessage());
		} catch (Exception e) {
			log.error("메시지 전처리 중 예상치 못한 오류 - 사용자: {}", memberId, e);
			return ProcessedMessage.error(rawMessage, memberId, "메시지 처리 중 오류가 발생했습니다.");
		}

	}

	private String validateMessage(String message) {
		if (message == null || message.trim().isEmpty()) {
			throw new IllegalArgumentException("메시지가 비어있습니다.");
		}
		if (message.length() > 1000) {
			throw new IllegalArgumentException("메시지가 너무 깁니다.");
		}
		return message.toLowerCase().replaceAll("\\s+", "") // 공백 제거
				.replaceAll("[!@#$%^&*(),.?\":{}|<>]", "") // 특수문자 제거
				.replaceAll("ㅋ+", "") // 웃음 표현 제거
				.replaceAll("ㅠ+", "") // 울음 표현 정규화
				.replaceAll("ㅜ+", ""); // 울음 표현 정규화
	}

	private boolean isPositiveException(String message) {
		return POSITIVE_EXCEPTIONS.stream().anyMatch(pattern -> pattern.matcher(message).matches());
	}

	private Set<String> detectSelfHarmKeywords(String message) {
		Set<String> detectedKeywords = new HashSet<>();

		for (String keyword : SELF_HARM_KEYWORDS) {
			if (message.contains(keyword)) {
				detectedKeywords.add(keyword);
				System.err.println("자해 키워드 감지: '" + keyword + "'");
			}
		}

		return detectedKeywords;
	}

	private boolean detectSelfHarmPatterns(String message) {
		for (Pattern pattern : SELF_HARM_PATTERNS) {
			if (pattern.matcher(message).matches()) {
				System.err.println("자해 패턴 감지: " + message);
				return true;
			}
		}
		return false;
	}

	/* 로그생성용 */
	private void handleEmergencyCase(int memberId, ProcessedMessage result) {
		System.err.println("=== 긴급상황 감지 ===");
		System.err.println("사용자: " + memberId);
		System.err.println("원본 메시지: " + result.getRawMessage());
		System.err.println("감지된 키워드: " + result.getDetectedKeywords());
		System.err.println("시간: " + LocalDateTime.now());

	}
}
