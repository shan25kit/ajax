package com.example.demo.dto;

import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Player {
	private String sessionId; // WebSocket 세션 ID
	private int memberId; // 실제 회원 ID
	private String nickName;
	private JsonNode avatarInfo; // 캐릭터 커스텀 정보
	private String currentMap = "default-map"; // 현재 맵 정보

	// Jackson 직렬화용 - character를 문자열로 변환

	@JsonProperty("avatarInfo")
	public String getCharacterString() {
		return avatarInfo != null ? avatarInfo.toString() : null;
	}

	// 원본 JsonNode getter (직렬화에서 제외)
	@JsonIgnore
	public JsonNode getCharacter() {
		return avatarInfo;
	}

	// setter는 JsonNode 타입 유지
	public void setCharacter(JsonNode character) {
		this.avatarInfo = character;
	}

	// 실시간 위치 (메모리에만 저장, DB 저장 안함) - Map으로 관리
	private Map<String, Double> position = new HashMap<>();

	// 위치 관련 메서드들 - Map 기반
	public Map<String, Double> getPosition() {
		return new HashMap<>(position); // 방어적 복사
	}

	public void setPosition(Map<String, Double> position) {
		this.position = new HashMap<>(position);
	}

	public void updatePosition(double x, double y, double z) {
		position.put("x", x);
		position.put("y", y);
		position.put("z", z);
	}

	public void updatePosition(Map<String, Double> newPosition) {
		position.putAll(newPosition);
	}

	// 개별 좌표 접근
	public double getX() {
		return position.getOrDefault("x", 0.0);
	}

	public double getY() {
		return position.getOrDefault("y", 0.0);
	}

	public double getZ() {
		return position.getOrDefault("z", 0.0);
	}

	public void setX(double x) {
		position.put("x", x);
	}

	public void setY(double y) {
		position.put("y", y);
	}

	public void setZ(double z) {
		position.put("z", z);
	}

	// 브로드캐스팅용 위치 데이터 (참조 반환)
	public Map<String, Double> getPositionForBroadcast() {
		return position; // 직접 참조 (성능상 이유)
	}

	private Map<String, Double> rotation; // 🆕 회전 정보 추가

	// 생성자에서 초기화
	public Player(String sessionId, String memberId, String nickName, String avatarInfo) {
		// 기존 코드...
		this.rotation = new HashMap<>();
		this.rotation.put("x", -Math.PI / 6); // 초기값
		this.rotation.put("y", Math.PI / 4); // 초기값
		this.rotation.put("z", 0.0); // 초기값
	}

	// 🆕 회전 업데이트 메서드
	public void updateRotation(Map<String, Double> newRotation) {
		this.rotation = newRotation;
	}

	public Map<String, Double> getRotationForBroadcast() {
		return this.rotation;
	}

	// 🆕 회전 정보 반환 메서드
	public Map<String, Double> getRotation() {
		return this.rotation;
	}
}
