package com.example.demo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.example.demo.dto.Player;
import com.example.demo.dto.Req;
import com.example.demo.service.GameService;

@Controller
@RequestMapping("/usr/game")
public class GameController {
	private Req req;
	private GameService gameService;
	
	public GameController(Req req, GameService gameService) {
		this.req = req;
		this.gameService = gameService;
	}
	// 유저 정보 로딩
	@GetMapping("")
    public String userInfoload(Model model) {
		System.out.println("=== websocket() 메서드 호출됨 ===");
		int memberId = this.req.getLoginedMember().getId();
		Player player = this.gameService.selectPlayerByMemberId(memberId);
		model.addAttribute("player", player);
        return "usr/game/startMap";
    }

	@GetMapping("/chatBot")
	public String chatBot() {
		return "usr/game/chatBot";
	}
	
	@GetMapping("/testMap")
	public String testMap(Model model) {
		System.out.println("=== websocket() 메서드 호출됨 ===");
		int memberId = this.req.getLoginedMember().getId();
		System.out.println(memberId);
		Player player = this.gameService.selectPlayerByMemberId(memberId);
		System.out.println(player);
		model.addAttribute("player", player);
		return "usr/game/testMap";
	}
	
	// 테스트용 엔드포인트
	@GetMapping("/test")
	public ResponseEntity<Map<String, String>> test() {
		Map<String, String> response = new HashMap<>();
		response.put("status", "success");
		response.put("message", "게임 서버가 정상 작동 중입니다");
		return ResponseEntity.ok(response);
	}

	// WebSocket 연결 정보 엔드포인트
	@GetMapping("/websocket-info")
	public ResponseEntity<Map<String, String>> getWebSocketInfo() {
		Map<String, String> info = new HashMap<>();
		info.put("websocket_url", "ws://localhost:8081/game");
		info.put("status", "ready");
		return ResponseEntity.ok(info);
	}
}