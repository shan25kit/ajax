package com.example.demo.handler;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
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
		String payload = message.getPayload();

		// JSON 메시지 파싱
		ObjectMapper mapper = new ObjectMapper();
		JsonNode messageNode = mapper.readTree(payload);
		String type = messageNode.get("type").asText();

		switch (type) {
		case "join-map":
			System.out.println(messageNode);
			handleJoinMap(session, messageNode);
			break;
		case "player-move":
			handlePlayerMove(sessionId, messageNode);
			break;
		case "change-map":
			System.out.println(messageNode);
			handleMapChange(sessionId, messageNode);
			break;
		case "chat-inMap":
			handleChatInMap(session, messageNode);
			break;
		case "chat-global":
			handleChatGlobal(session, messageNode);
			break;

		}
	}

	@Override
	public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
		String sessionId = session.getId();
		Player player = playerSessions.get(sessionId);
		sessions.remove(sessionId);
		playerSessions.remove(sessionId);

		// 다른 플레이어들에게 퇴장 알림
		if (player != null) {
			try {
				broadcastToOthers(sessionId, createPlayerLeftMessage(sessionId));
				System.out.println("📤 퇴장 알림 전송 완료: " + player.getNickName());
			} catch (Exception e) {
				System.out.println("❌ 퇴장 알림 전송 실패: " + e.getMessage());
			}
		}

		System.out.println("플레이어 연결 해제: " + sessionId);
	}

	// 맵 입장 처리
	private void handleJoinMap(WebSocketSession session, JsonNode messageNode) throws Exception {
		int memberId = messageNode.get("memberId").asInt();
		String currentMap = messageNode.get("currentMap").asText();
		String newSessionId = session.getId();
		System.out.println("=== 입장 요청 디버깅 ===");
		System.out.println("memberId: " + memberId);
		System.out.println("sessionId: " + newSessionId);
		System.out.println("요청된 currentMap: " + currentMap);

		cleanupExistingSessionsForMember(memberId, newSessionId);

		String nickName = messageNode.get("nickName").asText();
		JsonNode avatarInfo = messageNode.get("avatarInfo");

		// 플레이어 정보 저장
		Player player = new Player();
		player.setSessionId(newSessionId);
		player.setMemberId(memberId);
		player.setNickName(nickName);
		player.setAvatarInfo(avatarInfo);
		player.setCurrentMap(currentMap);

		Map<String, Double> initialPosition = getInitialPositionByMap(currentMap);
		player.setPosition(initialPosition);
		playerSessions.put(newSessionId, player);
		System.out.println("플레이어 저장 완료: " + player);

		
		handlePlayerMapEntry(player, newSessionId, false);

		System.out.println("handleJoinMap 완료");
	}

	private Map<String, Double> getInitialPositionByMap(String currentMap) {
		Map<String, Double> position = new HashMap<>();
		switch (currentMap) {
		case "startMap":
			position.put("x", 2400.0);
			position.put("y", 0.0);
			position.put("z", 1800.0);
			break;

		case "sadMap":
			position.put("x", 5000.0); 
			position.put("y", 0.0);
			position.put("z", 5000.0);
			break;

		case "happyMap":
			position.put("x", 1200.0);
			position.put("y", 0.0);
			position.put("z", 1500.0);
			break;

		// 다른 맵들도 추가...

		default:
			// 기본 위치 (startMap과 동일)
			position.put("x", 2400.0);
			position.put("y", 0.0);
			position.put("z", 1800.0);
			break;
		}

		return position;
	}

	private void cleanupExistingSessionsForMember(int memberId, String excludeSessionId) {

		System.out.println("🧹 기존 세션 정리 시작 - memberId: " + memberId);

		List<String> sessionsToRemove = new ArrayList<>();
		List<Player> playersToNotify = new ArrayList<>();
		List<WebSocketSession> sessionsToClose = new ArrayList<>();

		// ✅ 1단계: 동기화 블록 내에서 정리할 데이터 수집
		synchronized (playerSessions) {
			for (Map.Entry<String, Player> entry : playerSessions.entrySet()) {
				String sessionId = entry.getKey();
				Player player = entry.getValue();

				// 같은 memberId이면서 현재 세션이 아닌 경우
				if (player != null && player.getMemberId() == memberId && !sessionId.equals(excludeSessionId)) {

					sessionsToRemove.add(sessionId);
					playersToNotify.add(player); // 퇴장 알림용 플레이어 정보 복사

					// WebSocket 세션 수집
					WebSocketSession wsSession = sessions.get(sessionId);
					if (wsSession != null) {
						sessionsToClose.add(wsSession);
					}

					System.out.println("정리 대상 발견: " + sessionId + " (닉네임: " + player.getNickName() + ")");
				}
			}
		}

		if (sessionsToRemove.isEmpty()) {
			System.out.println("정리할 기존 세션 없음");
			return;
		}

		System.out.println("발견된 기존 세션: " + sessionsToRemove.size() + "개");

		// ✅ 2단계: 메모리에서 즉시 제거 (동시성 문제 방지)
		synchronized (playerSessions) {
			for (String sessionId : sessionsToRemove) {
				playerSessions.remove(sessionId);
			}
		}

		synchronized (sessions) {
			for (String sessionId : sessionsToRemove) {
				sessions.remove(sessionId);
			}
		}

		// ✅ 3단계: 다른 플레이어들에게 퇴장 알림 (동기화 블록 밖에서)
		for (int i = 0; i < sessionsToRemove.size(); i++) {
			String sessionId = sessionsToRemove.get(i);
			Player player = playersToNotify.get(i);

			try {
				if (player.getCurrentMap() != null) {
					String leftMessage = createPlayerLeftMessage(sessionId);
					broadcastToPlayersInMap(player.getCurrentMap(), sessionId, leftMessage);
					System.out.println("퇴장 알림 전송 완료: " + player.getCurrentMap() + " - " + player.getNickName());
				}
			} catch (Exception e) {
				System.out.println("퇴장 알림 전송 중 오류 (계속 진행): " + sessionId + " - " + e.getMessage());
			}
		}

		// ✅ 4단계: WebSocket 세션 안전하게 종료
		for (int i = 0; i < sessionsToClose.size(); i++) {
			WebSocketSession wsSession = sessionsToClose.get(i);
			String sessionId = sessionsToRemove.get(i);

			if (wsSession != null && wsSession.isOpen()) {
				try {
					// 세션 교체 메시지 전송
					String replaceMessage = createSessionReplacedMessage("새로운 페이지에서 접속하여 기존 연결이 교체되었습니다.");
					wsSession.sendMessage(new TextMessage(replaceMessage));

					// 비동기로 연결 종료 (메시지 전송 시간 확보)
					CompletableFuture.runAsync(() -> {
						try {
							Thread.sleep(200); // 메시지 전송 대기
							if (wsSession.isOpen()) {
								wsSession.close(CloseStatus.NORMAL);
								System.out.println("WebSocket 연결 정상 종료: " + sessionId);
							}
						} catch (Exception e) {
							// 정상 종료 실패 시 강제 종료
							try {
								wsSession.close(CloseStatus.SERVER_ERROR);
								System.out.println("WebSocket 연결 강제 종료: " + sessionId);
							} catch (Exception ignored) {
								System.out.println("WebSocket 강제 종료도 실패: " + sessionId);
							}
						}
					});

				} catch (Exception e) {
					System.out.println("WebSocket 종료 처리 중 오류: " + sessionId + " - " + e.getMessage());
					// 메시지 전송 실패 시에도 연결 종료 시도
					try {
						wsSession.close(CloseStatus.SERVER_ERROR);
					} catch (Exception ignored) {
					}
				}
			}
		}

		System.out.println("🎯 모든 기존 세션 정리 완료 - 처리된 세션: " + sessionsToRemove.size() + "개");
	}

	private String createSessionReplacedMessage(String reason) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		Map<String, Object> message = new HashMap<>();
		message.put("type", "session-replaced");
		message.put("reason", reason);
		message.put("timestamp", System.currentTimeMillis());
		return mapper.writeValueAsString(message);
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

	private void handleMapChange(String sessionId, JsonNode messageNode) throws Exception {

		System.out.println("=== 맵 변경 요청 ===");
		System.out.println("전체 메시지: " + messageNode);
		JsonNode targetMapNode = messageNode.get("targetMap");
		if (targetMapNode == null) {
			System.out.println("❌ targetMap을 찾을 수 없음!");
			sendMapChangeError(sessionId, "targetMap 정보가 없습니다.");
			return;
		}
		String targetMap = targetMapNode.asText();

		Player player = playerSessions.get(sessionId);
		if (player == null) {
			System.out.println("❌ 플레이어를 찾을 수 없음: " + sessionId);
			sendMapChangeError(sessionId, "플레이어 정보를 찾을 수 없습니다.");
			return;
		}
		int memberId = player.getMemberId();
		String currentMap = player.getCurrentMap();
		String nickName = player.getNickName();
		System.out.println("맵 변경 정보:");
		System.out.println("  - 플레이어: " + nickName + " (ID: " + memberId + ")");
		System.out.println("  - 현재 맵: " + currentMap);
		System.out.println("  - 목표 맵: " + targetMap);

		// 3. 같은 맵 체크
		if (targetMap.equals(currentMap)) {
			System.out.println("⚠️ 이미 같은 맵에 있음, 성공 메시지만 전송");
			sendMapChangeSuccess(sessionId, targetMap);
			return;
		}
		  // 4. 기존 세션 정리
        cleanupExistingSessionsForMember(memberId, sessionId);
        try {
            // 5. 현재 맵에서 퇴장 처리
            if (currentMap != null) {
                System.out.println("🚪 현재 맵에서 퇴장 처리: " + currentMap);
                String leftMapMessage = createPlayerLeftMapMessage(player);
                broadcastToPlayersInMap(currentMap, sessionId, leftMapMessage);
                System.out.println("✅ 퇴장 알림 전송 완료");
            }

            // 6. 플레이어 정보 업데이트
            System.out.println("📝 플레이어 맵 정보 업데이트");
            player.setCurrentMap(targetMap);
            Map<String, Double> newPosition = getInitialPositionByMap(targetMap);
            player.setPosition(newPosition);

            // 7. 클라이언트에게 맵 변경 성공 메시지 즉시 전송
            sendMapChangeSuccess(sessionId, targetMap);

            // 8. 🎯 비동기로 새 맵 입장 처리 (공통 메서드 사용)
            final Player finalPlayer = player; // final 변수로 복사
            CompletableFuture.runAsync(() -> {
                try {
                    // 클라이언트가 맵을 정리할 시간 확보
                    Thread.sleep(300);

                    // 세션이 여전히 유효한지 재확인
                    if (sessions.containsKey(sessionId) && playerSessions.containsKey(sessionId)) {
                        System.out.println("🚪 새 맵 입장 처리 시작: " + targetMap);

                        // 🎯 공통 맵 입장 처리 호출
                        handlePlayerMapEntry(finalPlayer, sessionId, true);

                    } else {
                        System.out.println("⚠️ 맵 변경 후 세션이 무효화됨: " + sessionId);
                    }

                } catch (Exception e) {
                    System.out.println("❌ 새 맵 입장 처리 중 오류: " + e.getMessage());
                    e.printStackTrace();

                    // 실패 시 클라이언트에게 알림
                    try {
                        sendMapChangeError(sessionId, "새 맵 입장 중 오류가 발생했습니다.");
                    } catch (Exception ignored) {}
                }
            });

            System.out.println("🎯 맵 변경 처리 완료: " + currentMap + " → " + targetMap);

        } catch (Exception e) {
            System.out.println("❌ 맵 변경 처리 중 오류: " + e.getMessage());
            e.printStackTrace();

            // 오류 발생 시 맵 정보 롤백
            if (currentMap != null) {
                player.setCurrentMap(currentMap);
                System.out.println("📝 맵 정보 롤백 완료: " + currentMap);
            }

            sendMapChangeError(sessionId, "맵 변경 중 오류가 발생했습니다: " + e.getMessage());
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

	private void handlePlayerMapEntry(Player player, String sessionId, boolean isMapChange) throws Exception {
		WebSocketSession session = sessions.get(sessionId);
		if (session == null || !session.isOpen()) {
			System.out.println("❌ 유효하지 않은 세션으로 맵 입장 실패: " + sessionId);
			return;
		}

		String mapName = player.getCurrentMap();
		String nickName = player.getNickName();

		System.out.println("👤 플레이어 맵 입장 처리 시작");
		System.out.println("  - 플레이어: " + nickName);
		System.out.println("  - 맵: " + mapName);
		System.out.println("  - 맵 변경 여부: " + isMapChange);

		try {
			// 1. 본인에게 플레이어 입장 메시지 전송
			String playerJoinedMessage = createPlayerJoinedMessage(player);
			session.sendMessage(new TextMessage(playerJoinedMessage));
			System.out.println("✅ 본인에게 입장 메시지 전송 완료");

			// 2. 같은 맵의 다른 플레이어들에게 새 플레이어 알림
			broadcastToSameMap(sessionId, playerJoinedMessage);
			System.out.println("✅ 다른 플레이어들에게 입장 알림 전송 완료");

			// 3. 같은 맵의 기존 플레이어들 정보를 새 플레이어에게 전송
			sendExistingPlayers(session);
			System.out.println("✅ 기존 플레이어 정보 전송 완료");

			// 4. 로그 출력
			if (isMapChange) {
				System.out.println("🗺️ 맵 변경으로 인한 입장 완료: " + nickName + " → " + mapName);
			} else {
				System.out.println("🚪 신규 접속으로 인한 입장 완료: " + nickName + " → " + mapName);
			}

		} catch (Exception e) {
			System.out.println("❌ 맵 입장 처리 중 오류 발생: " + e.getMessage());
			e.printStackTrace();
			throw e; // 상위로 예외 전파
		}
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
			broadcastToPlayersInMap(currentPlayer.getCurrentMap(), sessionId, message);
		}
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
	 private void sendMapChangeSuccess(String sessionId, String targetMap) {
	        try {
	            WebSocketSession session = sessions.get(sessionId);
	            if (session != null && session.isOpen()) {
	                String successMessage = createMapChangeSuccessMessage(targetMap);
	                session.sendMessage(new TextMessage(successMessage));
	                System.out.println("✅ 맵 변경 성공 메시지 전송: " + targetMap);
	            }
	        } catch (Exception e) {
	            System.out.println("❌ 성공 메시지 전송 실패: " + e.getMessage());
	        }
	    }
	private void sendMapChangeError(String sessionId, String errorMessage) {
		try {
			WebSocketSession session = sessions.get(sessionId);
			if (session != null && session.isOpen()) {
				ObjectMapper mapper = new ObjectMapper();
				Map<String, Object> error = new HashMap<>();
				error.put("type", "map-change-error");
				error.put("message", errorMessage);
				error.put("timestamp", System.currentTimeMillis());

				session.sendMessage(new TextMessage(mapper.writeValueAsString(error)));
				System.out.println("📤 에러 메시지 전송: " + errorMessage);
			}
		} catch (Exception e) {
			System.out.println("❌ 에러 메시지 전송 실패: " + e.getMessage());
		}
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