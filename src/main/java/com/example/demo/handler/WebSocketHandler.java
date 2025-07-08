package com.example.demo.handler;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.example.demo.dto.Player;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Component
public class WebSocketHandler extends TextWebSocketHandler {
    
    // 연결된 플레이어들 저장
    private final Map<String, WebSocketSession> players = new ConcurrentHashMap<>();
    private final Map<String, Player> playerInfos = new ConcurrentHashMap<>();
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String sessionId = session.getId();
        players.put(sessionId, session);
        System.out.println("플레이어 연결: " + sessionId);
    }
    
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String sessionId = session.getId();
        String payload = message.getPayload();
        
        // JSON 메시지 파싱
        ObjectMapper mapper = new ObjectMapper();
        JsonNode messageNode = mapper.readTree(payload);
        String type = messageNode.get("type").asText();
        System.out.println(session);
       System.out.println(messageNode);
       
        switch (type) {
            case "join-map":
                handleJoinMap(session, messageNode);
                break;
            case "player-move":
                handlePlayerMove(sessionId, messageNode);
                break;
        }
    }
    
    // 맵 입장 처리
    private void handleJoinMap(WebSocketSession session, JsonNode messageNode) throws Exception {
        String sessionId = session.getId();
        int memberId = messageNode.get("memberId").asInt();
        String nickName = messageNode.get("nickName").asText();
        JsonNode avatarInfo = messageNode.get("avatarInfo"); 
        // 플레이어 정보 저장
        Player player = new Player();
        player.setId(sessionId);
        player.setMemberId(memberId);
        player.setNickName(nickName);
        player.setAvatarInfo(avatarInfo);
		 System.out.println(player);
		 
		Map<String, Double> initialPosition = new HashMap<>();
		initialPosition.put("x", 0.0);
		initialPosition.put("y", 0.0);
		initialPosition.put("z", 0.0);
		player.setPosition(initialPosition);
		
        
        playerInfos.put(sessionId, player);
        System.out.println("플레이어 저장 완료: " + nickName);
        
      // 1. 본인에게 player-joined 메시지 전송
        session.sendMessage(new TextMessage(createPlayerJoinedMessage(player)));

        // 2. 다른 플레이어들에게 새 플레이어 알림
        broadcastToOthers(sessionId, createPlayerJoinedMessage(player));

        // 3. 기존 플레이어들 정보 전송
        sendExistingPlayers(session);
        System.out.println("브로드캐스팅 완료");
    }
    
    // 플레이어 움직임 처리
    private void handlePlayerMove(String sessionId, JsonNode messageNode) throws Exception {
        Player player = playerInfos.get(sessionId);
        if (player != null) {
            JsonNode position = messageNode.get("position");
            
         // Map으로 위치 업데이트
            Map<String, Double> newPosition = new HashMap<>();
            newPosition.put("x", position.get("x").asDouble());
            newPosition.put("y", position.get("y").asDouble());
            newPosition.put("z", position.get("z").asDouble());
            
            player.updatePosition(newPosition);
            
            // 다른 플레이어들에게 위치 업데이트 브로드캐스트
            broadcastToOthers(sessionId, createPlayerMovedMessage(sessionId, player));
        }
    }
    
    // 다른 플레이어들에게 메시지 브로드캐스트
    private void broadcastToOthers(String excludeSessionId, String message) {
        players.entrySet().parallelStream()
            .filter(entry -> !entry.getKey().equals(excludeSessionId))
            .forEach(entry -> {
                try {
                    entry.getValue().sendMessage(new TextMessage(message));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
    }
    
	 // 기존 플레이어들 정보 전송 
     private void sendExistingPlayers(WebSocketSession session) throws Exception { 
     List<Player> existingPlayers = playerInfos.values().stream().filter(player ->
	 !player.getId().equals(session.getId())).toList();
	  
	  if (!existingPlayers.isEmpty()) { 
		  String message = createExistingPlayersMessage(existingPlayers); 
		  session.sendMessage(new TextMessage(message)); } }
	 
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String sessionId = session.getId();
        Player player = playerInfos.get(sessionId);
        players.remove(sessionId);
        playerInfos.remove(sessionId);
        
        // 다른 플레이어들에게 퇴장 알림
        broadcastToOthers(sessionId, createPlayerLeftMessage(sessionId));
        
        System.out.println("플레이어 연결 해제: " + sessionId);
        String nickName = player != null ? player.getNickName() : "Unknown";
        System.out.println("플레이어 연결 해제: " + nickName + " (" + sessionId + ")");
    }
    
    // 메시지 생성 메서드들
    private String createPlayerJoinedMessage(Player player) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-joined");
        message.put("player", player);
        return mapper.writeValueAsString(message);
    }
    
    private String createPlayerMovedMessage(String memberId, Player player) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-moved");
        message.put("memberId", memberId);
        message.put("position", player.getPositionForBroadcast());
        return mapper.writeValueAsString(message);
    }
    
    private String createExistingPlayersMessage(List<Player> players) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "existing-players");
        message.put("players", players);
        return mapper.writeValueAsString(message);
    }
    
    private String createPlayerLeftMessage(String memberId) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-left");
        message.put("memberId", memberId);
        return mapper.writeValueAsString(message);
    }

}