package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.CustomCharacter;
import com.example.demo.dto.Member;
import com.example.demo.dto.Req;
import com.example.demo.dto.ResultData;
import com.example.demo.service.CustomCharacterService;
import com.example.demo.service.MemberService;
import com.example.demo.util.Util;
import com.fasterxml.jackson.databind.JsonNode;

import jakarta.servlet.http.HttpSession;

@Controller
public class UsrCustomCharacterController {

	private CustomCharacterService customCharacterService;
	private MemberService memberService;
	private Req req;

	public UsrCustomCharacterController(CustomCharacterService customCharacterService, MemberService memberService, Req req) {
		this.customCharacterService = customCharacterService;
		this.memberService = memberService;
		this.req = req;

	}

	@PostMapping("/usr/custom/save")
	@ResponseBody
	public ResultData saveCustom(HttpSession session, @RequestBody JsonNode avatarInfo) {
		System.out.println(avatarInfo);
		if (this.req.getLoginedMember() == null) {
			return ResultData.from("F-1", "로그인이 필요합니다");
		}
		try {
			int memberId = this.req.getLoginedMember().getId();

			if (customCharacterService.exists(memberId)) {
				customCharacterService.customCaracterByUpdate(memberId, avatarInfo);
			} else {
				customCharacterService.customCaracterBySave(memberId, avatarInfo);
			}

			return ResultData.from("S-1", "캐릭터 저장 완료");

		} catch (Exception e) {
			return ResultData.from("F-2", "저장 중 오류가 발생했습니다");
		}
	}
	
	@PostMapping("/usr/custom/updateNickName")
	@ResponseBody
	public ResultData updateNickName(@RequestParam int memberId, @RequestParam String nickName) {
		
		Member member = this.memberService.getMemberByNickName(nickName);

		if (member != null) {
			return ResultData.from("F-1", "이미 사용 중인 닉네임입니다.");
		}
		
	    this.memberService.updateNickName(memberId, nickName);
	    
	    return ResultData.from("S-1", "닉네임이 수정되었습니다.");
	}


}
