package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
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
import com.example.demo.service.CustomCharacterService;
import com.example.demo.service.EmailAuthService;
import com.example.demo.service.GoogleService;
import com.example.demo.service.KakaoService;
import com.example.demo.service.MemberService;
import com.example.demo.service.NaverService;
import com.example.demo.util.Util;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Controller
public class UsrMemberController {

	private MemberService memberService;
	private CustomCharacterService customCharacterService;
	private EmailAuthService emailAuthService;
	private KakaoService kakaoService;
	private NaverService naverService;
	private GoogleService googleService;
	private Req req;

	public UsrMemberController(MemberService memberService, CustomCharacterService customCharacterService,
			KakaoService kakaoService, NaverService naverService, GoogleService googleService, Req req,
			EmailAuthService emailAuthService) {
		this.memberService = memberService;
		this.customCharacterService = customCharacterService;
		this.emailAuthService = emailAuthService;
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
		if (loginType == null
				|| (!loginType.equals("kakao") && !loginType.equals("naver") && !loginType.equals("google"))) {

			loginType = "normal"; // 일반 로그인은 "normal"로 저장하거나 null로 두기
			loginPw = Util.encryptSHA256(loginPw); // 비밀번호 암호화

			// loginId와 email은 필수값이어야 함
			if (email == null || loginId == null || loginPw == null) {
				return Util.jsReplace("일반 회원가입에 필요한 정보가 부족합니다.", "/usr/member/signup");
			}
		}

		this.memberService.signupMember(loginType, email, loginId, loginPw);

		return Util.jsReplace("회원 가입이 완료되었습니다", "/");
	}

	@GetMapping("/usr/member/emailSignUp")
	public String emailSignup() {
		return "usr/member/emailSignUp";
	}

	@GetMapping("/usr/member/loginIdDupChk")
	@ResponseBody
	public ResultData loginIdDupChk(String loginId) {

		Member member = this.memberService.getMemberByLoginIdChk(loginId);

		if (member != null) {
			return ResultData.from("F-1", String.format("이미 사용중인 아이디입니다", loginId));
		}

		return ResultData.from("S-1", String.format("사용가능한 아이디입니다", loginId));
	}

	@GetMapping("/usr/member/emailDupChk")
	@ResponseBody
	public ResultData emailDupChk(String email) {

		Member member = this.memberService.getMemberByEmail(email);

		if (member != null) {
			String loginType = member.getLoginType();
			String message;
			switch (loginType) {
			case "kakao":
				message = "해당 이메일로 이미 가입된 다음 계정이 있습니다.";
				break;
			case "naver":
				message = "해당 이메일로 이미 가입된 네이버 계정이 있습니다.";
				break;
			case "google":
				message = "해당 이메일로 이미 가입된 구글 계정이 있습니다.";
				break;
			default:
				message = "해당 이메일로 이미 가입된 계정이 있습니다.";
				break;
			}
			return ResultData.from("F-1", message, email);
		}
		return ResultData.from("S-1", String.format("사용가능한 이메일입니다", email));
	}

	// 카카오 로그인 콜백 처리
	@GetMapping("/usr/member/kakaoCallback")
	public String kakaoCallback(@RequestParam String code) {
		// 1. 인가코드로 AccessToken 요청
		String accessToken = kakaoService.getAccessToken(code);

		// 2. AccessToken으로 사용자 정보 요청
		KakaoUserInfo userInfo = kakaoService.getUserInfo(accessToken);

		// 3. DB에서 회원 조회 or 회원가입
		Member member = memberService.getMemberByLoginId(userInfo.getName());
		int loginMemberId;
		if (member == null) {
			memberService.signupMember("kakao", null, userInfo.getName(), null);
			loginMemberId = memberService.getLastInsertId();
			req.login(new LoginedMember(loginMemberId));
			return "redirect:/usr/member/info";
		} else {
			loginMemberId = member.getId();
			req.login(new LoginedMember(loginMemberId));
			// 기존 회원 분기 처리
			if (member.getNickName() == null) {
				return "redirect:/usr/member/info";
			}
			if (!customCharacterService.exists(loginMemberId)) {
				return "redirect:/usr/member/customCharacterPage";
			}
			return "redirect:/usr/game/startMap";
		}
	}

	@GetMapping("/usr/member/naverCallback")
	public String naverCallback(@RequestParam String code, @RequestParam String state) {
		String accessToken = naverService.getAccessToken(code, state);
		NaverUserInfo userInfo = naverService.getUserInfo(accessToken);
		int loginMemberId;
		Member member = memberService.getMemberByEmail(userInfo.getEmail());
		if (member == null) {
			memberService.signupMember("naver", userInfo.getEmail(), null, null);
			loginMemberId = memberService.getLastInsertId();
			req.login(new LoginedMember(loginMemberId));
			return "redirect:/usr/member/info";
		} else {
			loginMemberId = member.getId();
			req.login(new LoginedMember(loginMemberId));
			// 기존 회원 분기 처리
			if (member.getNickName() == null) {
				return "redirect:/usr/member/info";
			}
			if (!customCharacterService.exists(loginMemberId)) {
				return "redirect:/usr/member/customCharacterPage";
			}
			return "redirect:/usr/game/startMap";
		}
	}

	// ✅ 구글 로그인 콜백
	@GetMapping("/usr/member/googleCallback")
	public String googleCallback(@RequestParam String code) {
		String accessToken = googleService.getAccessToken(code);
		GoogleUserInfo userInfo = googleService.getUserInfo(accessToken);
		int loginMemberId;
		Member member = memberService.getMemberByEmail(userInfo.getEmail());
		if (member == null) {
			memberService.signupMember("google", userInfo.getEmail(), null, null);
			loginMemberId = memberService.getLastInsertId();
			req.login(new LoginedMember(loginMemberId));
			return "redirect:/usr/member/info";
		} else {
			loginMemberId = member.getId();
			System.out.println(member);
			req.login(new LoginedMember(loginMemberId));
			// 기존 회원 분기 처리
			if (member.getNickName() == null) {
				return "redirect:/usr/member/info";
			}
			if (!customCharacterService.exists(loginMemberId)) {
				return "redirect:/usr/member/customCharacterPage";
			}
			return "redirect:/usr/game/startMap";
		}

	}

	@GetMapping("/usr/member/login")
	public String login() {
		if (req.getLoginedMember() == null || req.getLoginedMember().getId() == 0) {
			System.out.println(req.getLoginedMember().getId());
			return "usr/member/login";
		}
		return "redirect:/usr/game/startMap";
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

		if (member.getNickName() == null) {
			return Util.jsReplace("환영합니다 최초 닉네임을 설정하세요", "/usr/member/info");
		}

		System.out.println(customCharacterService.exists(member.getId()));

		if (customCharacterService.exists(member.getId())) {
			return Util.jsReplace("환영합니다", "/usr/game/startMap");
		}

		return Util.jsReplace("환영합니다", "/usr/member/customCharacterPage");
	}

	@GetMapping("/usr/member/logout")
	@ResponseBody
	public String logout(HttpServletRequest request, HttpServletResponse response) {
		String oldSessionId = request.getSession().getId();
		System.out.println("로그아웃 전 세션ID: " + oldSessionId);
		this.req.logout();
		Cookie jsessionCookie = new Cookie("JSESSIONID", null);
		jsessionCookie.setMaxAge(0);
		jsessionCookie.setPath("/");
		response.addCookie(jsessionCookie);
		Cookie[] cookies = request.getCookies();
		if (cookies != null) {
			for (Cookie cookie : cookies) {
				Cookie deleteCookie = new Cookie(cookie.getName(), null);
				deleteCookie.setMaxAge(0);
				deleteCookie.setPath("/");
				response.addCookie(deleteCookie);
			}
		}
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

		Member member = this.memberService.getMemberByEmail(email);

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

	@GetMapping("/usr/member/info")
	public String info(Model model) {
		int loginedMember = this.req.getLoginedMember().getId();

		model.addAttribute("loginedMember", loginedMember);

		return "usr/member/info";
	}

	@PostMapping("/usr/member/memberInfo")
	@ResponseBody
	public String memberInfo(int memberId, String nickName) {

		Member member = this.memberService.getMemberByNickName(nickName);

		if (member != null) {
			return Util.jsReplace(String.format("[ %s ] 은(는) 이미 사용중인 닉네임입니다", nickName), "usr/member/info");
		}

		this.memberService.insertNickName(memberId, nickName);

		return Util.jsReplace("닉네임 등록이 완료되었습니다", "/usr/member/customCharacterPage");
	}

	@GetMapping("/usr/member/nickNameDupChk")
	@ResponseBody
	public ResultData nickNameDupChk(String nickName) {

		Member member = this.memberService.getMemberByNickName(nickName);

		if (member != null) {
			return ResultData.from("F-1", String.format("[ %s ] 은(는) 이미 사용중인 닉네임입니다", nickName));
		}

		return ResultData.from("S-1", "사용 가능한 닉네임입니다");
	}

	// 이메일 인증번호 보내기
	@GetMapping("/usr/member/sendToEmailForconfirm")
	@ResponseBody
	public String sendToEmailForconfirm(@RequestParam String email) {
		emailAuthService.sendAuthCode(email);
		return "인증코드가 전송되었습니다.";
	}

	@GetMapping("/usr/member/verifyEmailCode")
	@ResponseBody
	public String verifyEmailCode(@RequestParam String email, @RequestParam String code) {
		boolean success = emailAuthService.verifyCode(email, code);
		return success ? "인증 성공" : "인증 실패";
	}

	@GetMapping("/usr/member/customCharacterPage")
	public String customCharacterPage(Model model, @RequestParam(required = false) String fromMap) {
		int id = req.getLoginedMember().getId();

		Member member = this.memberService.getMemberById(id);

		model.addAttribute("member", member);
		model.addAttribute("memberId", member.getId());
	    model.addAttribute("nickName", member.getNickName());
	    model.addAttribute("fromMap", fromMap);

		return "usr/member/customCharacterPage";
	}

}