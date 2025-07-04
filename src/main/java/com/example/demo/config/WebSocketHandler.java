package com.example.demo.config;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.example.demo.dto.PlayerInfo;
import com.example.demo.dto.Position;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Component
public class WebSocketHandler extends TextWebSocketHandler {
    
    // 연결된 플레이어들 저장
    private final Map<String, WebSocketSession> players = new ConcurrentHashMap<>();
    private final Map<String, PlayerInfo> playerInfos = new ConcurrentHashMap<>();
    
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
        String username = messageNode.get("username").asText();
        JsonNode characterNode = messageNode.get("character");
        
        // 플레이어 정보 저장
        PlayerInfo playerInfo = new PlayerInfo();
        playerInfo.setId(sessionId);
        playerInfo.setUsername(username);
        playerInfo.setPosition(new Position(0, 0, 0)); // 시작 위치
        playerInfo.setCharacter(characterNode);
        
        playerInfos.put(sessionId, playerInfo);
        
        // 다른 플레이어들에게 새 플레이어 알림
        broadcastToOthers(sessionId, createPlayerJoinedMessage(playerInfo));
        
        // 새 플레이어에게 기존 플레이어들 정보 전송
        sendExistingPlayers(session);
    }
    
    // 플레이어 움직임 처리
    private void handlePlayerMove(String sessionId, JsonNode messageNode) throws Exception {
        PlayerInfo playerInfo = playerInfos.get(sessionId);
        if (playerInfo != null) {
            JsonNode positionNode = messageNode.get("position");
            Position newPosition = new Position(
                positionNode.get("x").asDouble(),
                positionNode.get("y").asDouble(),
                positionNode.get("z").asDouble()
            );
            
            playerInfo.setPosition(newPosition);
            
            // 다른 플레이어들에게 위치 업데이트 브로드캐스트
            broadcastToOthers(sessionId, createPlayerMovedMessage(sessionId, newPosition));
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
        List<PlayerInfo> existingPlayers = playerInfos.values().stream()
            .filter(player -> !player.getId().equals(session.getId()))
            .collect(Collectors.toList());
        
        if (!existingPlayers.isEmpty()) {
            String message = createExistingPlayersMessage(existingPlayers);
            session.sendMessage(new TextMessage(message));
        }
    }
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String sessionId = session.getId();
        players.remove(sessionId);
        playerInfos.remove(sessionId);
        
        // 다른 플레이어들에게 퇴장 알림
        broadcastToOthers(sessionId, createPlayerLeftMessage(sessionId));
        
        System.out.println("플레이어 연결 해제: " + sessionId);
    }
    
    // 메시지 생성 메서드들
    private String createPlayerJoinedMessage(PlayerInfo playerInfo) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-joined");
        message.put("player", playerInfo);
        return mapper.writeValueAsString(message);
    }
    
    private String createPlayerMovedMessage(String playerId, Position position) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-moved");
        message.put("playerId", playerId);
        message.put("position", position);
        return mapper.writeValueAsString(message);
    }
    
    private String createExistingPlayersMessage(List<PlayerInfo> players) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "existing-players");
        message.put("players", players);
        return mapper.writeValueAsString(message);
    }
    
    private String createPlayerLeftMessage(String playerId) throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> message = new HashMap<>();
        message.put("type", "player-left");
        message.put("playerId", playerId);
        return mapper.writeValueAsString(message);
    }
}