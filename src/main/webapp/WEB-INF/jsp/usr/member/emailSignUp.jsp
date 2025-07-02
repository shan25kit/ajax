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

		// 모든 input에서 기존 클래스 제거
		[form.loginId, form.loginPw, form.loginPwChk, form.email].forEach(input => {
			input.classList.remove("input-error", "input-success");
		});

		if (form.loginId.value.length == 0 || form.loginId.value != validLoginId) {
			form.loginId.classList.add("input-error");
			form.loginId.focus();
			return false;
		}

		if (form.loginPw.value.length == 0) {
			form.loginPw.classList.add("input-error");
			form.loginPw.focus();
			return false;
		}

		if (form.loginPw.value !== form.loginPwChk.value) {
			form.loginPw.classList.add("input-error");
			form.loginPwChk.classList.add("input-error");
			form.loginPw.focus();
			return false;
		}

		if (form.email.value.length == 0 || form.email.value != validEmail) {
			form.email.classList.add("input-error");
			form.email.focus();
			return false;
		}

		return true;
	}

	
	const checkPwMatch = function() {
		const pw = document.querySelector('input[name="loginPw"]').value.trim();
		const pwChkInput = document.querySelector('input[name="loginPwChk"]');
		const msgEl = document.querySelector('#pwChkMsg');

		pwChkInput.classList.remove('input-error', 'input-success');
		msgEl.textContent = '';
		msgEl.removeAttribute('style'); // 초기화

		if (pwChkInput.value.trim().length === 0) {
			return;
		}

		if (pw === pwChkInput.value.trim()) {
			pwChkInput.classList.add('input-success');
			msgEl.textContent = 'Passwords match';
			msgEl.style.color = 'green'; // ✅ 직접 스타일 주기
		} else {
			pwChkInput.classList.add('input-error');
			msgEl.textContent = 'Passwords do not match';
			msgEl.style.color = 'red'; // ✅ 직접 스타일 주기
		}
	}




	
	const loginIdDupChk = function(el) {
		el.value = el.value.trim();

		if (el.value.length == 0) {
			el.classList.add("input-error");
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
					el.classList.remove("input-error");
					el.classList.add("input-success");
					validLoginId = el.value;

					// ✅ 잠깐 초록색 보여주고 사라지게
					setTimeout(() => {
						if (document.activeElement !== el) {
							el.classList.remove("input-success");
						}
					}, 1000);

				} else {
					el.classList.remove("input-success");
					el.classList.add("input-error");
					validLoginId = null;
				}
			}
		});
	}


	
	const emailDupChk = function(el) {
		el.value = el.value.trim();

		if (el.value.length == 0) {
			el.classList.add("input-error");
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
					el.classList.remove("input-error");
					el.classList.add("input-success");
					validEmail = el.value;

					// ✅ 잠깐 초록색 보여주고 사라지게
					setTimeout(() => {
						if (document.activeElement !== el) {
							el.classList.remove("input-success");
						}
					}, 1000);

				} else {
					el.classList.remove("input-success");
					el.classList.add("input-error");
					validEmail = null;
				}
			}
		});
	}
	
	window.addEventListener("DOMContentLoaded", () => {
		const inputs = document.querySelectorAll("input");

		inputs.forEach(input => {
			// focus 시 에러 테두리 제거
			input.addEventListener("focus", () => {
				input.classList.remove("input-error");
			});

			// blur 시 초록 테두리/배경 제거 (비밀번호 확인은 제외)
			input.addEventListener("blur", () => {
				if (input.name !== "loginPwChk") {
					input.classList.remove("input-success");
					input.style.backgroundColor = ""; // ✅ 배경 초기화
				}
			});
		});
	});




	
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
