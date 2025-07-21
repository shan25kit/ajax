<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="StartMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<!-- Three.js 라이브러리 로드 -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>

<body tabindex="0">

<div class="map-container" id="mapContainer">
  <img id="mapImage" src="/resource/img/background-1.png" alt="스타터맵 이미지" />
  <canvas id="mapCanvas" width="5055" height="3904"></canvas>
  <canvas id="threeCanvas" style="position:absolute; top:0; left:0; z-index:20; pointer-events:none;"></canvas>
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

<script>
  const mapImage = document.getElementById('mapImage');
  const mapContainer = document.getElementById('mapContainer');
  const canvas = document.getElementById('mapCanvas');
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  const threeCanvas = document.getElementById('threeCanvas');

  let scale = 0.5;
  let translateX = 0;
  let translateY = 0;
  const minScale = 0.4;
  const maxScale = 2.5;

  let isDragging = false;
  let startX = 0;
  let startY = 0;
  
  // 포탈 영역
  const portals = [
    { id: 'portal_1', x: 2200, y: 900 },
    { id: 'portal_2', x: 2978, y: 1150 },
    { id: 'portal_3', x: 2795, y: 1350 },
    { id: 'portal_4', x: 1875, y: 1200 },
    { id: 'portal_5', x: 1538, y: 1370 },
    { id: 'object', x: 2260, y: 1550 }
  ];

  // Three.js 관련 변수들
  let renderer, scene, camera, character, mixer, clock;
  let charX = 2200; // 캐릭터 시작 위치 X - 타원 밖으로 이동
  let charY = 1500; // 캐릭터 시작 위치 Y - 타원 밖으로 이동
  
  // 키 입력 상태 추적
  const keys = {
    w: false,
    a: false,
    s: false,
    d: false
  };
  
  // 움직임 설정
  const moveSpeed = 3;
  let isMoving = false;
  let walkAction, idleAction;

  // Three.js 초기화
  function initThreeJS() {
    // 렌더러 설정
    renderer = new THREE.WebGLRenderer({ canvas: threeCanvas, alpha: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x000000, 0); // 투명 배경
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    
    // 씬 생성
    scene = new THREE.Scene();
    
    // 카메라 설정 (45도 쿼터뷰)
    const aspect = window.innerWidth / window.innerHeight;
    const frustumSize = 800;
    camera = new THREE.OrthographicCamera(
      (frustumSize * aspect) / -2, (frustumSize * aspect) / 2,
      frustumSize / 2, frustumSize / -2,
      1, 2000
    );
    
    // 45도 각도로 카메라 위치 설정 (ISO 쿼터뷰)
    const distance = 500;
    camera.position.set(distance, distance, distance);
    camera.lookAt(0, 0, 0);
    
    // 조명 설정 (쿼터뷰에 맞게 개선)
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(100, 200, 100);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    directionalLight.shadow.camera.near = 0.5;
    directionalLight.shadow.camera.far = 1000;
    directionalLight.shadow.camera.left = -500;
    directionalLight.shadow.camera.right = 500;
    directionalLight.shadow.camera.top = 500;
    directionalLight.shadow.camera.bottom = -500;
    scene.add(directionalLight);
    
    // GLTFLoader로 캐릭터 로드
    const loader = new THREE.GLTFLoader();
    loader.load('/resource/model/body.glb', (gltf) => {
      character = gltf.scene;
      character.scale.setScalar(5); // 쿼터뷰에 맞게 크기 조정
      character.position.set(0, 0, 0);
      character.castShadow = true;
      character.receiveShadow = true;
      
      // 캐릭터의 모든 메시에 그림자 설정
      character.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });
      
      scene.add(character);
      
      // 애니메이션 설정
      if (gltf.animations && gltf.animations.length > 0) {
        mixer = new THREE.AnimationMixer(character);
        
        // idle과 walk 애니메이션 찾기
        gltf.animations.forEach((clip) => {
          if (clip.name.toLowerCase().includes('idle')) {
            idleAction = mixer.clipAction(clip);
          } else if (clip.name.toLowerCase().includes('walk')) {
            walkAction = mixer.clipAction(clip);
          }
        });
        
        // 기본적으로 idle 애니메이션 재생
        if (idleAction) {
          idleAction.play();
        }
      }
      
      // 캐릭터 초기 위치 설정
      updateCharacterPosition();
      
      console.log('캐릭터 로드 완료');
    }, undefined, (error) => {
      console.error('캐릭터 로드 실패:', error);
      // 캐릭터 로드 실패시 기본 큐브로 대체
      const geometry = new THREE.BoxGeometry(30, 60, 30);
      const material = new THREE.MeshLambertMaterial({ color: 0xff0000 });
      character = new THREE.Mesh(geometry, material);
      character.position.set(0, 30, 0);
      character.castShadow = true;
      character.receiveShadow = true;
      scene.add(character);
      updateCharacterPosition();
    });
    
    // 시계 초기화
    clock = new THREE.Clock();
    
    // 렌더링 루프 시작
    animate();
  }

  // 마스킹 영역 점들 정의
  function getMaskPoints() {
    const maskScale = 1;
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

    return points.map(point => ({
      x: (point[0] - maskCenterX) * maskScale + canvasCenterX + offsetX,
      y: (point[1] - maskCenterY) * maskScale + canvasCenterY + offsetY
    }));
  }

  // 점이 다각형 내부에 있는지 확인 (Ray casting algorithm)
  function isPointInPolygon(x, y, polygon) {
    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi = polygon[i].x, yi = polygon[i].y;
      const xj = polygon[j].x, yj = polygon[j].y;
      
      if (((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  // 점이 타원 내부에 있는지 확인 (이동 불가 영역)
  function isPointInEllipse(x, y) {
    const canvasCenterX = canvas.width / 2;
    const canvasCenterY = canvas.height / 2;
    const ellipseX = canvasCenterX + 45;
    const ellipseY = canvasCenterY - 220;
    const radiusX = 165;
    const radiusY = 130;
    
    const dx = x - ellipseX;
    const dy = y - ellipseY;
    
    return (dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1;
  }

  // 캐릭터가 이동 가능한 위치인지 확인 (영역 확장 테스트)
  function canMoveToPosition(mapX, mapY) {
    // 일단 간단한 사각형 영역으로 테스트
    const minX = 1500, maxX = 3500;
    const minY = 1300, maxY = 2500;
    
    const inBounds = mapX >= minX && mapX <= maxX && mapY >= minY && mapY <= maxY;
    
    // 타원 체크 (중앙 장애물)
    const normalizedX = mapX / mapImage.naturalWidth;  
    const normalizedY = mapY / mapImage.naturalHeight; 
    const canvasX = normalizedX * canvas.width;
    const canvasY = normalizedY * canvas.height;
    const inEllipse = isPointInEllipse(canvasX, canvasY);
    
    const canMove = inBounds && !inEllipse;
    
    // 디버깅 - 간단한 로그
    if (Math.abs(mapX - charX) < 10 && Math.abs(mapY - charY) < 10) {
      console.log(`간단 체크: (\${mapX.toFixed(0)}, \${mapY.toFixed(0)}) -> 범위내: \${inBounds}, 타원내: \${inEllipse}, 결과: \${canMove}`);
    }
    
    return canMove;
  }

  // 캐릭터 위치 업데이트
  function updateCharacterPosition() {
    if (!character) return;
    
    // 맵 좌표를 화면 좌표로 변환
    const screenX = charX * scale + translateX;
    const screenY = charY * scale + translateY;
    
    // 화면 중앙을 기준으로 Three.js 좌표 계산
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;
    
    // 쿼터뷰 좌표 변환 (사선 움직임 방지)
    const worldX = screenX - centerX;
    const worldZ = screenY - centerY;
    
    character.position.x = worldX;
    character.position.z = worldZ;
    character.position.y = 0; // 바닥에 고정
  }

  // 키 입력 처리
  function handleMovement() {
    if (!character) return;
    
    let deltaX = 0;
    let deltaY = 0;
    let moving = false;
    
    if (keys.w) { deltaY -= moveSpeed; moving = true; }
    if (keys.s) { deltaY += moveSpeed; moving = true; }
    if (keys.a) { deltaX -= moveSpeed; moving = true; }
    if (keys.d) { deltaX += moveSpeed; moving = true; }
    
    // 대각선 이동 시 속도 정규화
    if (deltaX !== 0 && deltaY !== 0) {
      const length = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
      deltaX = (deltaX / length) * moveSpeed;
      deltaY = (deltaY / length) * moveSpeed;
    }
    
    // 새로운 위치 계산
    const newX = charX + deltaX;
    const newY = charY + deltaY;
    
    // 이동 가능한지 확인 (더 관대한 체크로 변경)
    if (deltaX !== 0 || deltaY !== 0) {
      // X축 이동 체크
      if (deltaX !== 0 && canMoveToPosition(charX + deltaX, charY)) {
        charX += deltaX;
      }
      // Y축 이동 체크  
      if (deltaY !== 0 && canMoveToPosition(charX, charY + deltaY)) {
        charY += deltaY;
      }
      
      updateCharacterPosition();
    }
    
    // 애니메이션 전환
    if (moving !== isMoving) {
      isMoving = moving;
      
      if (mixer) {
        if (isMoving && walkAction) {
          if (idleAction) idleAction.fadeOut(0.2);
          walkAction.reset().fadeIn(0.2).play();
        } else if (!isMoving && idleAction) {
          if (walkAction) walkAction.fadeOut(0.2);
          idleAction.reset().fadeIn(0.2).play();
        }
      }
    }
    
    // 캐릭터 방향 설정 (정상적인 방향)
    if (moving && character) {
      // 일반적인 방향 계산 (사선 움직임 보정 제거)
      const angle = Math.atan2(deltaX, -deltaY);
      character.rotation.y = angle;
    }
  }

  // 애니메이션 루프
  function animate() {
    requestAnimationFrame(animate);
    
    handleMovement();
    
    if (mixer) {
      const delta = clock.getDelta();
      mixer.update(delta);
    }
    
    renderer.render(scene, camera);
  }

  // 키보드 이벤트 리스너
  window.addEventListener('keydown', (e) => {
    const key = e.key.toLowerCase();
    if (key in keys) {
      keys[key] = true;
      e.preventDefault();
    }
  });

  window.addEventListener('keyup', (e) => {
    const key = e.key.toLowerCase();
    if (key in keys) {
      keys[key] = false;
      e.preventDefault();
    }
  });

  // 기존 함수들
  function updatePortals() {
    portals.forEach(p => {
      const el = document.getElementById(p.id);
      if (el) {
        const tx = p.x * scale + translateX;
        const ty = p.y * scale + translateY;
        el.style.transform = `translate(\${tx}px, \${ty}px) scale(\${scale})`;
        el.style.transformOrigin = 'top left';
      }
    });
  }

  function updateTransform() {
    const transform = `translate(\${translateX}px, \${translateY}px) scale(\${scale})`;

    mapImage.style.transformOrigin = 'top left';
    canvas.style.transformOrigin = 'top left';

    mapImage.style.transform = transform;
    canvas.style.transform = transform;
    
    drawMaskArea();
    updatePortals();
    updateCharacterPosition();
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

  // 이벤트 리스너들
  mapContainer.addEventListener('wheel', (e) => {
    e.preventDefault();
    const zoomAmount = 0.1;
    const delta = e.deltaY < 0 ? 1 : -1;

    const newScale = scale + delta * zoomAmount;
    if (newScale < minScale || newScale > maxScale) return;

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
    if (renderer) {
      renderer.setSize(window.innerWidth, window.innerHeight);
      
      // 쿼터뷰 카메라 비율 업데이트
      const aspect = window.innerWidth / window.innerHeight;
      const frustumSize = 800;
      camera.left = (frustumSize * aspect) / -2;
      camera.right = (frustumSize * aspect) / 2;
      camera.top = frustumSize / 2;
      camera.bottom = frustumSize / -2;
      camera.updateProjectionMatrix();
    }
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
    
    // Three.js 초기화
    initThreeJS();
  });

  function resizeCanvas() {
    canvas.width = mapImage.naturalWidth;
    canvas.height = mapImage.naturalHeight;
    canvas.style.width = mapImage.naturalWidth + 'px';
    canvas.style.height = mapImage.naturalHeight + 'px';
  }

  // 마스킹 영역
  function drawMaskArea() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // 현재 스케일과 변환을 고려한 마스킹 그리기
    ctx.save();
    
    // 빨간색 영역 = 이동 가능 영역
    ctx.fillStyle = 'rgba(255, 0, 0, 0.4)'; // 빨간색 반투명
    ctx.strokeStyle = 'rgba(255, 0, 0, 0.8)';
    ctx.lineWidth = 2.3;

    const maskScale = 1;
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

    // 이동 가능한 빨간색 영역 그리기
    ctx.beginPath();
    for (let i = 0; i < points.length; i++) {
      const scaledX = (points[i][0] - maskCenterX) * maskScale + canvasCenterX + offsetX;
      const scaledY = (points[i][1] - maskCenterY) * maskScale + canvasCenterY + offsetY;

      if (i === 0) ctx.moveTo(scaledX, scaledY);
      else ctx.lineTo(scaledX, scaledY);
    }
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // 이동 불가 타원 (구멍 - 빨간색이 아닌 영역)
    ctx.save();
    ctx.globalCompositeOperation = 'destination-out';

    const ellipseX = canvasCenterX + 45;
    const ellipseY = canvasCenterY - 220;
    const radiusX = 165;
    const radiusY = 130;

    ctx.beginPath();
    ctx.ellipse(ellipseX, ellipseY, radiusX, radiusY, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    // 실제 이동 가능 영역을 초록색으로 표시 (스케일이 작을 때만)
    if (scale > 0.8) {
      drawActualMovableArea();
    }
    
    ctx.restore();
    
    console.log('마스킹 영역 그리기 완료 - 빨간색 = 이동 가능');
  }

  // 실제 이동 가능 영역 표시 (선택사항)
  function drawActualMovableArea() {
    // 이 함수는 필요에 따라 구현하세요
    // 예: 더 세밀한 이동 가능 영역 표시
  }

</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>