<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>Add commentMore actions
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

	<div>
		<div>
			<div>
				<div>
					<div>
						<div>아이디</div>
						<div><input class="input input-neutral" name="loginId" type="text" /></div>
					</div>
					<div>
						<div>이메일</div>
						<div><input class="input input-neutral" name="email" type="text" /></div>
					</div>
					<div>
						<div>
							<button id="findBtn" onclick="findLoginPw();">비밀번호 찾기</button>
							<div class="mt-4 loading-layer hidden">
								<span class="loading loading-bars loading-xl"></span>
							</div>
						</div>
					</div>
				</div>
			</div>
			
			<div>
				<div>
					<div><a href="findLoginId">아이디 찾기</a></div>
					<div><a href="login">로그인</a></div>
				</div>
			</div>
		</div>
	</div>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>