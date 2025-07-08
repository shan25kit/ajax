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

	@GetMapping("/usr/home/chatBot")
	public String chatBot() {
		return "usr/home/chatBot";
	}
	
	@GetMapping("/usr/home/testMap")
	public String testMap() {
		return "usr/home/testMap";
	}
	
	@GetMapping("/usr/home/webSocketTest")
	public String webSocketTest() {
		return "usr/home/webSocketTest";
	}
	
}