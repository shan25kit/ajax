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
	private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
	private final Map<String, Player> playerSessions = new ConcurrentHashMap<>();

	@Override
	public void afterConnectionEstablished(WebSocketSession session) throws Exception {
		String sessionId = session.getId();
		sessions.put(sessionId, session);
		System.out.println("플레이어 연결: " + sessionId);
	}

	@Override
	protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
		String sessionId = session.getId();
		System.out.println(sessionId);
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
		case "change-map": 
			handleMapChange(session, messageNode);
			break;
		case "chat-inMap": 
			handleChatInMap(session, messageNode);
			break;
		case "chat-global": 
			handleChatGlobal(session, messageNode);
			break;
			
		}
	}

	// 맵 입장 처리
	private void handleJoinMap(WebSocketSession session, JsonNode messageNode) throws Exception {
		int memberId = messageNode.get("memberId").asInt();
		String sessionId = session.getId();
		// ✅ 올바른 기존 세션 확인: 같은 memberId를 가진 다른 세션 찾기
		String existingSessionId = playerSessions.entrySet().stream()
				.filter(entry -> entry.getValue().getMemberId() == memberId)
				.filter(entry -> !entry.getKey().equals(sessionId)) // 현재 세션 제외
				.map(Map.Entry::getKey).findFirst().orElse(null);

		if (existingSessionId != null) {
			WebSocketSession existingSession = sessions.get(existingSessionId);
			if (existingSession != null) {
				System.out.println("기존 세션 발견, 강제 종료: " + existingSessionId);
				existingSession.sendMessage(new TextMessage(createForceLogoutMessage()));
				existingSession.close(); // afterConnectionClosed 자동 호출됨
			}
		}
		String nickName = messageNode.get("nickName").asText();
		JsonNode avatarInfo = messageNode.get("avatarInfo");
		String currentMap = messageNode.get("currentMap").asText();
		
		// 플레이어 정보 저장
		Player player = new Player();
		player.setSessionId(sessionId);
		player.setMemberId(memberId);
		player.setNickName(nickName);
		player.setAvatarInfo(avatarInfo);
		player.setCurrentMap(currentMap);

		Map<String, Double> initialPosition = new HashMap<>();
		initialPosition.put("x", 2400.0);
		initialPosition.put("y", 0.0);
		initialPosition.put("z", 1800.0);

		player.setPosition(initialPosition);

		playerSessions.put(sessionId, player);
		System.out.println("플레이어 저장 완료: " + player);

		// 1. 본인에게 player-joined 메시지 전송
		session.sendMessage(new TextMessage(createPlayerJoinedMessage(player)));

		// 2. 다른 플레이어들에게 새 플레이어 알림
		broadcastToSameMap(sessionId, createPlayerJoinedMessage(player));

		// 3. 기존 플레이어들 정보 전송
		sendExistingPlayers(session);
		System.out.println("브로드캐스팅 완료");
	}

	// 플레이어 움직임 처리
	private void handlePlayerMove(String sessionId, JsonNode messageNode) throws Exception {
		Player player = playerSessions.get(sessionId);
		if (player != null) {
			JsonNode position = messageNode.get("position");
			JsonNode rotation = messageNode.get("rotation"); 
			// Map으로 위치 업데이트
			Map<String, Double> newPosition = new HashMap<>();
			newPosition.put("x", position.get("x").asDouble());
			newPosition.put("y", position.get("y").asDouble());
			newPosition.put("z", position.get("z").asDouble());

			player.updatePosition(newPosition);
			 if (rotation != null) {
		            Map<String, Double> newRotation = new HashMap<>();
		            newRotation.put("x", rotation.get("x").asDouble());
		            newRotation.put("y", rotation.get("y").asDouble());
		            newRotation.put("z", rotation.get("z").asDouble());
		            
		            player.updateRotation(newRotation); // Player 클래스에 메서드 추가 필요
		        }
			// 다른 플레이어들에게 위치 업데이트 브로드캐스트
			broadcastToOthers(sessionId, createPlayerMovedMessage(sessionId, player));
		}
	}

	private void handleMapChange(WebSocketSession session, JsonNode messageNode) throws Exception {
		System.out.println("=== 맵 변경 요청 ===");
		System.out.println("전체 메시지: " + messageNode);
		JsonNode targetMapNode = messageNode.get("targetMap");
		String sessionId = session.getId();
		if (targetMapNode != null) {
			String targetMap = targetMapNode.asText();
			System.out.println("targetMap: " + targetMap);
			Player player = playerSessions.get(sessionId);
			System.out.println(player);
			if (player != null) {
				// 1. 현재 맵에서 퇴장
				broadcastToPlayersInMap(player.getCurrentMap(), sessionId, createPlayerLeftMapMessage(player));
				// 2. 플레이어 맵 정보 업데이트
				player.setCurrentMap(targetMap);
				System.out.println(player.getCurrentMap());
				playerSessions.put(sessionId, player);
				// 3. 새로운 맵에 입장
				broadcastToPlayersInMap(targetMap, sessionId, createPlayerEnteredMapMessage(player));
				// 4. 본인에게 성공 메시지
				session.sendMessage(new TextMessage(createMapChangeSuccessMessage(targetMap)));
			}
		} else {
			System.out.println("targetMap을 찾을 수 없음!");
		}
	}
	// 1. 맵별 채팅 처리
	private void handleChatInMap(WebSocketSession session, JsonNode messageNode) throws Exception {
		String sessionId = session.getId();
	    Player player = playerSessions.get(sessionId);
	    String CurrentMap = player.getCurrentMap();
	    System.out.println("현재 플레이어 맵: " + CurrentMap);
	    
	    if (player != null) {
	        String message = messageNode.get("message").asText();
	        String chatMessage = createChatMessage(player, message, "chat-inMap");
	        System.out.println(chatMessage);
	     // 나에게 브로드캐스트
	        session.sendMessage(new TextMessage(chatMessage));
	        // 같은 맵의 다른 플레이어들에게 브로드캐스트
	        broadcastToPlayersInMap(CurrentMap, sessionId, chatMessage);
	        
	        System.out.println("맵 채팅 [" + CurrentMap + "] " + player.getNickName() + ": " + message);
	    }
	}

	// 2. 전체 공지 처리
	private void handleChatGlobal(WebSocketSession session, JsonNode messageNode) throws Exception {
	    Player player = playerSessions.get(session.getId());
	    
	    if (player != null) {
	        String message = messageNode.get("message").asText();
	        String chatMessage = createChatMessage(player, message, "GLOBAL");
	        
	        // 모든 플레이어에게 브로드캐스트
	        broadcastChatToAll(chatMessage);
	        
	        System.out.println("전체 공지 " + player.getNickName() + ": " + message);
	    }
	}

	// 3. 같은 맵 채팅 브로드캐스트 (기존 broadcastToSameMap 활용)
	// 이미 있는 broadcastToSameMap 메서드를 그대로 사용하면 됩니다!

	// 4. 전체 채팅 브로드캐스트
	private void broadcastChatToAll(String message) {
	    sessions.values().parallelStream().forEach(session -> {
	        try {
	            session.sendMessage(new TextMessage(message));
	        } catch (IOException e) {
	            e.printStackTrace();
	        }
	    });
	}
	// 다른 플레이어들에게 메시지 브로드캐스트
	private void broadcastToOthers(String excludeSessionId, String message) {
		sessions.entrySet().parallelStream().filter(entry -> !entry.getKey().equals(excludeSessionId))
				.forEach(entry -> {
					try {
						entry.getValue().sendMessage(new TextMessage(message));
					} catch (IOException e) {
						e.printStackTrace();
					}
				});
	}

	// 맵별 브로드캐스팅 메서드 추가
	private void broadcastToPlayersInMap(String targetMap, String excludeSessionId, String message) {
		System.out.println(message);
		sessions.entrySet().parallelStream().filter(entry -> !entry.getKey().equals(excludeSessionId)) // 본인 제외
				.filter(entry -> {
					Player player = playerSessions.get(entry.getKey());
					return player != null && targetMap.equals(player.getCurrentMap()); // 같은 맵만
				}).forEach(entry -> {
					try {
						entry.getValue().sendMessage(new TextMessage(message));
					} catch (IOException e) {
						e.printStackTrace();
					}
				});
	}

	// 편의 메서드 (현재 맵의 다른 플레이어들에게) 
	private void broadcastToSameMap(String sessionId, String message) { 
		Player currentPlayer = playerSessions.get(sessionId); 
		if (currentPlayer != null) {
	  broadcastToPlayersInMap(currentPlayer.getCurrentMap(), sessionId, message); }
	}
	

	// 기존 플레이어들 정보 전송
	private void sendExistingPlayers(WebSocketSession session) throws Exception {
		String sessionId = session.getId();
		Player currentPlayer = playerSessions.get(sessionId);

		if (currentPlayer != null) {
			String currentMap = currentPlayer.getCurrentMap(); // 현재 플레이어의 맵

			List<Player> existingPlayers = playerSessions.values().stream()
					.filter(player -> !player.getSessionId().equals(sessionId)) // 본인 제외
					.filter(player -> currentMap.equals(player.getCurrentMap())) // 같은 맵만
					.toList();

			if (!existingPlayers.isEmpty()) {
				String message = createExistingPlayersMessage(existingPlayers);
				session.sendMessage(new TextMessage(message));
				System.out.println("같은 맵(" + currentMap + ")의 기존 플레이어 " + existingPlayers.size() + "명 전송");
			} else {
	            System.out.println("같은 맵(" + currentMap + ")에 다른 플레이어 없음");
	        }
		}
	}

	@Override
	public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
		String sessionId = session.getId();
		sessions.remove(sessionId);
		playerSessions.remove(sessionId);

		// 다른 플레이어들에게 퇴장 알림
		broadcastToOthers(sessionId, createPlayerLeftMessage(sessionId));

		System.out.println("플레이어 연결 해제: " + sessionId);
	}

	// 메시지 생성 메서드들
	private String createPlayerJoinedMessage(Player player) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "player-joined");
		message.put("player", player);
		return mapper.writeValueAsString(message);
	}

	private String createPlayerMovedMessage(String sessionId, Player player) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "player-move");
		message.put("sessionId", sessionId);
		message.put("position", player.getPositionForBroadcast());
		message.put("rotation", player.getRotationForBroadcast());
		return mapper.writeValueAsString(message);
	}

	// 맵 퇴장 메시지
	private String createPlayerLeftMapMessage(Player player) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "player-left-map");
		message.put("sessionId", player.getSessionId());
		message.put("memberId", player.getMemberId());
		message.put("nickName", player.getNickName());
		return mapper.writeValueAsString(message);
	}

	private String createMapChangeSuccessMessage(String targetMap) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "map-change-success");
		message.put("targetMap", targetMap);
		message.put("message", targetMap + " 맵으로 이동 완료");
		return mapper.writeValueAsString(message);
	}

	// 맵 입장 메시지 (새로운 맵의 기존 플레이어들에게)
	private String createPlayerEnteredMapMessage(Player player) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "player-joined");
		message.put("player", player);
		System.out.println(message);
		return mapper.writeValueAsString(message);
	}

	private String createExistingPlayersMessage(List<Player> players) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "existing-players");
		message.put("players", players);
		return mapper.writeValueAsString(message);
	}

	private String createPlayerLeftMessage(String sessionId) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "player-left");
		message.put("sessionId", sessionId);
		return mapper.writeValueAsString(message);
	}

	private String createForceLogoutMessage() throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "force-logout");
		message.put("reason", "다른 기기에서 로그인하여 연결이 해제되었습니다.");
		message.put("timestamp", System.currentTimeMillis());
		return mapper.writeValueAsString(message);
	}
	private String createChatMessage(Player sender, String message, String type) {
	    try {
	        ObjectMapper mapper = new ObjectMapper();
	        Map<String, Object> chatMessage = new HashMap<>();
	        chatMessage.put("type", type);
	        chatMessage.put("nickName", sender.getNickName());
	        chatMessage.put("message", message);
	        chatMessage.put("memberId", sender.getMemberId());
	        chatMessage.put("sessionId", sender.getSessionId());
	        chatMessage.put("timestamp", System.currentTimeMillis());
	        
	        // global일 때는 mapName 없이, map일 때만 추가
	        if ("chat-inMap".equals(type)) {
	            chatMessage.put("mapName", sender.getCurrentMap());
	        }
	        
	        return mapper.writeValueAsString(chatMessage);
	    } catch (Exception e) {
	        e.printStackTrace();
	        return "{}";
	    }
	}
}