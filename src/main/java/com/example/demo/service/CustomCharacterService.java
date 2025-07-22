package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.dao.CustomCharacterDao;
import com.example.demo.dto.CustomCharacter;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

@Service
public class CustomCharacterService {

	private CustomCharacterDao customCharacterDao;
	private final ObjectMapper objectMapper = new ObjectMapper();

	public CustomCharacterService(CustomCharacterDao customCharacterDao) {
		this.customCharacterDao = customCharacterDao;
	}

	// 캐릭터 저장
	public void customCaracterBySave(int memberId, JsonNode avatarInfo) {
		CustomCharacter character = convertJsonToCharacter(avatarInfo, memberId);
		customCharacterDao.customCaracterBySave(character.getMemberId(), character.getSkinColor(),
				character.getFace() != null ? Integer.valueOf(character.getFace()) : null,
				character.getHair() != null ? Integer.valueOf(character.getHair()) : null, character.getHairColor(),
				character.getTop() != null ? Integer.valueOf(character.getTop()) : null,
				character.getBottom() != null ? Integer.valueOf(character.getBottom()) : null,
				character.getDress() != null ? Integer.valueOf(character.getDress()) : null,
				character.getShoes() != null ? Integer.valueOf(character.getShoes()) : null,
				character.getAccessoryMain(),
				character.getAccessoryDetail() != null ? Integer.valueOf(character.getAccessoryDetail()) : null);
	}

	// 캐릭터 업데이트
	public void customCaracterByUpdate(int memberId, JsonNode avatarInfo) {
		CustomCharacter character = convertJsonToCharacter(avatarInfo, memberId);
		customCharacterDao.customCaracterByUpdate(character.getMemberId(), character.getSkinColor(),
				character.getFace() != null ? Integer.valueOf(character.getFace()) : null,
				character.getHair() != null ? Integer.valueOf(character.getHair()) : null, character.getHairColor(),
				character.getTop() != null ? Integer.valueOf(character.getTop()) : null,
				character.getBottom() != null ? Integer.valueOf(character.getBottom()) : null,
				character.getDress() != null ? Integer.valueOf(character.getDress()) : null,
				character.getShoes() != null ? Integer.valueOf(character.getShoes()) : null,
				character.getAccessoryMain(),
				character.getAccessoryDetail() != null ? Integer.valueOf(character.getAccessoryDetail()) : null);
	}

	// 캐릭터 존재여부 확인
	public boolean exists(int memberId) {
		return customCharacterDao.existsByMemberId(memberId);
	}

	// 캐릭터 정보 가져오기
	public CustomCharacter getCharacter(int memberId) {
		return customCharacterDao.getCharacterByMemberId(memberId);
	}

	public CustomCharacter convertJsonToCharacter(JsonNode avatarInfo, int memberId) {
		CustomCharacter character = new CustomCharacter();
		character.setMemberId(memberId);

		// 피부색
		character.setSkinColor(avatarInfo.path("skinColor").asText(null));

		// 파츠 정보
		JsonNode parts = avatarInfo.path("parts");
		
		if (parts.has("face")) {
			character.setFace(parts.path("face").path("style").asInt(0));
		}

		if (parts.has("hair")) {
			JsonNode hair = parts.path("hair");
			character.setHair(hair.path("style").asInt(0));
			character.setHairColor(hair.path("color").asText(null));
		}

		if (parts.has("top")) {
			character.setTop(parts.path("top").path("style").asInt(0));
		}

		if (parts.has("bottom")) {
			character.setBottom(parts.path("bottom").path("style").asInt(0));
		}

		if (parts.has("dress")) {
			character.setDress(parts.path("dress").path("style").asInt(0));
		}

		if (parts.has("shoes")) {
			character.setShoes(parts.path("shoes").path("style").asInt(0));
		}
		
		// ✅ 액세서리 중첩 구조 처리
	    if (parts.has("accessory")) {
	        JsonNode accessory = parts.path("accessory");
	        
	        // accessory.main 처리
	        if (accessory.has("main")) {
	            JsonNode mainArray = accessory.path("main");
	            if (mainArray.isArray() && mainArray.size() > 0) {
	                try {
	                    ArrayNode styleArray = objectMapper.createArrayNode();
	                    for (JsonNode item : mainArray) {
	                        styleArray.add(item.path("style").asInt());
	                    }
	                    character.setAccessoryMain(objectMapper.writeValueAsString(styleArray));
	                } catch (Exception e) {
	                    character.setAccessoryMain(null);
	                }
	            }
	        }
	        
	        // accessory.detail 처리
	        if (accessory.has("detail")) {
	            JsonNode detail = accessory.path("detail");
	            if (!detail.isMissingNode() && !detail.isNull()) {
	                character.setAccessoryDetail(detail.path("style").asInt(0));
	            }
	        }
	    }

		return character;
	}

	public JsonNode convertCharacterToJson(CustomCharacter character) {
		ObjectNode avatarInfo = objectMapper.createObjectNode(); // ✅ avatarInfo로 변경
		ObjectNode parts = objectMapper.createObjectNode();

		// 피부색
		if (character.getSkinColor() != null) {
			avatarInfo.put("skinColor", character.getSkinColor());
		}
		
		// 상의
		if (character.getFace() != null) {
			ObjectNode face = objectMapper.createObjectNode();
			face.put("style", character.getFace());
			parts.set("face", face);
		}

		// 헤어
		if (character.getHair() != null) {
			ObjectNode hair = objectMapper.createObjectNode();
			hair.put("style", character.getHair());
			hair.put("color", character.getHairColor());
			parts.set("hair", hair);
		}

		// 상의
		if (character.getTop() != null) {
			ObjectNode top = objectMapper.createObjectNode();
			top.put("style", character.getTop());
			top.put("color", (String) null);
			parts.set("top", top);
		}

		// 하의
		if (character.getBottom() != null) {
			ObjectNode bottom = objectMapper.createObjectNode();
			bottom.put("style", character.getBottom());
			bottom.put("color", (String) null);
			parts.set("bottom", bottom);
		}

		// 원피스
		if (character.getDress() != null) {
			ObjectNode dress = objectMapper.createObjectNode();
			dress.put("style", character.getDress());
			dress.put("color", (String) null);
			parts.set("dress", dress);
		}

		// 신발
		if (character.getShoes() != null) {
			ObjectNode shoes = objectMapper.createObjectNode();
			shoes.put("style", character.getShoes());
			shoes.put("color", (String) null);
			parts.set("shoes", shoes);
		}

		 // ✅ 액세서리 Main (JSON 문자열 → 배열)
	    if (character.getAccessoryMain() != null && !character.getAccessoryMain().isEmpty()) {
	        try {
	            JsonNode accessoryMainArray = objectMapper.readTree(character.getAccessoryMain());
	            if (accessoryMainArray.isArray() && accessoryMainArray.size() > 0) {
	                ArrayNode mainArray = objectMapper.createArrayNode();
	                for (JsonNode item : accessoryMainArray) {
	                    ObjectNode accessory = objectMapper.createObjectNode();
	                    accessory.put("style", item.asInt());
	                    mainArray.add(accessory);
	                }
	                parts.set("accessoryMain", mainArray);
	            }
	        } catch (Exception e) {
	            // JSON 파싱 실패 시 무시
	            System.err.println("accessoryMain JSON 파싱 실패: " + e.getMessage());
	        }
	    }

	    // ✅ 액세서리 Detail (숫자 → 객체)
	    if (character.getAccessoryDetail() != null && character.getAccessoryDetail() > 0) {
	        ObjectNode accessoryDetail = objectMapper.createObjectNode();
	        accessoryDetail.put("style", character.getAccessoryDetail());
	        parts.set("accessoryDetail", accessoryDetail);
	    }

		avatarInfo.set("parts", parts);
		return avatarInfo; // character -> avartarInfo jsonNode로 변환
	}
}