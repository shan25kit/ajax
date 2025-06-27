package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.dao.MemberDao;
import com.example.demo.dto.Member;

@Service
public class MemberService {
    
	private MemberDao memberDao;
    
	public MemberService(MemberDao memberDao) {
		this.memberDao = memberDao;
	}

	public void signupMember(String loginType, String email, String loginId, String loginPw) {
		this.memberDao.signupMember(loginType, email, loginId, loginPw);
	}

	public int getLastInsertId() {
		return this.memberDao.getLastInsertId();
	}

	public Member getMemberByLoginId(String loginId) {
		return this.memberDao.getMemberByLoginId(loginId);
	}
    
}