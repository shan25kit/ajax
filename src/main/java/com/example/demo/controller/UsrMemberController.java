package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.demo.dto.GoogleUserInfo;
import com.example.demo.dto.KakaoUserInfo;
import com.example.demo.dto.LoginedMember;
import com.example.demo.dto.Member;
import com.example.demo.dto.NaverUserInfo;
import com.example.demo.dto.Req;
import com.example.demo.dto.ResultData;
import com.example.demo.service.GoogleService;
import com.example.demo.service.KakaoService;
import com.example.demo.service.MemberService;
import com.example.demo.service.NaverService;
import com.example.demo.util.Util;

@Controller
public class UsrMemberController {

	private MemberService memberService;
	private KakaoService kakaoService;
	private NaverService naverService;
	private GoogleService googleService;
	private Req req;
	
	public UsrMemberController(MemberService memberService, KakaoService kakaoService, NaverService naverService, GoogleService googleService, Req req) {
		this.memberService = memberService;
		this.naverService = naverService;
		this.kakaoService = kakaoService;
		this.googleService = googleService;
		this.req = req;

	}
	
	@GetMapping("/usr/member/signup")
	public String signup() {
		return "usr/member/signup";
	}
	
	@PostMapping("/usr/member/doSignUp")
	@ResponseBody
	public String doSignUp(String loginType, String email, String loginId, String loginPw) {
		
		// loginType이 null 또는 일반 문자열일 때 일반 로그인 처리
		if (loginType == null || 
		    (!loginType.equals("kakao") && !loginType.equals("naver") && !loginType.equals("google"))) {
		    
			loginType = "normal"; // 일반 로그인은 "normal"로 저장하거나 null로 두기
			loginPw = Util.encryptSHA256(loginPw); // 비밀번호 암호화

			// loginId와 email은 필수값이어야 함
			if (email == null || loginId == null || loginPw == null) {
				return Util.jsReplace("일반 회원가입에 필요한 정보가 부족합니다.", "usr/member/signup");
			}
		}

		this.memberService.signupMember(loginType, email, loginId, Util.encryptSHA256(loginPw));
		
		return Util.jsReplace("회원 가입이 완료되었습니다", "/");
	}
	
	// 카카오 로그인 콜백 처리
    @GetMapping("/usr/member/kakaoCallback")
    public String kakaoCallback(@RequestParam String code) {
        // 1. 인가코드로 AccessToken 요청
        String accessToken = kakaoService.getAccessToken(code);

        // 2. AccessToken으로 사용자 정보 요청
        KakaoUserInfo userInfo = kakaoService.getUserInfo(accessToken);

        // 3. DB에서 회원 조회 or 회원가입
        Member member = memberService.getMemberByEmail(userInfo.getEmail());
        if (member == null) {
            memberService.signupMember("kakao", userInfo.getEmail(), userInfo.getEmail(), null);
            member = memberService.getMemberByEmail(userInfo.getEmail());
        }

        // 4. 세션 로그인 처리
        req.login(new LoginedMember(member.getId()));

        return "redirect:/";
    }
    
    @GetMapping("/usr/member/naverCallback")
    public String naverCallback(@RequestParam String code, @RequestParam String state) {
        String accessToken = naverService.getAccessToken(code, state);
        NaverUserInfo userInfo = naverService.getUserInfo(accessToken);

        Member member = memberService.getMemberByEmail(userInfo.getEmail());
        if (member == null) {
            memberService.signupMember("naver", userInfo.getEmail(), userInfo.getEmail(), null);
            member = memberService.getMemberByEmail(userInfo.getEmail());
        }

        req.login(new LoginedMember(member.getId()));
        return "redirect:/";
    }
    
 // ✅ 구글 로그인 콜백
    @GetMapping("/usr/member/googleCallback")
    public String googleCallback(@RequestParam String code) {
    	String accessToken = googleService.getAccessToken(code);
        GoogleUserInfo userInfo = googleService.getUserInfo(accessToken);

        Member member = memberService.getMemberByEmail(userInfo.getEmail());
        if (member == null) {
            memberService.signupMember("google", userInfo.getEmail(), userInfo.getEmail(), null);
            member = memberService.getMemberByEmail(userInfo.getEmail());
        }

        req.login(new LoginedMember(member.getId()));
        return "redirect:/";
    }

	
	@GetMapping("/usr/member/loginIdDupChk")
	@ResponseBody
	public ResultData loginIdDupChk(String loginId) {

		Member member = this.memberService.getMemberByLoginId(loginId);

		if (member != null) {
			return ResultData.from("F-1", String.format("[ %s ] 은(는) 이미 사용중인 아이디입니다", loginId));
		}

		return ResultData.from("S-1", String.format("[ %s ] 은(는) 사용가능한 아이디입니다", loginId));
	}
	
	@GetMapping("/usr/member/login")
	public String login() {
		return "usr/member/login";
	}

	@PostMapping("/usr/member/doLogin")
	@ResponseBody
	public String doLogin(String loginId, String loginPw) {

		Member member = this.memberService.getMemberByLoginId(loginId);

		if (member == null) {
			return Util.jsReplace(String.format("[ %s ] 은(는) 존재하지 않는 아이디입니다", loginId), "login");
		}

		if (member.getLoginPw().equals(Util.encryptSHA256(loginPw)) == false) {
			return Util.jsReplace("비밀번호가 일치하지 않습니다", "login");
		}

		this.req.login(new LoginedMember(member.getId()));

		return Util.jsReplace("환영합니다", "/");
	}
	
	@GetMapping("/usr/member/logout")
	@ResponseBody
	public String logout() {

		this.req.logout();

		return Util.jsReplace("로그아웃 되었습니다", "/");
	}
	
	@GetMapping("/usr/member/getLoginId")
	@ResponseBody
	public String getLoginId() {
		return this.memberService.getLoginId(this.req.getLoginedMember().getId());
	}
}