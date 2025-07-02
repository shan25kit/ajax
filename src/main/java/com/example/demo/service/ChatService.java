package com.example.demo.service;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.example.demo.client.ChatGPTClient;

@Service
public class ChatService {
    
    private final ChatGPTClient chatGPTClient;
    
    
    public ChatService(ChatGPTClient chatGPTClient) {
        this.chatGPTClient = chatGPTClient;
    }
    

    // 역할별 메시지 처리
    public String sendMessageWithRole(String userMessage, String botType, int phase, Map<String, Object> context) {
        String systemPrompt = getSystemPrompt(botType,phase,context);
        return chatGPTClient.callChatGPT(systemPrompt, userMessage);
    }
 // CBT 기반 단계별 상세 프롬프트 시스템
    private String getSystemPrompt(String botType, int phase, Map<String, Object> context) {
        String basePersonality = getBotPersonality(botType);
        
        switch (phase) {
            case 1: // 감정 식별 단계 (CBT: Emotional Awareness)
                return basePersonality + getCBTPhase1Prompt(botType, context);
                
            case 2: // 인지 탐색 단계 (CBT: Cognitive Assessment) 
                return basePersonality + getCBTPhase2Prompt(botType, context);
                
            case 3: // 개입 전략 단계 (CBT: Intervention Planning)
                return basePersonality + getCBTPhase3Prompt(botType, context);
                
            default:
                return basePersonality + "CBT 모델을 기반으로 사용자를 도와주세요.";
        }
    }

    // Phase 1: CBT 기반 감정 식별
    private String getCBTPhase1Prompt(String botType, Map<String, Object> context) {
        return "【CBT 1단계: 감정 찾기】" +
               "• 구체적인 감정 이름과 강도(1-10) 파악하기 " +
               "• 감정을 판단하지 말고 있는 그대로 수용하며 탐색하기";
    }

    // Phase 2: CBT 기반 인지 탐색  
    private String getCBTPhase2Prompt(String botType, Map<String, Object> context) {
        String emotion = (String) context.getOrDefault("emotion", "감정");
        
        return "【CBT 2단계: 이유 찾기】" +
               String.format("• %s을(를) 느끼게 된 이유 찾기 ", emotion) +
               "• 인지 왜곡 패턴 식별하기 (흑백사고, 재앙적 사고, 개인화 등) " +
               "• 생각-감정-행동의 악순환 고리 파악하기 " +
               "• '그때 어떤 생각이 드셨나요?', '가장 힘든 생각은 무엇인가요?' 질문 활용 " +
               "• 사고의 현실성과 도움 정도 함께 평가하기";
    }

    // Phase 3: CBT 기반 개입 전략
    private String getCBTPhase3Prompt(String botType, Map<String, Object> context) {
        String emotion = (String) context.getOrDefault("emotion", "감정");
        String causes = (String) context.getOrDefault("causes", "원인");
        
        return "【CBT 3단계: 즉시 실행 가능한 개입 전략 제안】" +
               String.format("• %s 관리를 위한 인지 재구성 기법 제안 ", emotion) +
               String.format("• %s 해결을 위한 구체적 행동 계획 수립 ", causes) +
               "• 즉시 활용 가능한 대처 기술 안내 (호흡법, 이완기법 등) " +
               "• 사고 기록표나 행동 실험 계획 제안 " +
               "• 일상에서 실천 가능한 작은 단계부터 시작하도록 안내 " +
               "• 효과 측정 방법과 후속 계획 함께 논의";
    }
    private String getBotPersonality(String botType) {
        switch (botType) {
            case "Anger Guide":
                return "분노 조절 CBT 전문가로서 ";
                
            case "Hope Companion": 
                return "우울증 치료 CBT 전문가로서 ";
                
            case "Calm Navigator":
                return "불안장애 치료 CBT 전문가로서 ";
                
            case "Joy Coach":
                return "긍정심리 CBT 전문가로서 ";
                
            case "Zen Guide":
                return "스트레스 관리 CBT 전문가로서 ";
                
            default:
                return "CBT 기반 상담 전문가로서 ";
        }
    }
	
}