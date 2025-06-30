package com.example.demo.service;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import com.example.demo.dto.KakaoUserInfo;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class KakaoService {
    private final String REST_API_KEY = "c3bee10d6c467c390191366ebf91e099";
    private final String REDIRECT_URI = "http://localhost:8081/usr/member/kakaoCallback";

    public String getAccessToken(String code) {
        String tokenUrl = "https://kauth.kakao.com/oauth/token";

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "authorization_code");
        params.add("client_id", REST_API_KEY);
        params.add("redirect_uri", REDIRECT_URI);
        params.add("code", code);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(params, headers);
        ResponseEntity<String> response = restTemplate.postForEntity(tokenUrl, request, String.class);

        try {
            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode jsonNode = objectMapper.readTree(response.getBody());
            return jsonNode.get("access_token").asText();
        } catch (Exception e) {
            throw new RuntimeException("토큰 파싱 실패", e);
        }
    }

    public KakaoUserInfo getUserInfo(String accessToken) {
        String userInfoUrl = "https://kapi.kakao.com/v2/user/me";
        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);

        HttpEntity<Void> request = new HttpEntity<>(headers);
        ResponseEntity<String> response = restTemplate.exchange(userInfoUrl, HttpMethod.GET, request, String.class);

        try {
            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode jsonNode = objectMapper.readTree(response.getBody());
            String email = jsonNode.path("kakao_account").path("email").asText();
            return new KakaoUserInfo(email);
        } catch (Exception e) {
            throw new RuntimeException("카카오 유저정보 파싱 실패", e);
        }
    }
}
