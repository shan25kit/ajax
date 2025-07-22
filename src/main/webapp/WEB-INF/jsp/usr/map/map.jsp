<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<c:set var="pageTitle" value="StartMap" />
<%@ include file="/WEB-INF/jsp/common/header.jsp"%>


<body tabindex="0">

	<div class="map-container" id="mapContainer">
		<img id="mapImage" src="/resource/img/background-1.png" alt="스타터맵 이미지" />
		<canvas id="mapCanvas" width="5055" height="3904"></canvas>
		
		<!-- 캐릭터 컨테이너 (2D 좌표로 이동) -->
		<div class="character-container" id="characterContainer">
			<div class="character-3d" id="character3D"></div>
		</div>
		
	</div>

	<!-- 포탈들은 transform 적용 대상 아님, 별도로 DOM에 위치시킴 -->
	<div id="portalLayer">
		<div id="portal_1" class="portal_1">
			<img class="portal_back" src="/resource/img/portal_back.png" onerror="this.style.display='none'" /> 
			<img class="portal_center" src="/resource/img/portal_cneter.png" onerror="this.style.display='none'" /> 
			<img class="portal_inside" src="/resource/img/portal_inside_center.gif" onerror="this.style.display='none'" />
		</div>

		<div id="portal_2" class="portal_2">
			<img class="portal_back" src="/resource/img/portal_right-back.png" onerror="this.style.display='none'" />
			<img class="portal_center" src="/resource/img/portal_right1.png" onerror="this.style.display='none'" />
			<img class="portal_inside" src="/resource/img/portal_inside_right.gif" onerror="this.style.display='none'" />
		</div>

		<div id="portal_3" class="portal_3">
			<img class="portal_back" src="/resource/img/portal_right-back2.png" onerror="this.style.display='none'" />
			<img class="portal_center" src="/resource/img/portal_right2.png" onerror="this.style.display='none'" />
			<img class="portal_inside" src="/resource/img/portal_inside_right2.gif" onerror="this.style.display='none'" />
		</div>

		<div id="portal_4" class="portal_4">
			<img class="portal_back" src="/resource/img/portal_right-back.png" onerror="this.style.display='none'" />
			<img class="portal_center" src="/resource/img/portal_left1.png" onerror="this.style.display='none'" /> 
			<img class="portal_inside" src="/resource/img/portal_inside_right.gif" onerror="this.style.display='none'" />
		</div>

		<div id="portal_5" class="portal_5">
			<img class="portal_back" src="/resource/img/portal_right-back2.png" onerror="this.style.display='none'" />
			<img class="portal_center" src="/resource/img/portal_left2.png" onerror="this.style.display='none'" /> 
			<img class="portal_inside" src="/resource/img/portal_inside_right2.gif" onerror="this.style.display='none'" />
		</div>

		<div id="object" class="object">
			<img class="fountain" src="/resource/img/fountain.png" onerror="this.style.display='none'" />
		</div>
	</div>

<script>
  let isInitialized = false; // 중복 초기화 방지
  let animationId = null; // 애니메이션 ID 추적

  const mapImage = document.getElementById('mapImage');
  const mapContainer = document.getElementById('mapContainer');
  const canvas = document.getElementById('mapCanvas');
  const ctx = canvas.getContext('2d', { willReadFrequently: true });

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

  // 캐릭터 위치 (2D 좌표)
  let charX = 2400;
  let charY = 1800;
  
  // 키 입력 상태 추적
  const keys = {
    w: false,
    a: false,
    s: false,
    d: false
  };
  
  // 움직임 설정
  const moveSpeed = 10;
  let isMoving = false;

  // Three.js 관련 변수들
  let renderer, scene, camera, character, mixer, clock;
  let walkAction, idleAction;

  // DOM 요소들
  const characterContainer = document.getElementById('characterContainer');
  const characterDot = document.getElementById('characterDot');
  const character3DDiv = document.getElementById('character3D');

  // 최적화 변수들
  let maskNeedsRedraw = true;
  let lastCharX = charX;
  let lastCharY = charY;
  let lastScreenX = null;
  let lastScreenY = null;
  let lastScale = null;
  let lastFrameTime = 0;
  const targetFPS = 60;
  const frameInterval = 1000 / targetFPS;

  // 디바운싱을 위한 타임아웃
  let updateTimeout;

 // Three.js 초기화 (최적화 적용)
function initThreeJS() {
  try {
    if (typeof THREE === 'undefined') {
      console.error('Three.js가 로드되지 않았습니다');
      return;
    }
    
    console.log('Three.js 초기화 시작');
    
    if (renderer) {
      renderer.dispose();
    }

    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000);
    
    // 카메라를 캐릭터 전체가 보이도록 배치
    camera.position.set(0, 80, 120);
    camera.lookAt(0, 20, 0);
    
    // 렌더러 최적화
    renderer = new THREE.WebGLRenderer({ 
      alpha: true, 
      antialias: true, // 성능 향상을 위해 안티앨리어싱 비활성화
      powerPreference: "high-performance"
    });
    renderer.setSize(200, 200);
    renderer.setClearColor(0x000000, 0);
    
    // 그림자 최적화
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.BasicShadowMap; // 성능 향상
    
    character3DDiv.innerHTML = '';
    character3DDiv.appendChild(renderer.domElement);
    
    // 렌더러 캔버스 z-index 설정
    renderer.domElement.style.zIndex = '9999';
    renderer.domElement.style.position = 'relative';
    
    // 조명 최적화
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(10, 50, 20);
    directionalLight.castShadow = true;
    scene.add(directionalLight);
    
    clock = new THREE.Clock();
    
    console.log('Three.js 기본 설정 완료');
    loadCharacterModel();
    
    if (!animationId) {
      animate();
    }
    
    console.log('Three.js 초기화 완료');
  } catch (error) {
    console.error('Three.js 초기화 실패:', error);
  }
}

  // 안전한 GLB 로드
  function loadCharacterModel() {
    // GLTFLoader 로딩 대기
    if (typeof THREE === 'undefined') {
      console.warn('Three.js not loaded yet, retrying...');
      setTimeout(loadCharacterModel, 500);
      return;
    }
    
    if (typeof THREE.GLTFLoader === 'undefined') {
      console.warn('GLTFLoader not available yet, retrying...');
      // 다시 시도하거나 임시 캐릭터 사용
      setTimeout(() => {
        if (typeof THREE.GLTFLoader === 'undefined') {
          console.warn('GLTFLoader still not available, using temp character');
          createTempCharacter();
        } else {
          loadCharacterModel();
        }
      }, 1000);
      return;
    }

    const loader = new THREE.GLTFLoader();
    
    // 타임아웃 설정
    const timeout = setTimeout(() => {
      console.warn('GLB 로드 타임아웃, 임시 캐릭터 사용');
      createTempCharacter();
    }, 5000);

    loader.load('/resource/model/body.glb', 
      (gltf) => {
        clearTimeout(timeout);
        character = gltf.scene;
        character.scale.setScalar(3.5);
        
        character.traverse((child) => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
          }
        });
        
        scene.add(character);
        
        if (gltf.animations && gltf.animations.length > 0) {
          mixer = new THREE.AnimationMixer(character);
          
          gltf.animations.forEach((clip) => {
            if (clip.name.toLowerCase().includes('idle')) {
              idleAction = mixer.clipAction(clip);
            } else if (clip.name.toLowerCase().includes('walk')) {
              walkAction = mixer.clipAction(clip);
            }
          });
          
          if (idleAction) {
            idleAction.play();
          }
        }
        
        console.log('캐릭터 로드 완료');
      },
      (progress) => {
        // 로딩 진행률 (선택사항)
      },
      (error) => {
        clearTimeout(timeout);
        console.warn('GLB 로드 실패, 임시 캐릭터 사용:', error);
        createTempCharacter();
      }
    );
  }

  // 임시 캐릭터 생성
  function createTempCharacter() {
    try {
      const group = new THREE.Group();
      
      const bodyGeometry = new THREE.BoxGeometry(8, 12, 6);
      const bodyMaterial = new THREE.MeshLambertMaterial({ color: 0x4169E1 });
      const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
      body.position.y = 6;
      body.castShadow = true;
      group.add(body);
      
      const headGeometry = new THREE.SphereGeometry(4);
      const headMaterial = new THREE.MeshLambertMaterial({ color: 0xFFDBB3 });
      const head = new THREE.Mesh(headGeometry, headMaterial);
      head.position.y = 16;
      head.castShadow = true;
      group.add(head);
      
      character = group;
      scene.add(character);
      
      console.log('임시 캐릭터 생성 완료');
    } catch (error) {
      console.error('임시 캐릭터 생성 실패:', error);
    }
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

  // 점이 다각형 내부에 있는지 확인
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

  // 점이 타원 내부에 있는지 확인
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

  function canMoveToPosition(mapX, mapY) {
    try {
      const maskPoints = getMaskPoints();
      const inPolygon = isPointInPolygon(mapX, mapY, maskPoints);
      const inEllipse = isPointInEllipse(mapX, mapY);
      return inPolygon && !inEllipse;
    } catch (error) {
      console.error('이동 체크 에러:', error);
      return false;
    }
  }

  // 캐릭터 위치 업데이트 (최적화 적용)
  function updateCharacterPosition() {
    try {
      const screenX = charX * scale + translateX;
      const screenY = charY * scale + translateY;
      
      // 위치나 스케일이 변경되었을 때만 DOM 업데이트
      if (lastScreenX !== screenX || lastScreenY !== screenY || lastScale !== scale) {
        lastScreenX = screenX;
        lastScreenY = screenY;
        lastScale = scale;
        
        characterContainer.style.position = 'absolute';
        characterContainer.style.left = screenX - 105 + 'px';
        characterContainer.style.top = screenY - 180 + 'px';
        characterContainer.style.transform = `scale(\${scale})`;
        characterContainer.style.transformOrigin = 'center bottom';
        characterContainer.style.zIndex = '9999';
        characterContainer.style.pointerEvents = 'none';
      }
      
      drawMaskArea();
    } catch (error) {
      console.error('캐릭터 위치 업데이트 에러:', error);
    }
  }
  
  // 화면 중앙의 맵 좌표 계산
  function getScreenCenterMapCoords() {
    const screenCenterX = window.innerWidth / 2;
    const screenCenterY = window.innerHeight / 2;
    
    // 화면 중앙을 맵 좌표로 변환
    const mapX = (screenCenterX - translateX) / scale;
    const mapY = (screenCenterY - translateY) / scale;
    
    return { x: mapX, y: mapY };
  }

  // 키 입력 처리 (최적화 적용)
  function handleMovement() {
    if (!character) return;
    
    let deltaX = 0;
    let deltaY = 0;
    let moving = false;
    
    if (keys.w) { deltaY -= moveSpeed; moving = true; }
    if (keys.s) { deltaY += moveSpeed; moving = true; }
    if (keys.a) { deltaX -= moveSpeed; moving = true; }
    if (keys.d) { deltaX += moveSpeed; moving = true; }
    
    // 움직임이 없으면 빠르게 리턴
    if (!moving) {
      if (isMoving && idleAction && mixer) {
        isMoving = false;
        walkAction?.fadeOut(0.2);
        idleAction.reset().fadeIn(0.2).play();
      }
      return;
    }

    // 이동 가능 여부 체크 (마스킹 영역 내에서만 이동)
    const nextX = charX + deltaX;
    const nextY = charY + deltaY;
    let actuallyMoved = false;

    // X축 이동 체크
    if (canMoveToPosition(nextX, charY)) {
      charX = nextX;
      actuallyMoved = true;
    }
    
    // Y축 이동 체크
    if (canMoveToPosition(charX, nextY)) {
      charY = nextY;
      actuallyMoved = true;
    }

    // 실제로 이동했을 때만 처리
    if (actuallyMoved) {
      if (deltaX !== 0 || deltaY !== 0) {
        const angle = Math.atan2(deltaX, deltaY);
        character.rotation.y = angle;
      }
      
      // 마스킹 다시 그리기 플래그 설정
      maskNeedsRedraw = true;
      
      // 캐릭터가 화면 중앙에 오도록 맵을 조정 (카메라 팔로우)
      const screenCenterX = window.innerWidth / 2;
      const screenCenterY = window.innerHeight / 2;
      
      // 캐릭터가 화면 중앙에 오도록 translate 조정
      translateX = screenCenterX - charX * scale;
      translateY = screenCenterY - charY * scale;
      
      clampTranslate();
      debouncedUpdate();
      
      console.log(`캐릭터 이동: X=\${charX.toFixed(0)}, Y=\${charY.toFixed(0)}`);
    }

    // 애니메이션 전환
    if (mixer && !isMoving && walkAction) {
      idleAction?.fadeOut(0.2);
      walkAction.reset().fadeIn(0.2).play();
      isMoving = true;
    }
  }

  // 디바운싱 적용된 업데이트
  function debouncedUpdate() {
    clearTimeout(updateTimeout);
    updateTimeout = setTimeout(() => {
      updateTransform();
    }, 16); // 60fps에 맞춤
  }

  // 안전한 애니메이션 루프 (최적화 적용)
  function animate(currentTime = 0) {
    try {
      animationId = requestAnimationFrame(animate);
      
      // FPS 제한
      if (currentTime - lastFrameTime < frameInterval) {
        return;
      }
      lastFrameTime = currentTime;
      
      handleMovement();
      
      if (mixer) {
        const delta = clock.getDelta();
        mixer.update(delta);
      }
      
      // Three.js 렌더링이 필요할 때만 렌더링
      if (renderer && scene && camera) {
        renderer.render(scene, camera);
      }
    } catch (error) {
      console.error('애니메이션 에러:', error);
      // 에러 발생시 애니메이션 중지
      if (animationId) {
        cancelAnimationFrame(animationId);
        animationId = null;
      }
    }
  }

  // 이벤트 리스너들 (최적화 적용)
  window.addEventListener('keydown', (e) => {
    const key = e.key.toLowerCase();
    if (key in keys && !keys[key]) { // 연속 입력 방지
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

  // 포탈 위치 업데이트
  function updatePortals() {
    try {
      portals.forEach(p => {
        const el = document.getElementById(p.id);
        if (el) {
          const tx = p.x * scale + translateX;
          const ty = p.y * scale + translateY;
          el.style.transform = `translate(\${tx}px, \${ty}px) scale(\${scale})`;
          el.style.transformOrigin = 'top left';
        }
      });
    } catch (error) {
      console.error('포탈 업데이트 에러:', error);
    }
  }

  function updateTransform() {
    try {
      const transform = `translate(\${translateX}px, \${translateY}px) scale(\${scale})`;

      mapImage.style.transformOrigin = 'top left';
      canvas.style.transformOrigin = 'top left';
      mapImage.style.transform = transform;
      canvas.style.transform = transform;
      
      updatePortals();
      updateCharacterPosition();
    } catch (error) {
      console.error('Transform 업데이트 에러:', error);
    }
  }

  function clampTranslate() {
    try {
      const containerWidth = mapContainer.offsetWidth;
      const containerHeight = mapContainer.offsetHeight;
      const imageWidth = (mapImage.naturalWidth || 5055) * scale;
      const imageHeight = (mapImage.naturalHeight || 3904) * scale;

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
    } catch (error) {
      console.error('Clamp 에러:', error);
    }
  }

  // 이벤트 리스너들 (디바운싱 적용)
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
    debouncedUpdate(); // 디바운싱 적용
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
    debouncedUpdate(); // 디바운싱 적용
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  window.addEventListener('resize', () => {
    resizeCanvas();
    debouncedUpdate(); // 디바운싱 적용
  });

  // 안전한 초기화
  function initializeMap() {
    if (isInitialized) {
      console.warn('이미 초기화됨');
      return;
    }
    
    try {
      isInitialized = true;
      
      resizeCanvas();
      const containerWidth = mapContainer.offsetWidth;
      const containerHeight = mapContainer.offsetHeight;
      const imageWidth = (mapImage.naturalWidth || 5055) * scale;
      const imageHeight = (mapImage.naturalHeight || 3904) * scale;

      translateX = (containerWidth - imageWidth) / 2;
      translateY = (containerHeight - imageHeight) / 2;

      updateTransform();
      initThreeJS();
      
      setTimeout(() => {
        updateCharacterPosition();
        console.log('맵 초기화 완료');
      }, 100);
    } catch (error) {
      console.error('맵 초기화 에러:', error);
      isInitialized = false;
    }
  }

  function resizeCanvas() {
    try {
      const imageWidth = mapImage.naturalWidth || 5055;
      const imageHeight = mapImage.naturalHeight || 3904;
      
      canvas.width = imageWidth;
      canvas.height = imageHeight;
      canvas.style.width = imageWidth + 'px';
      canvas.style.height = imageHeight + 'px';
    } catch (error) {
      console.error('Canvas 리사이즈 에러:', error);
    }
  }

  // 마스킹 영역 그리기 (최적화 적용)
  function drawMaskArea() {
    try {
      // 캐릭터 위치가 변경되었을 때만 다시 그리기
      if (!maskNeedsRedraw && lastCharX === charX && lastCharY === charY) {
        return;
      }
      
      lastCharX = charX;
      lastCharY = charY;
      maskNeedsRedraw = false;
      
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.save();
      
      ctx.fillStyle = 'rgba(255, 0, 0, 0.4)';
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

      ctx.save();
      ctx.fillStyle = 'rgba(255, 255, 0, 0.9)';
      ctx.strokeStyle = 'rgba(255, 255, 0, 1.0)';
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(charX, charY, 20, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      
      ctx.fillStyle = 'white';
      ctx.strokeStyle = 'black';
      ctx.lineWidth = 2;
      ctx.font = 'bold 16px Arial';
      const text = `캐릭터: (\${charX.toFixed(0)}, \${charY.toFixed(0)})`;
      ctx.strokeText(text, charX + 25, charY - 25);
      ctx.fillText(text, charX + 25, charY - 25);
      ctx.restore();
      
      ctx.restore();
    } catch (error) {
      console.error('마스킹 그리기 에러:', error);
    }
  }

  // 페이지 로드시 안전한 초기화
  window.addEventListener('load', () => {
    console.log('페이지 로드 시작');
    
    // 이미지 로드 확인 및 초기화
    if (mapImage.complete && mapImage.naturalWidth > 0) {
      console.log('이미지 이미 로드됨');
      initializeMap();
    } else {
      console.log('이미지 로드 대기 중...');
      
      // 이미지 로드 완료 이벤트
      mapImage.addEventListener('load', () => {
        console.log('이미지 로드 완료');
        initializeMap();
      }, { once: true }); // once: true로 한 번만 실행되도록
      
      // 이미지 로드 실패 이벤트
      mapImage.addEventListener('error', (e) => {
        console.error('이미지 로드 실패:', e);
        // 기본값으로 강제 초기화
        setTimeout(() => {
          console.log('기본값으로 초기화 시도');
          initializeMap();
        }, 1000);
      }, { once: true });
      
      // 타임아웃 안전장치 (5초)
      setTimeout(() => {
        if (!isInitialized) {
          console.warn('이미지 로드 타임아웃, 강제 초기화');
          initializeMap();
        }
      }, 5000);
    }
  });

  // 페이지 언로드시 정리
  window.addEventListener('beforeunload', () => {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = null;
    }
    if (renderer) {
      renderer.dispose();
    }
  });

</script>

<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>