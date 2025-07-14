package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CustomCharacterDto {
	private int memberId;
	private String skin_face;
	private String hair;
	private String top;
	private String bottom;
	private String dress;
	private String shoes;
	private String accessory;
}