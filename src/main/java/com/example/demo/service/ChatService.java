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
                return "당신은 분노 조절 전문 상담사입니다." +
                       "1~2문장으로 일상적으로 대화 나누며 감정 찾기, 개방형 질문으로 감정에 대한 원인 찾기, 감정 관리 기법을 제안하기";
                       
            case "Hope":
                return "당신은 우울/절망 전문 상담사입니다." +
                        "1~2문장으로 따뜻하게 공감하며 현재 상황 파악하기, 개방형 질문으로 작은 긍정적 요소 발견하기, 점진적 활성화 기법을 제안하기";
                       
            case "Calm":
                return "당신은 불안/두려움 전문 상담사입니다." +
                        "1~2문장으로 차분하게 대화하며 불안 상황 이해하기, 개방형 질문으로 두려움의 구체적 원인 탐색하기, 즉시 진정법과 단계별 극복 전략을 제안하기";
                
            case "Joy":
                return "당신은 긍정감정 전문 상담사입니다." +
                        "1~2문장으로 밝게 대화하며 현재 기분 확인하기, 개방형 질문으로 감사할 점과 강점 발견하기, 지속 가능한 행복 증진 활동을 제안하기";
                       
            case "Zen":
                return "당신은 마음챙김 전문 상담사입니다." +
                        "1~2문장으로 고요하게 대화하며 현재 마음 상태 확인하기, 개방형 질문으로 스트레스 요인과 감정 패턴 탐색하기, 마음챙김 기법과 균형 회복 방법을 제안하기";
                       
            default:
                return "당신은 친근하고 공감능력이 뛰어난 상담사입니다. 사용자의 감정을 이해하고 지지해주세요. " +
                "따뜻하고 격려하는 톤으로 대화하며, 의학적 진단은 절대 하지 마세요.";
}
    }
}