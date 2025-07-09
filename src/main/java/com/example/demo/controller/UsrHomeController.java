package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class UsrHomeController {

	@GetMapping("/usr/home/main")
	public String showMain() {
		return "usr/home/main";
	}

	@GetMapping("/")
	public String showRoot() {
		return "redirect:/usr/home/main";
	}

	@GetMapping("/usr/game/chatBot")
	public String chatBot() {
		return "usr/game/chatBot";
	}
	
	@GetMapping("/usr/game/testMap")
	public String testMap() {
		return "usr/game/testMap";
	}
	
	@GetMapping("/usr/game/webSocketTest")
	public String webSocketTest() {
		return "usr/game/webSocketTest";
	}
	

}