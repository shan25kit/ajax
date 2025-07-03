<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>
let validNickName = null;

const nickNameDupChk = function(el) {
	el.value = el.value.trim();
	const msgEl = document.querySelector('#nickNameDupChkMsg');

	// 입력 안 했으면 메시지 없이 리턴만
	if (el.value.length === 0) {
		msgEl.textContent = '';
		validNickName = null;
		return;
	}

	$.ajax({
		url: '/usr/member/nickNameDupChk',
		type: 'GET',
		data: {
			nickName: el.value
		},
		dataType: 'json',
		success: function(data) {
			msgEl.textContent = data.rsMsg;

			if (data.success) {
				validNickName = el.value;
			} else {
				validNickName = null;
			}
		},
		error: function(_xhr, _status, error) {
			console.log(error);
		}
	});
};

const nickNameFormChk = function(form) {
	form.nickName.value = form.nickName.value.trim();
	form.nickNameChk.value = form.nickName.value;

	// 입력 유무는 required 속성으로 처리되고,
	// 중복 확인만 체크
	if (form.nickName.value !== validNickName) {
		alert(`[ \${form.nickName.value} ] 은(는) 사용할 수 없는 닉네임입니다`);
		form.nickName.focus();
		return false;
	}

	return true;
};

</script>


<div class="background">

	<div class="logo-top">
		<img src="/resource/img/logo-w.png" alt="온기로고" />
	</div>

	
	<div class="login-box glossy">
	
		<h3 class="login_header">EMOVERSE</h3>
		
		<div class="nickname_inner_box">

			<h2>닉네임<span>을 입력해주세요</span></h2>
			
			<!-- 일반 로그인 폼 -->
			<form action="/usr/member/memberInfo" method="post" onsubmit="return nickNameFormChk(this);">
				<input type="hidden" name="memberId" value="${loginedMember }" />
				<div>${loginedMember }</div>
				
				<input type="text" name="nickName" required onblur="nickNameDupChk(this);" />
				<button type="submit">확인</button>
				<br />
				<span id="nickNameDupChkMsg"></span>
				<input type="hidden" name="nickNameChk" />
			</form>


		</div>

	</div>

</div>


