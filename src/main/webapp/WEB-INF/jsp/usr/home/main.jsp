<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<div class="background">

	<div class="logo">
		<img src="/resource/img/logo-w-slogan.png" alt="온기로고" />
	</div>

	<div id="lottie-icon" style="width: 100px; height: 100px;"></div>
	
	<div class="login_page_button glassy-button">
		<a href="/usr/member/login">입장하기</a>
	</div>

	<div class="textBox">
		<ul>
			<li>
				<p>거울 앞에서 옷 고르는 중 ···</p>
			</li>
			<li>
				<p>마을에 나무를 심는 중 ···</p>
			</li>
			<li>
				<p>기쁨의 맵을 생성하는 중 ···</p>
			</li>
			<li>
				<p>상담 NPC가 공부하는 중 ···</p>
			</li>
			<li>
				<p>감정을 다스리는 중 ···</p>
			</li>
			<li>
				<p>친구와 약속 잡는 중 ···</p>
			</li>
			<li>
				<p>분수대에 물 채우는 중 ···</p>
			</li>

		</ul>
	</div>

</div>


<!-- 하단 텍스트 슬라이드 스크립트 -->

<script>
	$(document).ready(function() {
		let $textBox = $('.textBox ul');
		let $items = $textBox.find('li');
		let currentIndex = 0;
		let itemCount = $items.length;
		let itemWidth = $items.outerWidth(true); // li 너비 + margin

		// ul의 너비를 li * 갯수로 설정
		$textBox.css({
			width : itemWidth * itemCount,
			display : 'flex',
			padding : 0,
			margin : 0
		});

		function slideNext() {
			currentIndex++;
			if (currentIndex >= itemCount) {
				// 마지막 다음엔 처음으로 리셋
				currentIndex = 0;
			}

			$textBox.animate({
				marginLeft : -itemWidth * currentIndex
			}, 500);
		}

		setInterval(slideNext, 3500);
	});
</script>


<!-- 로딩 애니메이션 스크립트 -->

<script>
	lottie.loadAnimation({
		container : document.getElementById('lottie-icon'), // 표시할 div
		renderer : 'svg',
		loop : true,
		autoplay : true,
		path : '/resource/lottie/loading2.json' // Spring Boot static 경로 기준
	});
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>