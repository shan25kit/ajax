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
        String systemPrompt = "당신은 친근하고 공감능력이 뛰어난 상담사입니다. 사용자의 감정을 이해하고 지지해주세요.";
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
            case "Anger":
                return "당신은 분노 조절 전문 상담사입니다. 분노 수용하고  건설적 표현으로 갈등 해결을 안내하세요. " +
                       "즉시 진정 기법과 장기 감정 관리 전략 제공하세요.";
                       
            case "Hope":
                return "당신은 우울/절망 전문 상담사입니다. 따뜻한 공감을 통해 작은 희망 발견하고 점진적 활성화될 수 있도록 도와주세요. " +
                       "행동을 증가하고 인지를 재구성으로 의미 회복 지원하세요.";
                       
            case "Calm":
                return "당신은 불안/두려움 전문 상담사입니다. 불안 정상화하고 점진적 노출하여 단계별로 극복할 수 있도록 도와주세요." +
                	   "즉시 진정법과 체계적 자신감 회복 전략 제공하세요.";
                
            case "Joy":
                return "당신은 긍정감정 전문 상담사입니다. 감사를 발견하고 강점 활용해 의미 있는 활동 안내하세요. " +
                       "작은 기쁨 축하하고 지속 가능한 행복 구축 지원하세요.";
                       
            case "Zen":
                return "당신은 마음챙김 전문 상담사입니다. 현재 순간 집중하고 감정 관찰해 내면 평화를 안내하세요. " +
                       "스트레스를 관리해 삶의 균형 찾기 지원하세요.";
                       
            default:
                return "당신은 친근하고 공감능력이 뛰어난 상담사입니다. 사용자의 감정을 이해하고 지지해주세요. " +
                        "따뜻하고 격려하는 톤으로 대화하며, 의학적 진단은 절대 하지 마세요.";
        }
    }
}