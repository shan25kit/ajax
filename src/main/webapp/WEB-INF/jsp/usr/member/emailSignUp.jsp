<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="회원가입" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script>
$(document).ready(function() {
    // 인증코드 발송 버튼 클릭
    $('.email_check_button').click(function() {
        let email = $('input[name="email"]').val().trim();
        
        if (email.length === 0) {
            alert('이메일을 입력해주세요.');
            return;
        }
        
        $.ajax({
            url: '/usr/member/sendToEmailForconfirm',
            type: 'GET',
            data: { email: email },
            success: function(data) {
                alert(data);
                $('.email_check_box').css('display', 'block');
            },
            error: function() {
                alert('인증코드 발송 중 오류가 발생했습니다.');
            }
        });
    });
    
    // 이메일 중복 체크 (blur 시)
$('input[name="email"]').blur(function() {
    let email = $(this).val().trim();

    if (email.length === 0) {
        $('#emailDupMsg').text('');
        $('.email_check_button').prop('disabled', true);
        return;
    }

    $.ajax({
        url: '/usr/member/emailDupChk',
        type: 'GET',
        data: { email: email },
        success: function(data) {
            console.log('이메일 중복 체크 응답:', data);

            if (data.rsCode.startsWith('F-')) {
                $('#emailDupMsg')
                    .text(data.rsMsg)
                    .css('color', 'white')
                    .css('display', 'block');
                // 중복 없을 때 버튼 활성화
                $('.email_check_button')
                    .prop('disabled', false)
                    .css('background-color', '#662c77')
                    .css('cursor', 'pointer');
            } else {
                $('#emailDupMsg')
                    .text(data.rsMsg)
                    .css('color', 'rgb(255, 66, 66)');
                // 중복 있을 때 버튼 비활성화
                $('.email_check_button').prop('disabled', true);
            }
        }, // <-- success 콜백 닫힘
        error: function(xhr, status, error) {
            console.error('이메일 중복 체크 중 에러:', error);
            alert('이메일 중복 체크 요청에 실패했습니다.');
            $('.email_check_button').prop('disabled', true);
        } // <-- error 콜백 닫힘
    }); // <-- $.ajax 옵션 객체 닫힘 및 호출 끝
}); // <-- blur 콜백 닫힘

    // 이메일 인증코드 확인
    $('.email_check_confirm').click(function(event) {
        event.preventDefault(); // form submit 막음

        let email = $('input[name="email"]').val().trim();
        let code = $('input[name="code"]').val().trim();

        if (email.length === 0) {
            alert('이메일을 입력해주세요.');
            return;
        }

        if (code.length === 0) {
            alert('인증코드를 입력해주세요.');
            return;
        }

        $.ajax({
            url: '/usr/member/verifyEmailCode',
            type: 'GET',
            data: { email: email, code: code },
            success: function(data) {
                console.log('인증코드 확인 응답:', data);
                if (data === '인증 성공') {
                    $('input[name="loginId"]').prop('disabled', false);
                    $('input[name="loginPw"]').prop('disabled', false);
                    $('input[name="loginPwChk"]').prop('disabled', false);
                    alert('이메일 인증이 완료되었습니다.');
                } else {
                    alert('인증코드를 확인해주세요.');
                }
            },
            error: function(xhr, status, error) {
                console.error('인증코드 확인 중 에러:', error);
                alert('인증코드 확인 요청 중 오류가 발생했습니다.');
            }
        });
    });
    

    // Login ID 중복체크 (onblur)
    $('input[name="loginId"]').blur(function() {
        let loginId = $(this).val().trim();

        if (loginId.length === 0) {
            $('#loginIdDupChkMsg').text('');
            return;
        }

        $.ajax({
            url: '/usr/member/loginIdDupChk',
            type: 'GET',
            data: { loginId: loginId },
            success: function(data) {
                console.log("Login ID 중복 체크 응답:", data);
                if (data.rsCode.startsWith('S-')) {
                    $('#loginIdDupChkMsg').text(data.rsMsg)
                        .css('color', 'white')
                        .css('display', 'block');
                } else {
                    $('#loginIdDupChkMsg').text(data.rsMsg)
                        .css('color', 'rgb(255, 66, 66)')
                        .css('display', 'block');
                }
            },
            error: function() {
                alert('Login ID 중복 체크 요청에 실패했습니다.');
            }
        });
    });
    
    // 비밀번호 확인 체크 (oninput)
    $('input[name="loginPwChk"]').on('input', function() {
        let pw = $('input[name="loginPw"]').val();
        let pwChk = $(this).val();

        if (pw === pwChk) {
            $('#pwChkMsg').text('비밀번호가 일치합니다.')
                .css('color', 'white')
                .css('display', 'block');
        } else {
            $('#pwChkMsg').text('비밀번호가 일치하지 않습니다.')
                .css('color', 'rgb(255, 66, 66)')
                .css('display', 'block');
        }
    });
    
	  // email_input form 에서 email 값 가져오기
    $('.submit_button').click(function(event) {
    	  let emailVal = $('.email_input input[name="email"]').val().trim();
    	  $('input[name="email"][type="hidden"]').val(emailVal);
    	});
    
    
    // 폼 제출 시 유효성 검사
    $('.signUp_box').submit(function(event) {
        let loginId = $('input[name="loginId"]').val().trim();
        let loginPw = $('input[name="loginPw"]').val().trim();
        let loginPwChk = $('input[name="loginPwChk"]').val().trim();
        
        if (loginId.length === 0) {
            alert('Login ID를 입력해주세요.');
            event.preventDefault();
            return;
        }
        
        if (loginPw.length === 0) {
            alert('비밀번호를 입력해주세요.');
            event.preventDefault();
            return;
        }
        
        if (loginPw !== loginPwChk) {
            alert('비밀번호가 일치하지 않습니다.');
            event.preventDefault();
            return;
        }
       
    });
});
</script>


<div class="background">

	<div class="logo-top">
		<a href="/usr/home/main">
			<img src="/resource/img/logo-w.png" alt="온기로고" />
		</a>
	</div>


	<div class="login-box glossy">

		<h3 class="login_header">SIGN UP</h3>

		<div class="signup_inner_box">

			<!-- email 회원가입 버튼 -->

			<div class="email_sign_button">

				<form class="email_input">
					<div class="email_check">
						<input type="email" name="email" placeholder="e-mail" required />
						<button class="email_check_button" type="button">인증키 발송</button>
					</div>
					<p id="emailDupMsg"></p>
				</form>

				<form class="email_check_box" style="display: none"
					action="/usr/member/verifyEmailCode" method="get">
					<input type="text" name="code" placeholder="인증코드 입력" required />
					<button class="email_check_confirm" type="button">확인</button>
				</form>

				<form class="signUp_box" action="doSignUp" method="post">
					<input type="hidden" name="email" />
					<input type="hidden" name="loginType" value="normal" />
					<input type="text" name="loginId" placeholder="Login ID" required disabled />
					<p id="loginIdDupChkMsg"></p>
					<input type="password" name="loginPw" placeholder="Password" required disabled /><br />
					<input type="password" name="loginPwChk" placeholder="Check Password" required disabled />
					<p id="pwChkMsg"></p>

					<button class="submit_button" type="submit">Sign Up</button>
				</form>

			</div>

		</div>

	</div>


</div>
