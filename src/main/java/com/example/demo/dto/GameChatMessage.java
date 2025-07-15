package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class GameChatMessage {
    private String type;
    private String nickName;
    private String message;
    private String mapName;
    private Integer memberId;
    private Long timestamp;
    private Boolean success;
    
 
    public static GameChatMessage createRequest(String type, String message) {
        GameChatMessage chat = new GameChatMessage();
        chat.setType(type);
        chat.setMessage(message);
        return chat;
    }
    
  
    public static GameChatMessage createMapResponse(String nickName, String message, String mapName, int memberId) {
        GameChatMessage chat = new GameChatMessage();
        chat.setType("chat-map");
        chat.setNickName(nickName);
        chat.setMessage(message);
        chat.setMapName(mapName);
        chat.setMemberId(memberId);
        chat.setTimestamp(System.currentTimeMillis());
        chat.setSuccess(true);
        return chat;
    }
    
   
    public static GameChatMessage createGlobalResponse(String nickName, String message, int memberId) {
        GameChatMessage chat = new GameChatMessage();
        chat.setType("chat-global");
        chat.setNickName(nickName);
        chat.setMessage(message);
        chat.setMapName(null); // 전체 공지는 맵 이름 없음
        chat.setMemberId(memberId);
        chat.setTimestamp(System.currentTimeMillis());
        chat.setSuccess(true);
        return chat;
    }
    
   
    public static GameChatMessage createError(String errorMessage) {
        GameChatMessage chat = new GameChatMessage();
        chat.setType("error");
        chat.setMessage(errorMessage);
        chat.setTimestamp(System.currentTimeMillis());
        chat.setSuccess(false);
        return chat;
    }
    

    public boolean isRequest() {
        return "chat-map".equals(type) || "chat-global".equals(type);
    }
    
  
    public boolean isResponse() {
        return timestamp != null && success != null;
    }
    
  
    public boolean isMapChat() {
        return "chat-map".equals(type);
    }
    
   
    public boolean isGlobalChat() {
        return "chat-global".equals(type);
    } 
    
}