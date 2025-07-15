<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="로그인" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<div class="background">

	<div class="logo-top">
		<a href="/usr/home/main">
			<img src="/resource/img/logo-w.png" alt="온기로고" />
		</a>
	</div>

	
	<div class="login-box glossy">

		<div class="login_inner_box">
		
		<h3 class="login_header">LOGIN</h3>

			<!-- 일반 로그인 폼 -->
			<form action="/usr/member/doLogin" method="post">
				<input type="text" name="loginId" required placeholder="ID" /><br />
				<input type="password" name="loginPw" placeholder="Password"
					required /> <a class="find_pw" href="/usr/member/findLoginPw">Forgot Password?</a>
				<button type="submit">LOGIN</button>
			</form>


			<h2 class="or">OR</h2>

			<!-- SNS 로그인 버튼 -->


			<div class="social_login_button">

				<!-- 카카오 로그인 -->
				<a
					href="https://kauth.kakao.com/oauth/authorize?client_id=c3bee10d6c467c390191366ebf91e099&redirect_uri=http://localhost:8081/usr/member/kakaoCallback&response_type=code">
					<img src="/resource/img/kakao_logo.png" alt="카카오로그인" />
				</a>


				<!-- 네이버 로그인 -->
				<a
					href="https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=PTJar8b7Xfd2XprSDQu0&redirect_uri=http://localhost:8081/usr/member/naverCallback&state=1234">
					<img src="/resource/img/naver_logo.png" alt="네이버로그인" />
				</a>

				<!-- 구글 로그인 -->
				<a
					href="https://accounts.google.com/o/oauth2/v2/auth?client_id=453369456336-r4v3ov9mg6i3lm96jrn095laqgiqlhj2.apps.googleusercontent.com&redirect_uri=http://localhost:8081/usr/member/googleCallback&response_type=code&scope=email%20profile">
					<img src="/resource/img/google_logo.png" alt="구글로그인" />
				</a>
				
				


			</div>

		</div>


	</div>

	<div>
		<a href="/usr/member/signup" class="signup_bottom">Sign Up</a>
	</div>



</div>


