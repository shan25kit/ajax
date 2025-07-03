<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>


<div class="background">

	<div class="logo-top">
		<img src="/resource/img/logo-w.png" alt="온기로고" />
	</div>

	
	<div class="login-box glossy">

		<h3 class="login_header">SING UP</h3>

		<div class="login_inner_box">

		<!-- SNS 회원가입 버튼 -->

			<div class="social_sign_button">

				<!-- 카카오 회원가입 -->
				<a href="https://kauth.kakao.com/oauth/authorize?client_id=c3bee10d6c467c390191366ebf91e099&redirect_uri=http://localhost:8081/usr/member/kakaoCallback&response_type=code">
					<img src="/resource/img/kakao_logo.png" alt="카카오로 회원가입" />
					<span>Sign Up With Kakao</span>
				</a>



				<!-- 네이버 회원가입 -->
				<a href="https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=PTJar8b7Xfd2XprSDQu0&redirect_uri=http://localhost:8081/usr/member/naverCallback&state=1234">
					<img src="/resource/img/naver_logo.png" alt="네이버로 회원가입" />
					<span>Sign Up With Naver</span>
					
				</a>


				<!-- 구글 회원가입 -->
				<a href="https://accounts.google.com/o/oauth2/v2/auth?client_id=453369456336-r4v3ov9mg6i3lm96jrn095laqgiqlhj2.apps.googleusercontent.com&redirect_uri=http://localhost:8081/usr/member/googleCallback&response_type=code&scope=email%20profile">
					<img src="/resource/img/google_logo.png" alt="구글로 회원가입" />
					<span>Sign Up With Google</span>
				</a>
				
				<!-- 이메일 회원가입 -->
				<div>
					<a href="/usr/member/emailSignUp">Sign up With Email</a>
				</div>
					




			</div>

		</div>

	</div>


</div>