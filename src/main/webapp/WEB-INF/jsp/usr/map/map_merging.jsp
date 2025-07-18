<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="StartMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<div class="map-container" id="mapContainer">
  <img id="mapImage" src="/resource/img/background-1.png" alt="스타터맵 이미지" />
  <canvas id="mapCanvas" width="5055" height="3904"></canvas>
  <canvas id="threeCanvas" style="position:absolute; top:0; left:0; z-index:20; pointer-events:none;"></canvas>
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

</div>

<div class="clouds">
			<img class="first_cloud" src="/resource/img/cloud1.png" alt="구름1" />
			<img class="second_cloud" src="/resource/img/cloud2.png" alt="구름2" />
			<img class="third_cloud" src="/resource/img/cloud3.png" alt="구름3" />
		</div>
<!-- 포탈들은 transform 적용 대상 아님, 별도로 DOM에 위치시킴 -->
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




<!-- 맵 스크립트 -->
<script>
  const mapImage = document.getElementById('mapImage');
  const mapContainer = document.getElementById('mapContainer');
  const canvas = document.getElementById('mapCanvas');
  const ctx = canvas.getContext('2d');

  let scale = 0.5;
  let translateX = 0;
  let translateY = 0;
  const minScale = 0.5;
  const maxScale = 2.5;

  let isDragging = false;
  let startX = 0;
  let startY = 0;
  
  
  //////////////////////////////포탈 영역//////////////////////////////
 const portals = [
  { id: 'portal_1', x: 2200, y: 900 },
  { id: 'portal_2', x: 2978, y: 1150 },
  { id: 'portal_3', x: 2795, y: 1350 },
  { id: 'portal_4', x: 1875, y: 1200 },
  { id: 'portal_5', x: 1538, y: 1370 },
  { id: 'object', x: 2260, y: 1550 }
];

function updatePortals() {
  portals.forEach(p => {
    const el = document.getElementById(p.id);
    const tx = p.x * scale + translateX;
    const ty = p.y * scale + translateY;
    el.style.transform = `translate(\${tx}px, \${ty}px) scale(\${scale})`;
    el.style.transformOrigin = 'top left';
  });
}
  
//////////////////////////////포탈 영역//////////////////////////////

  function updateTransform() {
    const transform = `translate(\${translateX}px, \${translateY}px) scale(\${scale})`;

    mapImage.style.transformOrigin = 'top left';
    canvas.style.transformOrigin = 'top left';

    mapImage.style.transform = transform;
    canvas.style.transform = transform;
    

    drawMaskArea();
    updatePortals();  
  }

  function clampTranslate() {
    const containerWidth = mapContainer.offsetWidth;
    const containerHeight = mapContainer.offsetHeight;
    const imageWidth = mapImage.naturalWidth * scale;
    const imageHeight = mapImage.naturalHeight * scale;

    const minX = containerWidth - imageWidth;
    const minY = containerHeight - imageHeight;

    if (imageWidth < containerWidth) {
      translateX = (containerWidth - imageWidth) / 2;
    } else {
      translateX = Math.min(0, Math.max(minX, translateX));
    }

    if (imageHeight < containerHeight) {
      translateY = (containerHeight - imageHeight) / 2;
    } else {
      translateY = Math.min(0, Math.max(minY, translateY));
    }
  }

  mapContainer.addEventListener('wheel', (e) => {
	  e.preventDefault();
	  const zoomAmount = 0.1;
	  const delta = e.deltaY < 0 ? 1 : -1;

	  const newScale = scale + delta * zoomAmount;
	  if (newScale < minScale || newScale > maxScale) return;

	  // 🧠 마우스 위치를 기준으로 줌 중심 계산
	  const rect = mapContainer.getBoundingClientRect();
	  const mouseX = e.clientX - rect.left;
	  const mouseY = e.clientY - rect.top;

	  const offsetX = (mouseX - translateX) / scale;
	  const offsetY = (mouseY - translateY) / scale;

	  scale = newScale;

	  translateX = mouseX - offsetX * scale;
	  translateY = mouseY - offsetY * scale;

	  clampTranslate();
	  updateTransform();
	});

  mapContainer.addEventListener('mousedown', (e) => {
    isDragging = true;
    startX = e.clientX;
    startY = e.clientY;
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;
    startX = e.clientX;
    startY = e.clientY;

    translateX += dx;
    translateY += dy;

    clampTranslate();
    updateTransform();
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  window.addEventListener('resize', () => {
    resizeCanvas();
    updateTransform();
  });

  window.addEventListener('load', () => {
    resizeCanvas();
    const containerWidth = mapContainer.offsetWidth;
    const containerHeight = mapContainer.offsetHeight;
    const imageWidth = mapImage.naturalWidth * scale;
    const imageHeight = mapImage.naturalHeight * scale;

    translateX = (containerWidth - imageWidth) / 2;
    translateY = (containerHeight - imageHeight) / 2;

    updateTransform();
  });

  function resizeCanvas() {
    canvas.width = mapImage.naturalWidth;
    canvas.height = mapImage.naturalHeight;
    canvas.style.width = mapImage.naturalWidth + 'px';
    canvas.style.height = mapImage.naturalHeight + 'px';
  }

  //마스킹 영역
  
  function drawMaskArea() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = 'rgba(255, 0, 0, 0.4)';
  ctx.strokeStyle = 'rgba(255, 0, 0, 0.8)';
  ctx.lineWidth = 2.3;

  const scale = 1;
  const offsetX = 70;
  const offsetY = -130;

  const points = [
    [0, 410], [114, 506], [82, 535], [193, 598], [196, 625],
    [299, 659], [371, 704], [573, 705], [579, 741], [670, 766],
    [777, 822], [1028, 804], [1145, 769], [1161, 724], [1320, 639],
    [1323, 600], [1362, 572], [1385, 597], [1450, 527], [1496, 530],
    [1521, 517], [1390, 428], [1473, 379], [1450, 313], [1364, 261],
    [1259, 303], [1177, 279], [1128, 219], [1128, 162], [1191, 143],
    [1039, 66], [983, 27], [888, 27], [791, 0], [699, 6],
    [580, 84], [482, 51], [213, 216], [199, 247], [159, 278],
    [95, 244], [22, 284], [43, 326]
  ];

  const xs = points.map(p => p[0]);
  const ys = points.map(p => p[1]);
  const maskCenterX = (Math.min(...xs) + Math.max(...xs)) / 2;
  const maskCenterY = (Math.min(...ys) + Math.max(...ys)) / 2;

  const canvasCenterX = canvas.width / 2;
  const canvasCenterY = canvas.height / 2;

  // 1️⃣ 바깥 다각형 마스킹
  ctx.beginPath();
  for (let i = 0; i < points.length; i++) {
    const scaledX = (points[i][0] - maskCenterX) * scale + canvasCenterX + offsetX;
    const scaledY = (points[i][1] - maskCenterY) * scale + canvasCenterY + offsetY;

    if (i === 0) ctx.moveTo(scaledX, scaledY);
    else ctx.lineTo(scaledX, scaledY);
  }
  ctx.closePath();
  ctx.fill();
  ctx.stroke();

  // 2️⃣ 이동 불가 타원 (구멍 만들기)
  ctx.save();
  ctx.globalCompositeOperation = 'destination-out'; // 마스크 안에 구멍 만들기

  const ellipseX = canvasCenterX + 45; // 타원 중심 X (조정 가능)
  const ellipseY = canvasCenterY - 220; // 타원 중심 Y (조정 가능)
  const radiusX = 165; // 수평 반지름
  const radiusY = 130;  // 수직 반지름

  ctx.beginPath();
  ctx.ellipse(ellipseX, ellipseY, radiusX, radiusY, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>