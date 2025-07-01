package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.client.ChatGPTClient;

@Service
public class ChatService {
    
    private final ChatGPTClient chatGPTClient;
    
    public ChatService(ChatGPTClient chatGPTClient) {
        this.chatGPTClient = chatGPTClient;
    }
    
    // 기본 메시지 처리
    public String sendMessage(String userMessage) {
        String systemPrompt = "당신은 친근하고 도움이 되는 AI 어시스턴트입니다. 한국어로 답변해 주세요.";
        return chatGPTClient.callChatGPT(systemPrompt, userMessage);
    }
    
    // 역할별 메시지 처리
    public String sendMessageWithRole(String userMessage, String botType) {
        String systemPrompt = getSystemPrompt(botType);
        return chatGPTClient.callChatGPT(systemPrompt, userMessage);
    }
    
    // 봇 타입별 시스템 프롬프트 반환
    private String getSystemPrompt(String botType) {
        switch (botType) {
            case "productivity":
                return "당신은 개인 생산성 도우미입니다. 일정 관리, 할일 정리, 목표 달성을 도와주세요. " +
                       "친근하고 동기부여가 되는 톤으로 구체적이고 실행 가능한 조언을 제공하세요.";
                       
            case "health":
                return "당신은 건강 및 피트니스 코치입니다. 운동, 식단, 수면 등 건강 관리 조언을 해주세요. " +
                       "의학적 진단은 하지 말고, 일반적인 건강 조언과 동기부여에 집중하세요.";
                       
            case "language":
                return "당신은 언어 학습 도우미입니다. 문법 설명, 어휘 확장, 회화 연습을 친근하게 도와주세요.";
                
            case "finance":
                return "당신은 개인 금융 관리 어드바이저입니다. 가계부 관리, 저축, 투자 기본 조언을 해주세요. " +
                       "구체적 투자 추천보다는 일반적인 금융 교육에 집중하세요.";
                       
            case "counseling":
                return "당신은 친근하고 공감능력이 뛰어난 상담사입니다. 사용자의 감정을 이해하고 지지해주세요. " +
                       "따뜻하고 격려하는 톤으로 대화하며, 의학적 진단은 절대 하지 마세요.";
                       
            default:
                return "당신은 친근하고 도움이 되는 AI 어시스턴트입니다. 한국어로 답변해 주세요.";
        }
    }
}