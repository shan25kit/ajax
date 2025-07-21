<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="StartMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>
<script type="text/javascript">
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
</script>
  <!-- 맵 컨테이너 -->
    <div class="map-container" id="mapContainer">
       
            <!-- 배경 이미지 -->
            <img id="mapImage" src="/resource/img/background-1.png" alt="map" />
            
            <!-- 마스킹 캔버스 -->
            <canvas id="mapCanvas" width="5055" height="3904"></canvas>
            <canvas id="threeCanvas" style="position:absolute; top:0; left:0; z-index:20; pointer-events:none;"></canvas>

            <!-- 구름 애니메이션 -->
            <div class="clouds">
                <img class="first_cloud" src="/resource/img/cloud1.png" alt="구름1" />
                <img class="second_cloud" src="/resource/img/cloud2.png" alt="구름2" />
                <img class="third_cloud" src="/resource/img/cloud3.png" alt="구름3" />
            </div>
    
    </div>

    <!-- 포털 레이어 -->
    <div id="portalLayer">
        <div id="portal_1" class="portal_1">
            <img class="portal_back" src="/resource/img/portal_back.png" />
            <img class="portal_center" src="/resource/img/portal_cneter.png" />
            <img class="portal_inside" src="/resource/img/portal_inside_center.gif" />
        </div>

        <div id="portal_2" class="portal_2">
            <img class="portal_back" src="/resource/img/portal_right-back.png" />
            <img class="portal_center" src="/resource/img/portal_right1.png" />
            <img class="portal_inside" src="/resource/img/portal_inside_right.gif" />
        </div>
        
        <div id="portal_3" class="portal_3">
            <img class="portal_back" src="/resource/img/portal_right-back2.png" />
            <img class="portal_center" src="/resource/img/portal_right2.png" />
            <img class="portal_inside" src="/resource/img/portal_inside_right2.gif" />
        </div>
        
        <div id="portal_4" class="portal_4">
            <img class="portal_back" src="/resource/img/portal_right-back.png" />
            <img class="portal_center" src="/resource/img/portal_left1.png" />
            <img class="portal_inside" src="/resource/img/portal_inside_right.gif"/>
        </div>
        
        <div id="portal_5" class="portal_5">
            <img class="portal_back" src="/resource/img/portal_right-back2.png" />
            <img class="portal_center" src="/resource/img/portal_left2.png" />
            <img class="portal_inside" src="/resource/img/portal_inside_right2.gif"/>
        </div>
        
        <div id="object" class="object">
            <img class="fountain" src="/resource/img/fountain.png" />
        </div>
    </div>

    <!-- 채팅 시스템 -->
    <div class="player-chat-container" id="chatContainer">
        <div class="chat-header">
            <div class="chat-title-wrapper">
                <div class="chat-icon">💬</div>
                <span class="chat-title">대화</span>
            </div>
            <button class="chat-toggle" id="chatToggle">−</button>
        </div>
        <div class="chat-messages" id="chatMessages">
            <!-- 채팅 메시지들이 여기에 추가됩니다 -->
        </div>
        <div class="chat-input-area">
            <div class="input-wrapper">
                <input type="text" id="chatInput" class="clean-input"
                    placeholder="메시지를 입력하세요..." maxlength="200">
                <button id="chatSend" class="send-button">
                    <span class="send-icon">↗</span>
                </button>
            </div>
            <!-- 메시지 종류 선택 버튼 숨김 -->
            <input type="hidden" id="chatType" value="MAP">
        </div>
    </div>

    <!-- jQuery (채팅 시스템용) -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <!-- 메인 스크립트 -->
    <script type="module" src="/resource/js/main.js"></script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>