package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.CustomCharacter;
import com.example.demo.dto.Req;
import com.example.demo.service.CustomCharacterService;

import jakarta.servlet.http.HttpSession;

@Controller
public class UsrCustomCharacterController {

	private CustomCharacterService customCharacterService;
	private Req req;
	
	public UsrCustomCharacterController(CustomCharacterService customCharacterService, Req req) {
		this.customCharacterService = customCharacterService;
		this.req = req;

	}
	
	@PostMapping("/usr/custom/save")
	public String saveCustom(HttpSession session, @RequestBody CustomCharacter character) {
		 // ✅ 변환 결과 확인용 로그
	    System.out.println("=== 받은 데이터 확인 ===");
	    System.out.println("skinColor: " + character.getSkinColor());
	    System.out.println("hair: " + character.getHair());
	    System.out.println("hairColor: " + character.getHairColor());
	    System.out.println("top: " + character.getTop());
	    System.out.println("bottom: " + character.getBottom());
	    System.out.println("dress: " + character.getDress());
	    System.out.println("shoes: " + character.getShoes());
	    System.out.println("accessory: " + character.getAccessory());
	    System.out.println("memberId: " + character.getMemberId());  // 0이어야 함
	    
		if (this.req.getLoginedMember() == null) {
	        return "redirect:/usr/member/login";  // 로그인 안 되어 있을 경우 로그인 페이지로
	    }
		
		int memberId = this.req.getLoginedMember().getId();
		character.setMemberId(memberId);
		System.out.println("🎨 character: " + character);
		
		if (customCharacterService.exists(memberId)) {
			System.out.println("🔁 업데이트 실행");
	        // 이미 있으면 update
	        customCharacterService.customCaracterByUpdate(character);
	    } else {
	    	System.out.println("🆕 인서트 실행");
	        // 없으면 insert
	        customCharacterService.customCaracterBySave(character);
	    }
		
		// ✅ 저장 완료 후 바로 맵으로 이동
	    return "redirect:/usr/game";
	}

}
