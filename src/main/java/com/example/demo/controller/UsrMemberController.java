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
	
	@GetMapping("/usr/member/emailSignUp")
	public String emailSignup() {
		return "usr/member/emailSignUp";
	}
	
	@PostMapping("/usr/member/doEmailSignUp")
	@ResponseBody
	public String doEmailSignUp(String email, String loginId, String loginPw) {

		this.memberService.emailSignUp(email, loginId, Util.encryptSHA256(loginPw));
		
		return Util.jsReplace("회원 가입이 완료되었습니다", "/");
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

	@GetMapping("/usr/member/emailDupChk")
	@ResponseBody
	public ResultData emailDupChk(String email) {

		Member member = this.memberService.getMemberByEmail(email);

		if (member != null) {
			return ResultData.from("F-1", String.format("[ %s ] 은(는) 이미 가입된 이메일입니다", email));
		}

		return ResultData.from("S-1", String.format("[ %s ] 은(는) 사용가능한 이메일입니다", email));
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
	
	@GetMapping("/usr/member/findLoginId")
	public String findLoginId() {
		return "usr/member/findLoginId";
	}
	
	@GetMapping("/usr/member/doFindLoginId")
	@ResponseBody
	public ResultData doFindLoginId(String email) {
		
		Member member = this.memberService.getMemberByNameAndEmail(email);
		
		if (member == null) {
			return ResultData.from("F-1", "입력하신 정보와 일치하는 회원이 없습니다");
		}
		
		return ResultData.from("S-1", String.format("회원님의 아이디는 [ %s ] 입니다", member.getLoginId()));
	}
	
	@GetMapping("/usr/member/findLoginPw")
	public String findLoginPw() {
		return "usr/member/findLoginPw";
	}
	
	@GetMapping("/usr/member/doFindLoginPw")
	@ResponseBody
	public ResultData doFindLoginPw(String loginId, String email) {
		
		Member member = this.memberService.getMemberByLoginId(loginId);
		
		if (member == null) {
			return ResultData.from("F-1", "입력하신 아이디와 일치하는 회원이 없습니다");
		}
		
		if (member.getEmail().equals(email) == false) {
			return ResultData.from("F-2", "이메일이 일치하지 않습니다");
		}
		
		String tempPassword = Util.createTempPassword();
		
		try {
			this.memberService.sendPasswordRecoveryEmail(member, tempPassword);
		} catch (Exception e) {
			return ResultData.from("F-3", "임시 패스워드 발송에 실패했습니다");
		}
		
		this.memberService.modifyPassword(member.getId(), Util.encryptSHA256(tempPassword));
		
		return ResultData.from("S-1", "회원님의 이메일주소로 임시 패스워드가 발송되었습니다");
	}
}