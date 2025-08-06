<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="sadMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<div class="top-nav">
		<a href="/usr/member/customCharacterPage" class="nav-icon"><i class="fa-solid fa-circle-user"></i>
		<span class="nav-text">MYPAGE</span></a>
		<a href="/usr/member/logout" class="nav-icon"><i class="fa-solid fa-right-from-bracket"></i>
		<span class="nav-text">LOGOUT</span></a>
	</div>
<!-- 맵 컨테이너 -->
<div class="map-container" id="mapContainer">

	<!-- 배경 이미지 -->
	<img id="mapImage" src="/resource/img/슬픔의맵.png" alt="map" />

	<!-- 마스킹 캔버스 -->
	<canvas id="mapCanvas" width="5055" height="3904"></canvas>
	<div class="character-container" id="characterContainer">
		<div class="character-3d" id="character3D"></div>
	</div>
</div>

<!-- 오브젝트 -->
 <div id="portalLayer">
	<div id="portal_6" class="portal_6">
		<img class="portal_back" src="/resource/img/portal_right-back2.png" />
		<img class="portal_center" src="/resource/img/portal_left2.png" /> 
		<img class="portal_inside" src="/resource/img/portal_inside_right2.gif" />
	</div>
</div>
<div id="aiChatbot" class="ai-chatbot">
    <img class="chatbot-character" src="/resource/img/슬픔의맵NPC.gif" alt="AI 상담사" />
</div>

<!-- 채팅 시스템 -->
<div class="player-chat-container" id="chatContainer">
	<div class="player-chat-header">
		<div class="player-chat-title-wrapper">
			<div class="player-chat-icon">💬</div>
			<span class="player-chat-title">대화</span>
		</div>
		<button class="player-chat-toggle" id="chatToggle">−</button>
	</div>
	<div class="player-chat-messages" id="chatMessages">
		<!-- 채팅 메시지들이 여기에 추가됩니다 -->
	</div>
	<div class="player-chat-input-area">
		<div class="player-input-wrapper">
			<input type="text" id="chatInput" class="player-input"
				placeholder="메시지를 입력하세요..." maxlength="200">
			<button id="chatSend" class="player-send-button">
				<span class="player-send-icon">↗</span>
			</button>
		</div>
		<!-- 메시지 종류 선택 버튼 숨김 -->
		<input type="hidden" id="chatType" value="MAP">
	</div>
</div>

<!-- 메인 스크립트 -->
<script type="module">
    import { GameClient } from '/resource/js/core/GameClient.js';
		
	const currentMapName = "sadMap";
	console.log(currentMapName);
	
	console.log('=== 서버 데이터 원본 ===');
 	console.log('Member ID Raw:', '${player.memberId}');
 	console.log('Nick Name Raw:', '${player.nickName}');
 	console.log('Avatar Info Raw:', '${player.avatarInfo}');
 
        // 서버에서 전달받은 플레이어 데이터
     let player = {
            memberId: ${player.memberId},
            nickName: "${player.nickName}",
            avatarInfo: JSON.parse('${player.avatarInfo}')
     };

     console.log('🔍 파싱된 avatarInfo:', player.avatarInfo);
		
	 async function startGame() {
  		try {
       		 console.log('🎮 게임 시작');

        if (typeof THREE === 'undefined') {
            console.error('THREE.js가 로드되지 않았습니다!');
            return;
        }
        
        console.log('✅ 라이브러리 로드 완료');


        // 게임 클라이언트 생성 및 초기화
        const gameClient = new GameClient();
        await gameClient.initialize(player, currentMapName);
        
        // 서버 연결
        await gameClient.connect();
        
        // 게임 시작
        gameClient.startGame();
        
       // 디버그 활성화
        gameClient.enableDebugMode(); 


        // 전역 등록
        window.gameClient = gameClient;
        window.gameDebug = gameClient;

        console.log('✅ 게임 시작 완료');
        console.log('💡 window.gameDebug 사용 가능');

    } catch (error) {
        console.error('❌ 게임 시작 실패:', error);
        alert(`게임 시작 실패: ${error.message}`);
    }
}
// ===== 정리 =====
window.addEventListener('beforeunload', () => {
    window.gameClient?.destroy();
});

// ===== 시작 =====
document.addEventListener('DOMContentLoaded', startGame);

</script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>