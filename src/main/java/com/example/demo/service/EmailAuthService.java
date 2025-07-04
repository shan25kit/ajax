package com.example.demo.service;

import com.example.demo.dao.EmailAuthDao;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
@RequiredArgsConstructor
public class EmailAuthService {

    private final EmailAuthDao emailAuthDao;
    private final JavaMailSender mailSender;

    public void sendAuthCode(String email) {
        String code = generateCode();
        emailAuthDao.insertEmailAuth(email, code);
        sendEmail(email, code);
    }

    public boolean verifyCode(String email, String code) {
        return emailAuthDao.findValidEmailAuth(email, code) != null;
    }

    private String generateCode() {
        return String.valueOf(100000 + new Random().nextInt(900000));  // 6자리 숫자
    }

    private void sendEmail(String to, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject("이메일 인증 코드");
        message.setText("인증 코드: " + code);
        mailSender.send(message);
    }
}