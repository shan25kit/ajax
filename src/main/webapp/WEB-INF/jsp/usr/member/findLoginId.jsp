<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>
		const findLoginId = async function() {
			let inputEmail = $("input[name='email']");
			
			let inputEmailTrim = inputEmail.val(inputEmail.val().trim());
			
			if (inputEmailTrim.val().length == 0) {
				alert('이메일을 입력해주세요');
				inputEmail.focus();
				return;
			}
	
			const rs = await doFindLoginId(inputEmailTrim.val());
	
			if (rs) {
				alert(rs.rsMsg);
				
				if (rs.success) {
					location.replace("login");
				} else {
					inputEmail.val('');
					inputEmail.focus();
				}
			}
		}
		
		const doFindLoginId = function(email) {
			return $.ajax({
				url : '/usr/member/doFindLoginId',
				type : 'GET',
				data : {
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
		
			<h3 class="find_header">Find Your Login ID</h3>
			
			<div class="find_inner_box">
				<div>
					<input class="input input-neutral" name="email" type="text" placeholder="Email" required/><br />
					<button onclick="findLoginId();">Forgot ID</button>
					<div class="find-pw">
						<a href="findLoginPw">Forgot Password?</a><br />
						<a href="login">Login</a>
					</div>
				</div>
			</div>
		</div>
	</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>