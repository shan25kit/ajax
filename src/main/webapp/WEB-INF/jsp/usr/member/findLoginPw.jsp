<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>
		const findLoginPw = async function() {
			let inputLoginId = $("input[name='loginId']");
			let inputEmail = $("input[name='email']");
			
			let inputLoginIdTrim = inputLoginId.val(inputLoginId.val().trim());
			let inputEmailTrim = inputEmail.val(inputEmail.val().trim());
			
			if (inputLoginIdTrim.val().length == 0) {
				alert('아이디를 입력해주세요');
				inputLoginId.focus();
				return;
			}
			
			if (inputEmailTrim.val().length == 0) {
				alert('이메일을 입력해주세요');
				inputEmail.focus();
				return;
			}
	
			$('#findBtn').prop('disabled', true);
			$('.loading-layer').show();
			
			const rs = await doFindLoginPw(inputLoginIdTrim.val(), inputEmailTrim.val());
	
			if (rs) {
				alert(rs.rsMsg);
				$('.loading-layer').hide();
				$('#findBtn').prop('disabled', false);
				
				if (rs.success) {
					location.replace("login");
				} else {
					inputLoginId.val('');
					inputEmail.val('');
					inputLoginId.focus();
				}
			}
		}
		
		const doFindLoginPw = function(loginId, email) {
			return $.ajax({
				url : '/usr/member/doFindLoginPw',
				type : 'GET',
				data : {
					loginId : loginId,
					email : email
				},
				dataType : 'json'
			})
		}
	</script>

	<div  class="background">
	
		<div class="logo-top">
			<img src="/resource/img/logo-w.png" alt="온기로고" />
		</div>
	
		<div class="find-box glossy">
		
			<h3 class="find_header">Reset Your Password</h3>
			
			<div class="find_inner_box">
				<div>
					<input class="input input-neutral" name="loginId" type="text" placeholder="ID" required/><br />
					<input class="input input-neutral" name="email" type="text" placeholder="Email" required/><br />
					<button id="findBtn" onclick="findLoginPw();">Forgot Password</button><br />
					<div class="find-pw">
						<a href="findLoginId">Forgot ID?</a><br />
						<a href="login">Login</a>
					</div>
				</div>
			</div>
		</div>
	</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>