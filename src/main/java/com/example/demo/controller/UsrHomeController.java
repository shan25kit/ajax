package com.example.demo.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import jakarta.servlet.http.HttpServletRequest;

@Controller
public class UsrHomeController {

	@GetMapping("/usr/home/main")
	public String showMain(HttpServletRequest request) {
		String newSessionId = request.getSession().getId();
		System.out.println("새 세션ID: " + newSessionId);
		return "usr/home/main";
	}

	@GetMapping("/")
	public String showRoot() {
		return "redirect:/usr/home/main";
	}

}