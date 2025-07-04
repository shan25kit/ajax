package com.example.demo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/game")
@CrossOrigin(origins = "*")
public class GameController {
    
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
        info.put("websocket_url", "ws://localhost:8080/game");
        info.put("status", "ready");
        return ResponseEntity.ok(info);
    }
}