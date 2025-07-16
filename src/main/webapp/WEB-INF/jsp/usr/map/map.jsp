<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="StartMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<style>
body {
  margin: 0;
  overflow: hidden;
}
canvas {
  display: block;
}
</style>

<canvas id="threeCanvas"></canvas>

<script type="module">
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
camera.position.set(0, 0, 1000);

const renderer = new THREE.WebGLRenderer({ canvas: document.getElementById('threeCanvas'), alpha: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000);

const light = new THREE.DirectionalLight(0xffffff, 1);
light.position.set(0, 0, 1000);
scene.add(light);

// 맵 설정
const mapOriginalWidth = 5055;
const mapOriginalHeight = 3904;
let currentScale = 1.3;
let minScale = 1.0;
let visibleWidth, visibleHeight;

let charX = 2527 - mapOriginalWidth / 2;
let charY = mapOriginalHeight / 2 - 1952;

const character = new THREE.Mesh(
  new THREE.BoxGeometry(50, 50, 50),
  new THREE.MeshStandardMaterial({ color: 0x00ff00 })
);
scene.add(character);

const loader = new THREE.TextureLoader();
let mapPlane;
let maskPlane; // ✅ 전역 선언

// 화면 크기 계산
function updateVisibleSize() {
  const fovInRad = camera.fov * (Math.PI / 180);
  visibleHeight = 2 * Math.tan(fovInRad / 2) * camera.position.z;
  visibleWidth = visibleHeight * camera.aspect;
}
function calculateMinScaleToFillScreen() {
  updateVisibleSize();
  const scaleX = visibleWidth / mapOriginalWidth;
  const scaleY = visibleHeight / mapOriginalHeight;
  return Math.max(scaleX, scaleY);
}
updateVisibleSize();

// 맵 배경 로딩
loader.load('/resource/img/background-1.png', (texture) => {
  minScale = calculateMinScaleToFillScreen();
  currentScale = minScale;

  charX = (2527 - mapOriginalWidth / 2) * currentScale;
  charY = (mapOriginalHeight / 2 - 1952) * currentScale;

  mapPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(mapOriginalWidth, mapOriginalHeight),
    new THREE.MeshBasicMaterial({ map: texture })
  );
  mapPlane.scale.set(currentScale, currentScale, 1);
  scene.add(mapPlane);

  updateMapToCharacter();
});

// 마스크용 canvas 로딩 (이동 제한 체크용)
const maskCanvas = document.createElement("canvas");
const ctx = maskCanvas.getContext("2d", { willReadFrequently: true });
let isMaskReady = false;

const maskImg = new Image();
maskImg.crossOrigin = "anonymous";
maskImg.onload = () => {
  console.log("✅ 마스크 로딩 완료");
  console.log(`🎯 마스크 크기: \${maskImg.width} x \${maskImg.height}`);
  console.log(`🎯 맵 크기: \${mapOriginalWidth} x \${mapOriginalHeight}`);

  maskCanvas.width = mapOriginalWidth;
  maskCanvas.height = mapOriginalHeight;
  ctx.drawImage(maskImg, 0, 0, mapOriginalWidth, mapOriginalHeight);
  isMaskReady = true;
};
maskImg.onerror = () => {
  console.error("❌ 마스크 이미지 로딩 실패");
};
maskImg.src = "/resource/img/background-mask.png";

// 마스크 Plane을 Three.js로 시각화
loader.load('/resource/img/background-1.png', (texture) => {
  minScale = calculateMinScaleToFillScreen();
  currentScale = minScale;

  charX = (2527 - mapOriginalWidth / 2) * currentScale;
  charY = (mapOriginalHeight / 2 - 1952) * currentScale;

  mapPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(mapOriginalWidth, mapOriginalHeight),
    new THREE.MeshBasicMaterial({ map: texture })
  );
  mapPlane.scale.set(currentScale, currentScale, 1);
  scene.add(mapPlane);

  // ✅ 이 안에서 maskPlane 생성
  loader.load('/resource/img/background-mask.png', (maskTexture) => {
    maskTexture.magFilter = THREE.NearestFilter;
    maskTexture.minFilter = THREE.NearestMipMapNearestFilter;

    maskPlane = new THREE.Mesh(
      new THREE.PlaneGeometry(mapOriginalWidth, mapOriginalHeight),
      new THREE.MeshBasicMaterial({
        map: maskTexture,
        transparent: true,
        opacity: 0.4
      })
    );
    maskPlane.scale.set(currentScale, currentScale, 1);
    maskPlane.position.set(mapPlane.position.x, mapPlane.position.y, 0.5);
    scene.add(maskPlane);
  });

  updateMapToCharacter();
});

// 이동 가능 체크
function canMoveTo(worldX, worldY) {
  if (!isMaskReady) return true;

  const maskX = Math.floor(worldX / currentScale + mapOriginalWidth / 2);
  const maskY = Math.floor(mapOriginalHeight / 2 - worldY / currentScale);

  if (maskX < 0 || maskY < 0 || maskX >= mapOriginalWidth || maskY >= mapOriginalHeight) {
    console.log(`❌ 범위 밖 (\${maskX}, \${maskY})`);
    return false;
  }

  try {
    const pixel = ctx.getImageData(maskX, maskY, 1, 1).data;
    const [r, g, b, a] = pixel;
    const isWhite = r > 128 && g > 128 && b > 128;
    console.log(`🔍 RGB(\${r}, \${g}, \${b}, \${a}) → \${isWhite ? "✅ 통과" : "❌ 막힘"}`);
    return isWhite;
  } catch (err) {
    console.error("픽셀 읽기 오류:", err);
    return false;
  }
}

// 카메라/맵 위치 동기화
function updateMapToCharacter() {
  updateVisibleSize();

  const mapHalfW = (mapOriginalWidth * currentScale) / 2;
  const mapHalfH = (mapOriginalHeight * currentScale) / 2;
  const viewHalfW = visibleWidth / 2;
  const viewHalfH = visibleHeight / 2;

  let mapX = -charX;
  let mapY = -charY;

  const minMapX = -mapHalfW + viewHalfW;
  const maxMapX = mapHalfW - viewHalfW;
  const minMapY = -mapHalfH + viewHalfH;
  const maxMapY = mapHalfH - viewHalfH;

  mapX = THREE.MathUtils.clamp(mapX, -maxMapX, -minMapX);
  mapY = THREE.MathUtils.clamp(mapY, -maxMapY, -minMapY);

  if (mapPlane) mapPlane.position.set(mapX, mapY, 0);
  if (maskPlane) maskPlane.position.set(mapX, mapY, 0); // ✅ 추가
  character.position.set(charX, charY, 30);
}

// 이동 키
document.addEventListener("keydown", (e) => {
  const speed = 20;
  let dx = 0, dy = 0;

  switch (e.key) {
    case "ArrowUp": dy = speed; break;
    case "ArrowDown": dy = -speed; break;
    case "ArrowLeft": dx = -speed; break;
    case "ArrowRight": dx = speed; break;
    default: return;
  }

  const nextX = charX + dx;
  const nextY = charY + dy;

  if (canMoveTo(nextX, nextY)) {
    charX = nextX;
    charY = nextY;
    updateMapToCharacter();
  } else {
    console.log("🚫 이동 차단됨");
  }
});

// 창 크기 대응
window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  updateVisibleSize();

  minScale = calculateMinScaleToFillScreen();
  if (currentScale < minScale) {
    currentScale = minScale;
    if (mapPlane) mapPlane.scale.set(currentScale, currentScale, 1);
    if (maskPlane) maskPlane.scale.set(currentScale, currentScale, 1); // ✅ 크기 동기화도 추가
  }

  updateMapToCharacter();
});

// 렌더링
function animate() {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
animate();
</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>
