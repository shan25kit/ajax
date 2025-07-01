<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>
	let validLoginId = null;
	let validEmail = null;
	
	const loginFormChk = function(form) {
		form.loginId.value = form.loginId.value.trim();
		form.loginPw.value = form.loginPw.value.trim();

		if (form.loginId.value.length == 0) {
			alert('아이디를 입력 해주세요');
			form.loginId.focus();
			return false;
		}

		if (form.loginPw.value.length == 0) {
			alert('비밀번호를 입력 해주세요');
			form.loginPw.focus();
			return false;
		}

		return true;
	}
	
	const signupFormChk = function(form) {
		form.loginId.value = form.loginId.value.trim();
		form.loginPw.value = form.loginPw.value.trim();
		form.loginPwChk.value = form.loginPwChk.value.trim();
		form.email.value = form.email.value.trim();
		form.emailChk.value = form.emailChk.value.trim();
		
		if (form.loginId.value.length == 0) {
			alert('아이디를 입력 해주세요');
			form.loginId.focus();
			return false;
		}

		if (form.loginId.value != validLoginId) {
			alert('[ ' + form.loginId.value + ' ] 은(는) 사용할 수 없는 아이디입니다.');
			form.loginId.value = '';
			form.loginId.focus();
			return false;
		}
		
		if (form.loginPw.value.length == 0) {
			alert('비밀번호를 입력 해주세요');
			form.loginPw.focus();
			return false;
		}

		if (form.loginPw.value != form.loginPwChk.value) {
			form.loginPw.value = '';
			form.loginPwChk.value = '';
			form.loginPw.focus();
			return false;
		}
		
		if (form.email.value.length == 0) {
			alert('이메일을 입력 해주세요');
			form.email.focus();
			return false;
		}

		if (form.email.value != validEmail) {
			alert('[ ' + form.email.value + ' ] 은(는) 이미 가입된 이메일입니다.');
			form.email.value = '';
			form.email.focus();
			return false;
		}
	}
	
	const checkPwMatch = function() {
		const pw = document.querySelector('input[name="loginPw"]').value.trim();
		const pwChk = document.querySelector('input[name="loginPwChk"]').value.trim();
		const msgEl = document.querySelector('#pwChkMsg');

		if (pwChk.length === 0) {
			msgEl.textContent = '';
			return;
		}

		if (pw === pwChk) {
			msgEl.classList.remove('text-red-500');
			msgEl.classList.add('text-green-500');
			msgEl.textContent = '비밀번호가 일치합니다';
		} else {
			msgEl.classList.remove('text-green-500');
			msgEl.classList.add('text-red-500');
			msgEl.textContent = '비밀번호가 일치하지 않습니다';
		}
	}

	
	const loginIdDupChk = function(el) {
		el.value = el.value.trim();

		let loginIdDupChkMsg = $('#loginIdDupChkMsg');

		if (el.value.length == 0) {
			loginIdDupChkMsg.removeClass('text-green-500');
			loginIdDupChkMsg.addClass('text-red-500');
			loginIdDupChkMsg.html('아이디를 입력 해주세요');
			return;
		}

		$.ajax({
			url: '/usr/member/loginIdDupChk',
			type: 'GET',
			data: {
				loginId: el.value
			},
			dataType: 'json',
			success: function(data) {
				if (data.success) {
					loginIdDupChkMsg.removeClass('text-red-500');
					loginIdDupChkMsg.addClass('text-green-500');
					loginIdDupChkMsg.html(`${data.rsMsg}`);
					validLoginId = el.value;
				} else {
					loginIdDupChkMsg.removeClass('text-green-500');
					loginIdDupChkMsg.addClass('text-red-500');
					loginIdDupChkMsg.html(`${data.rsMsg}`);
					validLoginId = null;
				}
			},
			error: function(_xhr, _status, error) {
				console.log(error);
			}
		})
	}
	
	const emailDupChk = function(el) {
		el.value = el.value.trim();

		let emailDupChkMsg = $('#emailDupChkMsg');

		if (el.value.length == 0) {
			emailDupChkMsg.removeClass('text-green-500');
			emailDupChkMsg.addClass('text-red-500');
			emailDupChkMsg.html('이메일을 입력 해주세요');
			return;
		}

		$.ajax({
			url: '/usr/member/emailDupChk',
			type: 'GET',
			data: {
				email: el.value
			},
			dataType: 'json',
			success: function(data) {
				if (data.success) {
					emailDupChkMsg.removeClass('text-red-500');
					emailDupChkMsg.addClass('text-green-500');
					emailDupChkMsg.html(`${data.rsMsg}`);
					validEmail = el.value;
				} else {
					emailDupChkMsg.removeClass('text-green-500');
					emailDupChkMsg.addClass('text-red-500');
					emailDupChkMsg.html(`${data.rsMsg}`);
					validEmail = null;
				}
			},
			error: function(_xhr, _status, error) {
				console.log(error);
			}
		})
	}
	
</script>

<div class="background">

	<div class="logo-top">
		<img src="/resource/img/logo-w.png" alt="온기로고" />
	</div>

	
	<div class="login-box glossy">

		<h3 class="login_header">SING UP</h3>

		<div class="signup_inner_box">

		<!-- email 회원가입 버튼 -->

			<div class="email_sign_button">

				
				<form action="/usr/member/doSignUp" method="post" onsubmit="return signupFormChk(this);">
				    <input type="hidden" name="loginType" value="normal" />
				
				    <input type="email" name="email" onblur="emailDupChk(this);" placeholder="Email" required /><br/>
					<span id="emailDupChkMsg"></span>
					<input type="hidden" name="emailChk" />
				
				    <input type="text" name="loginId" onblur="loginIdDupChk(this);" placeholder="LoginId" required /><br/>
				    <span id="loginIdDupChkMsg"></span>
				
				    <input type="password" name="loginPw" placeholder="Password" required /><br/>
				    
				    <input type="password" name="loginPwChk" placeholder="Check Password" required oninput="checkPwMatch();" /><br/>
				    <span id="pwChkMsg"></span>
				
				    <button type="submit">Send Verification Email</button>
				</form>
					




			</div>

		</div>

	</div>


</div>
