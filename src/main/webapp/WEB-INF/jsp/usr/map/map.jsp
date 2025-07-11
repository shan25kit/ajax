<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="StartMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>



<div class="map-container" id="mapContainer">

	<div class="map-inner" id="mapInner">
		<img id="zoomMap" src="/resource/img/background-1.png" alt="map" />

		<div class="map_field">

			<div class="portal_1">
				<img src="/resource/img/portal_cneter.png" alt="중앙포탈" />
				<img src="/resource/img/portal_inside.gif" alt="포탈" />
			</div>

			<div class="object1">
				<img src="/resource/img/fountain.png" alt="분수대" />
			</div>


		</div>
		<div class="clouds">
			<img class="first_cloud" src="/resource/img/cloud1.png" alt="구름1" />
			<img class="second_cloud" src="/resource/img/cloud2.png" alt="구름2" />
			<img class="third_cloud" src="/resource/img/cloud3.png" alt="구름3" />
		</div>
	</div>

</div>




<script>
const container = document.getElementById('mapContainer');
const mapInner = document.getElementById('mapInner');

let scale = 0.5;
let posX = -200;
let posY = -150;
const minScale = 0.5;
const maxScale = 2.0;
const step = 0.1;

let isDragging = false;
let startX = 0;
let startY = 0;

const imageWidth = 4000;  // 실제 이미지 너비
const imageHeight = 2754; // 실제 이미지 높이

function applyTransform() {
  const containerWidth = container.clientWidth;
  const containerHeight = container.clientHeight;
  const scaledWidth = imageWidth * scale;
  const scaledHeight = imageHeight * scale;

  // ❗ 드래그 한계 계산
  const maxPosX = 0;
  const minPosX = containerWidth - scaledWidth;
  const maxPosY = 0;
  const minPosY = containerHeight - scaledHeight;

  // ❗ 범위 제한
  posX = Math.min(maxPosX, Math.max(minPosX, posX));
  posY = Math.min(maxPosY, Math.max(minPosY, posY));

  mapInner.style.transform = `translate(\${posX}px, \${posY}px) scale(\${scale})`;
}

// 줌
container.addEventListener('wheel', function (e) {
  e.preventDefault();

  const rect = container.getBoundingClientRect();
  const mouseX = e.clientX - rect.left;
  const mouseY = e.clientY - rect.top;

  const prevScale = scale;
  scale = e.deltaY < 0
    ? Math.min(maxScale, scale + step)
    : Math.max(minScale, scale - step);

  const scaleChange = scale / prevScale;
  posX = mouseX - (mouseX - posX) * scaleChange;
  posY = mouseY - (mouseY - posY) * scaleChange;

  applyTransform();
}, { passive: false });

// 드래그
container.addEventListener('pointerdown', (e) => {
  isDragging = true;
  startX = e.clientX;
  startY = e.clientY;
  container.setPointerCapture(e.pointerId);
  container.style.cursor = 'grabbing';
});

container.addEventListener('pointermove', (e) => {
  if (!isDragging) return;
  const dx = e.clientX - startX;
  const dy = e.clientY - startY;
  startX = e.clientX;
  startY = e.clientY;
  posX += dx;
  posY += dy;
  applyTransform();
});

container.addEventListener('pointerup', (e) => {
  isDragging = false;
  container.releasePointerCapture(e.pointerId);
  container.style.cursor = 'grab';
});

applyTransform(); // 최초 적용



//cloud 이동

$(document).ready(function () {
  function animateCloud($cloud, speed, delay, verticalShift = 20) {
    const screenWidth = $(window).width();
    const cloudWidth = $cloud.width();
    const initialTop = parseInt($cloud.css('top')) || 0;

    const farRight = screenWidth + cloudWidth + 1000;

    // ⭐ top 위치 살짝 위아래 랜덤
    function getRandomTop() {
      const offset = Math.floor(Math.random() * verticalShift * 2) - verticalShift; // -20 ~ +20
      return initialTop + offset;
    }

    // ⭐ 처음 이동
    function startFromInitial() {
      $cloud.animate(
        {
          left: farRight + 'px',
          top: getRandomTop() + 'px'
        },
        speed,
        'linear',
        moveLoop
      );
    }

    // ⭐ 이후 반복
    function moveLoop() {
      $cloud.css({
        left: -cloudWidth + 'px'
      }).animate(
        {
          left: farRight + 'px',
          top: getRandomTop() + 'px'
        },
        speed,
        'linear',
        moveLoop
      );
    }

    setTimeout(startFromInitial, delay);
  }

  // ⚠️ 반드시 구름 클래스에 position:absolute 있어야 top이 적용됨!
  // 예시: .first_cloud, .second_cloud, .third_cloud { position: absolute; }

  animateCloud($('.first_cloud'), 70000, 0);
  animateCloud($('.second_cloud'), 50000, 0);
  animateCloud($('.third_cloud'), 70000, 0);
});


</script>


<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>