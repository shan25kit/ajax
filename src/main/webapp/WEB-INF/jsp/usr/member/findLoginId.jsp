<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>Add commentMore actions
		const findLoginId = async function() {
			let inputName = $("input[name='name']");
			let inputEmail = $("input[name='email']");
			
			let inputNameTrim = inputName.val(inputName.val().trim());
			let inputEmailTrim = inputEmail.val(inputEmail.val().trim());
			
			if (inputNameTrim.val().length == 0) {
				alert('이름을 입력해주세요');
				inputName.focus();
				return;
			}
			
			if (inputEmailTrim.val().length == 0) {
				alert('이메일을 입력해주세요');
				inputEmail.focus();
				return;
			}
	
			const rs = await doFindLoginId(inputNameTrim.val(), inputEmailTrim.val());
	
			if (rs) {
				alert(rs.rsMsg);
				
				if (rs.success) {
					location.replace("login");
				} else {
					inputName.val('');
					inputEmail.val('');
					inputName.focus();
				}
			}
		}
		
		const doFindLoginId = function(name, email) {
			return $.ajax({
				url : '/usr/member/doFindLoginId',
				type : 'GET',
				data : {
					name : name,
					email : email
				},
				dataType : 'json'
			})
		}
	</script>

	<div>
		<div>
			<div>
				<div>
					<div>
						<div>이름</div>
						<div><input class="input input-neutral" name="name" type="text" /></div>
					</div>
					<div>
						<div>이메일</div>
						<div><input class="input input-neutral" name="email" type="text" /></div>
					</div>
					<div>
						<div><button onclick="findLoginId();">아이디 찾기</button></div>
					</div>
				</div>
			</div>
			
			<div>
				<div>
					<div><a href="findLoginPw">비밀번호 찾기</a></div>
					<div><a href="login">로그인</a></div>
				</div>
			</div>
		</div>
	</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>