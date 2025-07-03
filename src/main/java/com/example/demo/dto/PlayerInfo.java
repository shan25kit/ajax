package com.example.demo.dto;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.example.demo.dto.Position;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PlayerInfo {
	private String id;
	private String username;
	private Position position;
	private JsonNode character; // 캐릭터 커스텀 정보

}
