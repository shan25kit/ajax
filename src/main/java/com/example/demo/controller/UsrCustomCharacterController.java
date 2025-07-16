package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.CustomCharacter;
import com.example.demo.dto.Req;
import com.example.demo.dto.ResultData;
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
	@ResponseBody
	public ResultData saveCustom(HttpSession session, @RequestBody CustomCharacter character) {

		if (this.req.getLoginedMember() == null) {
			return ResultData.from("F-1", "로그인이 필요합니다");
		}

		try {
			int memberId = this.req.getLoginedMember().getId();
			character.setMemberId(memberId);

			if (customCharacterService.exists(memberId)) {
				customCharacterService.customCaracterByUpdate(character);
			} else {
				customCharacterService.customCaracterBySave(character);
			}

			return ResultData.from("S-1", "캐릭터 저장 완료");

		} catch (Exception e) {
			return ResultData.from("F-2", "저장 중 오류가 발생했습니다");
		}
	}

}
