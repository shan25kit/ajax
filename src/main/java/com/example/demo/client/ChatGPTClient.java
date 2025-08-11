package com.example.demo.client;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Component
public class ChatGPTClient {
	@Value("${openai.api.key}")
	private String apiKey;

	@Value("${openai.api.url}")
	private String apiUrl;
	
    // GitHub에 올릴 때는 이 방법 사용 (임시)
    /*
    private String apiKey = "sk-proj-여기에실제키입력";  // TODO: GitHub 올리기 전 삭제
    private String apiUrl = "https://api.openai.com/v1/chat/completions";
    */
private final RestTemplate restTemplate;
    
    public ChatGPTClient() {
        this.restTemplate = new RestTemplate();
    }
    
    // ChatGPT API 호출
    public String callChatGPT(String systemPrompt, String userMessage) {
        try {
            // 디버깅 정보 (필요시에만)
            System.out.println("API URL: " + apiUrl);
            System.out.println("요청 시작...");
            
            // HTTP 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);
            
            // 요청 본문 생성
            Map<String, Object> requestBody = createRequestBody(systemPrompt, userMessage);
            
            // API 호출
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, entity, Map.class);
            
            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("API 호출 성공!");
                return extractMessage(response.getBody());
            } else {
                System.out.println("예상치 못한 응답 코드: " + response.getStatusCode());
                return "죄송합니다. 일시적인 오류가 발생했습니다.";
            }
            
        } catch (HttpClientErrorException e) {
            System.out.println("클라이언트 오류 (4xx): " + e.getStatusCode());
            System.out.println("응답 본문: " + e.getResponseBodyAsString());
            return "요청에 문제가 있습니다.";
        } catch (HttpServerErrorException e) {
            System.out.println("서버 오류 (5xx): " + e.getStatusCode());
            return "서버에서 오류가 발생했습니다.";
        } catch (RestClientException e) {
            System.out.println("네트워크 오류: " + e.getMessage());
            return "네트워크 연결에 문제가 있습니다.";
        } catch (Exception e) {
            System.out.println("예상치 못한 오류: " + e.getMessage());
            e.printStackTrace(); // 디버깅용
            return "죄송합니다. 일시적인 오류가 발생했습니다.";
        }
    }
    
    // API 요청 본문 생성
    private Map<String, Object> createRequestBody(String systemPrompt, String userMessage) {
        // 메시지 배열 생성
        List<Map<String, String>> messages = Arrays.asList(
            Map.of("role", "system", "content", systemPrompt),
            Map.of("role", "user", "content", userMessage)
        );
        
        // 요청 본문
        return Map.of(
            "model", "gpt-3.5-turbo",
            "messages", messages,
            "max_tokens", 150,
            "temperature", 0.3
        );
    }
    
    // 응답에서 메시지 추출
    private String extractMessage(Map<String, Object> responseBody) {
    	try {
            List<Map<String, Object>> choices = (List<Map<String, Object>>) responseBody.get("choices");
            Map<String, Object> firstChoice = choices.get(0);
            Map<String, Object> message = (Map<String, Object>) firstChoice.get("message");
            String content = (String) message.get("content");
            
            // finish_reason 확인으로 끊김 감지
            String finishReason = (String) firstChoice.get("finish_reason");
            
            if ("length".equals(finishReason)) {
                System.out.println("경고: 응답이 토큰 제한으로 잘렸습니다.");
                // 끊어진 응답 처리
                return handleTruncatedResponse(content);
            } else {
                System.out.println("응답 완료: " + finishReason); // "stop"이면 정상 완료
                return content;
            }
            
        } catch (Exception e) {
            System.out.println("응답 파싱 오류: " + e.getMessage());
            return "응답을 처리하는 중 오류가 발생했습니다.";
        }

    	
    }

	private String handleTruncatedResponse(String content) {

		 if (content == null || content.trim().isEmpty()) {
		        return "응답이 너무 짧습니다.";
		    }
		    
		    // 마지막 완전한 문장까지만 반환 (한국어 기준)
		    String[] sentences = content.split("[.!?。！？]");
		    
		    if (sentences.length > 1) {
		        // 마지막 불완전한 문장 제거하고 완전한 문장들만 조합
		        StringBuilder result = new StringBuilder();
		        for (int i = 0; i < sentences.length - 1; i++) {
		            result.append(sentences[i].trim());
		            if (i < sentences.length - 2) {
		                result.append(". ");
		            }
		        }
		        return result.toString() + ".";
		    } else {
		        // 완전한 문장이 하나도 없으면 "..." 추가
		        return content.trim() + "...";
		    }
	}
    
    

}
