package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CustomCharacter {
	private int memberId;
	    // 개별 컬럼들 (DB 효율성)
	    private String skinColor;
	    private Integer hair;
	    private String hairColor;
	    private Integer top;
	    private Integer bottom;
	    private Integer dress;
	    private Integer shoes;
	    private Integer accessory;
}