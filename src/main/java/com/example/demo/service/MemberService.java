package com.example.demo.service;

import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import com.example.demo.dao.MemberDao;
import com.example.demo.dto.Member;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
public class MemberService {
    
	private MemberDao memberDao;
	private JavaMailSender javaMailSender;
    
	public MemberService(MemberDao memberDao, JavaMailSender javaMailSender) {
		this.memberDao = memberDao;
		this.javaMailSender = javaMailSender;
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

	public Member getMemberByEmail(String email) {
		return this.memberDao.getMemberByEmail(email);
	}

	public String getLoginId(int id) {
		return this.memberDao.getLoginId(id);
	}

	public Member getMemberByNameAndEmail(String email) {
		return memberDao.getMemberByEmail(email);
	}

	public void modifyPassword(int loginedMemberId, String loginPw) {
		this.memberDao.modifyPassword(loginedMemberId, loginPw);
	}
	
	public void sendEmail(String to, String subject, String text) {
        MimeMessage message = this.javaMailSender.createMimeMessage();
        
        try {
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(text, true);
        } catch (MessagingException e) {
            e.printStackTrace();
        }
        
        this.javaMailSender.send(message);
    }
	
    public void sendPasswordRecoveryEmail(Member member, String tempPassword) {
        String subject = "임시 패스워드 발송";
        String text = "<html>"
                    + "<body>"
                    + "<h3>임시 패스워드 : " + tempPassword + "</h3>"
                    + "<a style='display:inline-block;padding:10px;border-radius:10px;border:5px solid black;font-size:4rem;color:inherit;text-decoration:none;' href='http://localhost:8080/usr/member/login' target='_blank'>로그인 하러가기</a>"
                    + "</body>"
                    + "</html>";
        sendEmail(member.getEmail(), subject, text);
    }

	public void emailSignUp(String email, String loginId, String loginPw) {
		this.memberDao.emailSignUp(email, loginId, loginPw);
	}

	public void insertNickName(int memberId, String nickName) {
		this.memberDao.insertNickName(memberId, nickName);
	}

	public Member getMemberByNickName(String nickName) {
		return this.memberDao.getMemberByNickName(nickName);
	}

	public Member getMemberByLoginIdChk(String loginId) {
		return this.memberDao.getMemberByLoginIdChk(loginId);
	}
    
}