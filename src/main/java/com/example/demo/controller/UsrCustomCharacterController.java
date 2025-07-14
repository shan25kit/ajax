package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;

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
	public String saveCustom(String skin_face, String hair, String top, String bottom, String dress, String shoes, String accessory, HttpSession session) {

		if (this.req.getLoginedMember() == null) {
	        return "redirect:/usr/member/login";  // 로그인 안 되어 있을 경우 로그인 페이지로
	    }
		
		int memberId = this.req.getLoginedMember().getId();
		System.out.println("✅ 로그인된 memberId: " + memberId);
	    System.out.println("🎨 받은 파라미터: " + skin_face + ", " + hair + ", " + top + ", " + bottom + ", " + dress + ", " + shoes + ", " + accessory);

		if (customCharacterService.exists(memberId)) {
			System.out.println("🔁 업데이트 실행");
	        // 이미 있으면 update
	        customCharacterService.customCaracterByUpdate(memberId, skin_face, hair, top, bottom, dress, shoes, accessory);
	    } else {
	    	System.out.println("🆕 인서트 실행");
	        // 없으면 insert
	        customCharacterService.customCaracterBySave(memberId, skin_face, hair, top, bottom, dress, shoes, accessory);
	    }
		
		// ✅ 저장 완료 후 바로 맵으로 이동
	    return "redirect:/usr/game";
	}

}
