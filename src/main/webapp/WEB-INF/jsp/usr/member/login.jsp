<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<!-- 일반 로그인 폼 -->
<form action="/usr/member/doLogin" method="post">
    <label>아이디</label><br/>
    <input type="text" name="loginId" required /><br/><br/>

    <label>비밀번호</label><br/>
    <input type="password" name="loginPw" required /><br/><br/>

    <button type="submit">로그인</button>
</form>

<hr/>

<!-- SNS 로그인 버튼 -->
<h2>SNS로 로그인</h2>

<!-- 카카오 로그인 -->
<a href="https://kauth.kakao.com/oauth/authorize?client_id=c3bee10d6c467c390191366ebf91e099&redirect_uri=http://localhost:8081/usr/member/kakaoCallback&response_type=code">카카오로 로그인</a>


<!-- 네이버 로그인 -->
<a href="https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=PTJar8b7Xfd2XprSDQu0&redirect_uri=http://localhost:8081/usr/member/naverCallback&state=1234">네이버 로그인</a>

<!-- 구글 로그인 -->
<a href="https://accounts.google.com/o/oauth2/v2/auth?client_id=453369456336-r4v3ov9mg6i3lm96jrn095laqgiqlhj2.apps.googleusercontent.com&redirect_uri=http://localhost:8081/usr/member/googleCallback&response_type=code&scope=email%20profile">구글 로그인</a>