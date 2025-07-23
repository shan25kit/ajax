export class MapModule {
	constructor(gameClient) {
		this.gameClient = gameClient;
		this.isInitialized = false;

		// ===== 맵 렌더링 관련 =====
		this.container = null;

		this.scale = 0.5;
		this.posX = 0;
		this.posY = 0;
		this.isDragging = false;
		this.startX = 0;
		this.startY = 0;
		this.mapDragEnabled = true;

		// ===== 포털 관련 =====
		this.portalCollisionAreas = [];

		// ===== 맵 전환 관련 =====
		this.isTransitioning = false;
		this.transitionOverlay = null;

		// ===== 씬 그룹 =====
		this.mapGroup = null;

		// ===== 마스킹 영역 관련 =====
		this.canvas = null;
		this.ctx = null;
		this.maskingPolygon = null;
		this.restrictedEllipse = null;
		this.initializeMaskingAreas();

		// ===== 캐릭터 DOM관련 =====
		this.characterContainer = null;
		this.lastCharacterScreenX = null;
		this.lastCharacterScreenY = null;
		this.lastCharacterScale = null;

		console.log('🗺️ MapModule 생성됨');
	}
	// ===== 마스킹 영역 초기화 =====
	initializeMaskingAreas() {
		// 이동 불가 다각형 영역 (기존 JSP의 points 배열)
		this.maskingPolygon = [
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

		// 이동 불가 타원 영역 (구멍 - 이동 가능 영역)
		this.restrictedEllipse = {
			centerX: 45,    // 캔버스 중심에서의 오프셋
			centerY: -220,
			radiusX: 165,
			radiusY: 130
		};

		console.log('🎯 마스킹 영역 설정 완료');
	}
	// ===== 초기화 =====
	async initialize() {
		try {
			console.log('🗺️ MapModule 초기화 시작');

			// 씬 그룹 생성 (GameClient의 ThreeJSCore를 통해)
			this.mapGroup = this.gameClient.createSceneGroup('map');
			if (!this.mapGroup) {
				throw new Error('맵 씬 그룹 생성 실패');
			}

			// 맵 컨트롤 초기화
			this.initMapControls();

			// 마스킹 캔버스 초기화
			this.initMaskingCanvas();

			// DOM 포털 초기화
			this.initDOMPortals();

			// 초기 변환 적용
			this.applyTransform();

			this.isInitialized = true;
			console.log('✅ MapModule 초기화 완료');

		} catch (error) {
			console.error('❌ MapModule 초기화 실패:', error);
			throw error;
		}
	}

	// ===== 맵 컨트롤 초기화 =====
	initMapControls() {
		this.container = document.getElementById('mapContainer');
		this.mapImage = document.getElementById('mapImage');
		this.mapCanvas = document.getElementById('mapCanvas');
		this.characterContainer = document.getElementById('characterContainer');
		/*	this.clouds = document.querySelector('.clouds'); */

		if (!this.container) {
			console.warn('⚠️ 맵 컨테이너 요소를 찾을 수 없습니다.');
			return;
		}

		// 이벤트 리스너 등록 (bind를 사용해 this 컨텍스트 유지)
		this.container.addEventListener('wheel', this.handleWheel.bind(this), { passive: false });
		this.container.addEventListener('pointerdown', this.handlePointerDown.bind(this));
		this.container.addEventListener('pointermove', this.handlePointerMove.bind(this));
		this.container.addEventListener('pointerup', this.handlePointerUp.bind(this));
		
		window.addEventListener('resize', this.handleResize.bind(this));
		// 오프셋 동적 처리
		const containerWidth = this.container?.clientWidth || window.innerWidth;
		const containerHeight = this.container?.clientHeight || window.innerHeight;
		const mapConfig = this.gameClient.getMapConfig();

		const scaledWidth = mapConfig.IMAGE_WIDTH * this.scale;
		const scaledHeight = mapConfig.IMAGE_HEIGHT * this.scale;

		// 🔥 JSP와 동일한 로직 적용
		this.posX = (containerWidth - scaledWidth) / 2;
		this.posY = (containerHeight - scaledHeight) / 2;

		console.log(`🗺️ 초기 맵 위치 설정: X=${this.posX}, Y=${this.posY}`);
		console.log('🎮 맵 컨트롤 초기화 완료');
	}
	// ===== 마스킹 캔버스 초기화 =====
	initMaskingCanvas() {
		this.canvas = document.getElementById('mapCanvas');
		if (!this.canvas) {
			console.warn('⚠️ 마스킹 캔버스를 찾을 수 없습니다.');
			return;
		}

		this.ctx = this.canvas.getContext('2d');

		// 캔버스 크기 설정
		const mapConfig = this.gameClient.getMapConfig();
		this.canvas.width = mapConfig.IMAGE_WIDTH;
		this.canvas.height = mapConfig.IMAGE_HEIGHT;
		this.canvas.style.width = mapConfig.IMAGE_WIDTH + 'px';
		this.canvas.style.height = mapConfig.IMAGE_HEIGHT + 'px';

		// 초기 마스크 그리기
		this.drawMaskArea();

		console.log('🎨 마스킹 캔버스 초기화 완료');
	}

	// ===== 마스킹 영역 그리기 =====
	drawMaskArea() {
		if (!this.ctx || !this.canvas) return;

		this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

		this.ctx.fillStyle = 'rgba(255, 0, 0, 0.4)';
		this.ctx.strokeStyle = 'rgba(255, 0, 0, 0.8)';
		this.ctx.lineWidth = 2.3;

		const scale = 1;
		const offsetX = 70;
		const offsetY = -130;

		const points = this.maskingPolygon;
		const xs = points.map(p => p[0]);
		const ys = points.map(p => p[1]);
		const maskCenterX = (Math.min(...xs) + Math.max(...xs)) / 2;
		const maskCenterY = (Math.min(...ys) + Math.max(...ys)) / 2;

		const canvasCenterX = this.canvas.width / 2;
		const canvasCenterY = this.canvas.height / 2;

		// 1️⃣ 바깥 다각형 마스킹 (이동 불가 영역)
		this.ctx.beginPath();
		for (let i = 0; i < points.length; i++) {
			const scaledX = (points[i][0] - maskCenterX) * scale + canvasCenterX + offsetX;
			const scaledY = (points[i][1] - maskCenterY) * scale + canvasCenterY + offsetY;

			if (i === 0) this.ctx.moveTo(scaledX, scaledY);
			else this.ctx.lineTo(scaledX, scaledY);
		}
		this.ctx.closePath();
		this.ctx.fill();
		this.ctx.stroke();

		// 2️⃣ 이동 가능 타원 (구멍 만들기)
		this.ctx.save();
		this.ctx.globalCompositeOperation = 'destination-out'; // 마스크 안에 구멍 만들기

		const ellipseX = canvasCenterX + this.restrictedEllipse.centerX;
		const ellipseY = canvasCenterY + this.restrictedEllipse.centerY;
		const radiusX = this.restrictedEllipse.radiusX;
		const radiusY = this.restrictedEllipse.radiusY;

		this.ctx.beginPath();
		this.ctx.ellipse(ellipseX, ellipseY, radiusX, radiusY, 0, 0, Math.PI * 2);
		this.ctx.fill();
		this.ctx.restore();
	}

	// ===== 이동 가능 여부 검사 =====
	isMovementAllowed(position3D) {
		if (!position3D) return true;

		// 3D 좌표를 2D 이미지 좌표로 변환
		const imageCoord = this.worldToImageCoordinates(position3D.x, position3D.z);

		// 1. 다각형 내부에 있는지 검사 (이동 불가 영역)
		if (this.isPointInPolygon(imageCoord, this.maskingPolygon)) {
			// 2. 타원 내부에 있는지 검사 (이동 가능 구멍)
			if (this.isPointInEllipse(imageCoord, this.restrictedEllipse)) {
				return true; // 타원 내부는 이동 가능
			}
			return false; // 다각형 내부이지만 타원 밖은 이동 불가
		}

		return true; // 다각형 밖은 이동 가능
	}

	// ===== 점이 다각형 내부에 있는지 검사 (Ray casting algorithm) =====
	isPointInPolygon(point, polygon) {
		const mapConfig = this.gameClient.getMapConfig();

		// 다각형 좌표를 실제 캔버스 좌표로 변환
		const scale = 1;
		const offsetX = 70;
		const offsetY = -130;

		const xs = polygon.map(p => p[0]);
		const ys = polygon.map(p => p[1]);
		const maskCenterX = (Math.min(...xs) + Math.max(...xs)) / 2;
		const maskCenterY = (Math.min(...ys) + Math.max(...ys)) / 2;

		const canvasCenterX = mapConfig.IMAGE_WIDTH / 2;
		const canvasCenterY = mapConfig.IMAGE_HEIGHT / 2;

		const transformedPolygon = polygon.map(p => [
			(p[0] - maskCenterX) * scale + canvasCenterX + offsetX,
			(p[1] - maskCenterY) * scale + canvasCenterY + offsetY
		]);

		let inside = false;
		const x = point.x;
		const y = point.y;

		for (let i = 0, j = transformedPolygon.length - 1; i < transformedPolygon.length; j = i++) {
			const xi = transformedPolygon[i][0];
			const yi = transformedPolygon[i][1];
			const xj = transformedPolygon[j][0];
			const yj = transformedPolygon[j][1];

			if (((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
				inside = !inside;
			}
		}

		return inside;
	}

	// ===== 점이 타원 내부에 있는지 검사 =====
	isPointInEllipse(point, ellipse) {
		const mapConfig = this.gameClient.getMapConfig();
		const canvasCenterX = mapConfig.IMAGE_WIDTH / 2;
		const canvasCenterY = mapConfig.IMAGE_HEIGHT / 2;

		const ellipseX = canvasCenterX + ellipse.centerX;
		const ellipseY = canvasCenterY + ellipse.centerY;

		const dx = point.x - ellipseX;
		const dy = point.y - ellipseY;

		return (dx * dx) / (ellipse.radiusX * ellipse.radiusX) +
			(dy * dy) / (ellipse.radiusY * ellipse.radiusY) <= 1;
	}


	// ===== DOM 포털 초기화 =====
	initDOMPortals() {
		const portalPositions = this.gameClient.getPortalPositions();

		portalPositions.forEach((itemData) => {
			const element = document.getElementById(itemData.id);

			if (element) {
				// 충돌 영역 정보 저장
				this.portalCollisionAreas.push({
					id: itemData.id,
					x: itemData.x,
					y: itemData.y,
					targetMap: itemData.targetMap || null,  // 분수대는 targetMap이 null
					collisionRadius: itemData.id === 'object' ? 50 : 100,
					element: element,
					type: itemData.id === 'object' ? 'object' : 'portal'
				});

				console.log(`🌀 ${itemData.id === 'object' ? '오브젝트' : '포털'} 등록: ${itemData.id} (${itemData.x}, ${itemData.y})`);
			} else {
				console.warn(`⚠️ 요소를 찾을 수 없음: ${itemData.id}`);
			}
		});

		console.log(`✅ DOM 포털 초기화 완료: ${this.portalCollisionAreas.length}개`);
	}

	// ===== 휠 이벤트 처리 (줌) =====
	handleWheel(e) {
		if (!this.mapDragEnabled) return;
		e.preventDefault();

		const rect = this.container.getBoundingClientRect();
		const mouseX = e.clientX - rect.left;
		const mouseY = e.clientY - rect.top;

		const mapConfig = this.gameClient.getMapConfig();
		const prevScale = this.scale;

		this.scale = e.deltaY < 0
			? Math.min(mapConfig.MAX_SCALE, this.scale + mapConfig.ZOOM_STEP)
			: Math.max(mapConfig.MIN_SCALE, this.scale - mapConfig.ZOOM_STEP);

		const scaleChange = this.scale / prevScale;
		this.posX = mouseX - (mouseX - this.posX) * scaleChange;
		this.posY = mouseY - (mouseY - this.posY) * scaleChange;

		this.applyTransform();
	}

	// ===== 포인터 다운 이벤트 (드래그 시작) =====
	handlePointerDown(e) {
		if (!this.mapDragEnabled || e.target.closest('.clean-chat-container')) return;

		this.isDragging = true;
		this.startX = e.clientX;
		this.startY = e.clientY;
		this.container.setPointerCapture(e.pointerId);
		this.container.style.cursor = 'grabbing';
	}

	// ===== 포인터 무브 이벤트 (드래그 중) =====
	handlePointerMove(e) {
		if (!this.isDragging || !this.mapDragEnabled) return;

		const dx = e.clientX - this.startX;
		const dy = e.clientY - this.startY;
		this.startX = e.clientX;
		this.startY = e.clientY;
		this.posX += dx;
		this.posY += dy;
		this.applyTransform();
	}

	// ===== 포인터 업 이벤트 (드래그 종료) =====
	handlePointerUp(e) {
		this.isDragging = false;
		this.container.releasePointerCapture(e.pointerId);
		this.container.style.cursor = 'grab';
	}

	handleResize() {
		// 화면 크기 변경 시 맵 위치 재계산
		const containerWidth = this.container?.clientWidth || window.innerWidth;
		const containerHeight = this.container?.clientHeight || window.innerHeight;
		const mapConfig = this.gameClient.getMapConfig();

		const scaledWidth = mapConfig.IMAGE_WIDTH * this.scale;
		const scaledHeight = mapConfig.IMAGE_HEIGHT * this.scale;

		this.posX = (containerWidth - scaledWidth) / 2;
		this.posY = (containerHeight - scaledHeight) / 2;

		this.applyTransform();
	}
	// ===== 변환 적용 =====
	applyTransform() {
		if (!this.container) return;

		const mapConfig = this.gameClient.getMapConfig();
		const containerWidth = this.container.clientWidth;
		const containerHeight = this.container.clientHeight;
		const scaledWidth = mapConfig.IMAGE_WIDTH * this.scale;
		const scaledHeight = mapConfig.IMAGE_HEIGHT * this.scale;

		// 드래그 한계 계산
		const maxPosX = 0;
		const minPosX = containerWidth - scaledWidth;
		const maxPosY = 0;
		const minPosY = containerHeight - scaledHeight;

		// 범위 제한
		this.posX = Math.min(maxPosX, Math.max(minPosX, this.posX));
		this.posY = Math.min(maxPosY, Math.max(minPosY, this.posY));
		// ✅ 개별 요소들에 CSS 변환 적용
		const transform = `translate(${this.posX}px, ${this.posY}px) scale(${this.scale})`;

		if (this.mapImage) this.mapImage.style.transform = transform;
		if (this.mapCanvas) this.mapCanvas.style.transform = transform;
		/*	if (clouds) clouds.style.transform = transform;*/


		// 마스킹 영역 다시 그리기
		this.drawMaskArea();

		// 포털 위치 업데이트
		this.updatePortals();

		// 캐릭터 위치 업데이트
		this.updateCharacterDOM();

		// Three.js 씬 동기화
		this.updateSceneTransform();
	}
	// ===== 포털 위치 업데이트 =====
	updatePortals() {
		this.portalCollisionAreas.forEach(portal => {
			if (portal.element) {
				const tx = portal.x * this.scale + this.posX;
				const ty = portal.y * this.scale + this.posY;
				portal.element.style.transform = `translate(${tx}px, ${ty}px) scale(${this.scale})`;
				portal.element.style.transformOrigin = 'top left';
			}
		});
	}


	// ===== Three.js 씬 변환 동기화 =====
	updateSceneTransform() {
		const mapConfig = this.gameClient.getMapConfig();
		const camera = this.gameClient.getCamera();

		if (!camera) return;

		const screenCenterX = window.innerWidth / 2;
		const screenCenterY = window.innerHeight / 2;

		const imageX = (screenCenterX - this.posX) / this.scale;
		const imageY = (screenCenterY - this.posY) / this.scale;

		const worldScale = 100 / mapConfig.IMAGE_WIDTH;
		const worldX = (imageX - mapConfig.IMAGE_WIDTH / 2) * worldScale;
		const worldZ = (imageY - mapConfig.IMAGE_HEIGHT / 2) * worldScale;

		// 캐릭터 이동 중이 아닐 때만 카메라 이동
		const characterMovementModule = this.gameClient.getCharacterMovementModule();
		if (!characterMovementModule?.isCharacterMoving) {
			camera.position.set(worldX, 30, worldZ + 10);
			camera.lookAt(worldX, 0, worldZ);
		}
	}
	updateCharacterDOM() {
		try {
			if (!this.characterContainer) {
				console.warn('⚠️ characterContainer를 찾을 수 없습니다.');
				return;
			}

			const characterRenderModule = this.gameClient.getCharacterRenderModule();
			const myCharacter = characterRenderModule?.getMyCharacter();

			if (!myCharacter) {
				// 캐릭터가 아직 로드되지 않았으면 숨김
				characterContainer.style.display = 'none';
				return;
			}

			// 캐릭터가 있으면 표시
			characterContainer.style.display = 'block';

			// 🔥 3D 캐릭터 위치를 2D 이미지 좌표로 변환
			const imageCoord = this.worldToImageCoordinates(
				myCharacter.position.x,
				myCharacter.position.z
			);

			// 🔥 맵 변환을 적용한 화면 좌표 계산 
			const screenX = imageCoord.x * this.scale + this.posX;
			const screenY = imageCoord.y * this.scale + this.posY;

			// 🔥 성능 최적화: 위치가 실제로 변경되었을 때만 DOM 업데이트
			if (this.lastCharacterScreenX !== screenX ||
				this.lastCharacterScreenY !== screenY ||
				this.lastCharacterScale !== this.scale) {

				this.lastCharacterScreenX = screenX;
				this.lastCharacterScreenY = screenY;
				this.lastCharacterScale = this.scale;

				// 🔥 JSP와 동일한 위치 계산 (중앙/하단 정렬)
				characterContainer.style.position = 'absolute';
				characterContainer.style.left = (screenX - 100) + 'px';  // 중앙 정렬 보정
				characterContainer.style.top = (screenY - 180) + 'px';   // 하단 정렬 보정
				characterContainer.style.transform = `scale(${this.scale})`;
				characterContainer.style.transformOrigin = 'center bottom';
				characterContainer.style.zIndex = '9999';
				characterContainer.style.pointerEvents = 'none';

				// 🔥 디버그 로그 (필요시)
				// console.log(`👤 캐릭터 DOM 위치: screen(${screenX.toFixed(1)}, ${screenY.toFixed(1)}) scale(${this.scale})`);
			}

		} catch (error) {
			console.error('❌ 캐릭터 DOM 위치 업데이트 에러:', error);
		}
	}
	// ===== 포털 충돌 검사 (3D 캐릭터 vs 2D 포털) =====
	checkPortalCollision(characterPosition) {
		if (!characterPosition || this.portalCollisionAreas.length === 0) return null;

		// 3D 캐릭터 위치를 2D 맵 좌표로 변환
		const character2DPos = this.worldToImageCoordinates(
			characterPosition.x,
			characterPosition.z
		);

		// 각 포털과의 거리 계산
		for (const portal of this.portalCollisionAreas) {
			const distance = Math.sqrt(
				Math.pow(character2DPos.x - portal.x, 2) +
				Math.pow(character2DPos.y - portal.y, 2)
			);

			if (distance < portal.collisionRadius) {
				console.log(`🌀 포털 충돌 감지: ${portal.id} -> ${portal.targetMap}`);
				return portal.targetMap;
			}
		}

		return null;
	}

	// ===== 좌표 변환 유틸리티 =====
	worldToImageCoordinates(worldX, worldZ) {
		const mapConfig = this.gameClient.getMapConfig();
		const scaleRatio = mapConfig.IMAGE_WIDTH / 100;
		const imageCenterX = mapConfig.IMAGE_WIDTH / 2;
		const imageCenterY = mapConfig.IMAGE_HEIGHT / 2;

		return {
			x: worldX * scaleRatio + imageCenterX,
			y: worldZ * scaleRatio + imageCenterY
		};
	}


	// ===== 포털 진입 처리 =====
	handlePortalEntry(targetMap) {
		if (this.isTransitioning) return;

		console.log(`🌀 포털 진입: ${targetMap}`);
		this.isTransitioning = true;

		// 서버에 맵 변경 요청 (websocketChatModule을 통해)
		const websocketModule = this.gameClient.getwebsocketChatModule();
		if (websocketModule && websocketModule.requestMapChange) {
			websocketModule.requestMapChange(targetMap);
		} else {
			console.warn('⚠️ WebSocket 모듈을 찾을 수 없어 맵 변경 요청을 전송할 수 없습니다.');
		}

		// 전환 효과 표시
		this.showTransitionEffect(targetMap);

		// 3초 후 플래그 해제 (안전장치)
		setTimeout(() => {
			this.isTransitioning = false;
		}, 3000);
	}

	// ===== 서버로부터 맵 전환 성공 응답 처리 =====
	handleMapChangeSuccess(message) {
		console.log(`✅ 맵 전환 성공: ${message.targetMap}`);
		this.executeTransition(message.targetMap);
	}

	// ===== 전환 효과 표시 =====
	showTransitionEffect(targetMap) {
		// 기존 오버레이 제거
		this.hideTransitionEffect();

		this.transitionOverlay = document.createElement('div');
		this.transitionOverlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 24px;
            z-index: 1000;
            transition: opacity 0.5s ease;
        `;

		// 맵별 메시지 커스터마이징
		let message = `${targetMap}로 이동 중...`;
		switch (targetMap) {
			case '/emotionMap':
				message = '감정의 세계로 이동 중...';
				break;
			case '/happyMap':
				message = '행복의 공간으로 이동 중...';
				break;
			case '/sadMap':
				message = '슬픔의 공간으로 이동 중...';
				break;
			case '/testMap':
				message = '테스트 맵으로 이동 중...';
				break;
		}

		this.transitionOverlay.innerHTML = `
            <div style="text-align: center;">
                <div style="font-size: 28px; margin-bottom: 20px;">🌀</div>
                <div>${message}</div>
                <div style="font-size: 14px; margin-top: 10px; opacity: 0.7;">잠시만 기다려주세요...</div>
            </div>
        `;

		document.body.appendChild(this.transitionOverlay);
	}

	// ===== 실제 페이지 전환 실행 =====
	executeTransition(targetMap) {
		let redirectPath;

		switch (targetMap) {
			case '/testMap':
				redirectPath = '/usr/game/testMap';
				break;
			case '/emotionMap':
				redirectPath = '/usr/game/emotionMap';
				break;
			case '/happyMap':
				redirectPath = '/usr/game/happyMap';
				break;
			case '/sadMap':
				redirectPath = '/usr/game/sadMap';
				break;
			default:
				redirectPath = '/usr/game/startMap';
				console.warn(`⚠️ 알 수 없는 타겟 맵: ${targetMap}, 시작 맵으로 이동`);
		}

		console.log(`🔄 페이지 이동: ${redirectPath}`);

		setTimeout(() => {
			window.location.href = redirectPath;
		}, 1000);
	}

	// ===== 전환 효과 제거 =====
	hideTransitionEffect() {
		if (this.transitionOverlay) {
			this.transitionOverlay.style.opacity = '0';
			setTimeout(() => {
				if (this.transitionOverlay) {
					document.body.removeChild(this.transitionOverlay);
					this.transitionOverlay = null;
				}
			}, 500);
		}
	}

	// ===== 맵 드래그 활성화/비활성화 =====
	setDragEnabled(enabled) {
		this.mapDragEnabled = enabled;

		if (this.container) {
			this.container.style.cursor = enabled ? 'grab' : 'default';
		}
	}

	// ===== 전환 상태 확인 =====
	isInTransition() {
		return this.isTransitioning;
	}

	// ===== 포털 관리 메서드들 =====

	// 특정 포털 요소 찾기
	getPortalElement(targetMap) {
		const portal = this.portalCollisionAreas.find(p => p.targetMap === targetMap);
		return portal ? portal.element : null;
	}

	// 포털 활성화/비활성화
	setPortalActive(targetMap, active) {
		const portalElement = this.getPortalElement(targetMap);
		if (portalElement) {
			portalElement.style.display = active ? 'block' : 'none';
			console.log(`🌀 포털 ${active ? '활성화' : '비활성화'}: ${targetMap}`);
		}
	}

	// 모든 포털 활성화/비활성화
	setAllPortalsActive(active) {
		this.portalCollisionAreas.forEach(portal => {
			if (portal.element) {
				portal.element.style.display = active ? 'block' : 'none';
			}
		});
		console.log(`🌀 모든 포털 ${active ? '활성화' : '비활성화'}`);
	}

	// ===== 맵 정보 조회 =====
	getMapInfo() {
		return {
			scale: this.scale,
			position: { x: this.posX, y: this.posY },
			isDragging: this.isDragging,
			dragEnabled: this.mapDragEnabled,
			isTransitioning: this.isTransitioning,
			portalCount: this.portalCollisionAreas.length
		};
	}

	// 현재 맵 변환 정보 반환
	getTransform() {
		return {
			posX: this.posX,
			posY: this.posY,
			scale: this.scale
		};
	}

	// ===== 맵 위치 제어 메서드들 =====

	// 특정 위치로 맵 이동
	moveTo(x, y, smooth = true) {
		if (smooth) {
			// 부드러운 이동 (애니메이션)
			const duration = 1000; // 1초
			const startX = this.posX;
			const startY = this.posY;
			const startTime = performance.now();

			const animate = (currentTime) => {
				const elapsed = currentTime - startTime;
				const progress = Math.min(elapsed / duration, 1);

				// 이징 함수 (ease-out)
				const easedProgress = 1 - Math.pow(1 - progress, 3);

				this.posX = startX + (x - startX) * easedProgress;
				this.posY = startY + (y - startY) * easedProgress;

				this.applyTransform();

				if (progress < 1) {
					requestAnimationFrame(animate);
				}
			};

			requestAnimationFrame(animate);
		} else {
			// 즉시 이동
			this.posX = x;
			this.posY = y;
			this.applyTransform();
		}
	}

	// 맵 중앙으로 이동
	centerMap() {
		const mapConfig = this.gameClient.getMapConfig();
		const containerWidth = this.container?.clientWidth || window.innerWidth;
		const containerHeight = this.container?.clientHeight || window.innerHeight;

		const scaledWidth = mapConfig.IMAGE_WIDTH * this.scale;
		const scaledHeight = mapConfig.IMAGE_HEIGHT * this.scale;

		const centerX = (containerWidth - scaledWidth) / 2;
		const centerY = (containerHeight - scaledHeight) / 2;

		this.moveTo(centerX, centerY, true);
	}

	// 특정 스케일로 줌
	zoomTo(targetScale, smooth = true) {
		const mapConfig = this.gameClient.getMapConfig();
		targetScale = Math.min(mapConfig.MAX_SCALE, Math.max(mapConfig.MIN_SCALE, targetScale));

		if (smooth) {
			// 부드러운 줌
			const duration = 500;
			const startScale = this.scale;
			const startTime = performance.now();

			const animate = (currentTime) => {
				const elapsed = currentTime - startTime;
				const progress = Math.min(elapsed / duration, 1);
				const easedProgress = 1 - Math.pow(1 - progress, 2);

				this.scale = startScale + (targetScale - startScale) * easedProgress;
				this.applyTransform();

				if (progress < 1) {
					requestAnimationFrame(animate);
				}
			};

			requestAnimationFrame(animate);
		} else {
			this.scale = targetScale;
			this.applyTransform();
		}
	}
	smoothMoveTo(targetX, targetY, lerpFactor) {
		this.posX += (targetX - this.posX) * lerpFactor;
		this.posY += (targetY - this.posY) * lerpFactor;
		this.applyTransform();
	}
	// ===== 디버그 메서드들 =====
	enableDebugMode() {
		console.log('🔍 MapModule 디버그 모드 활성화');

		// 포털 위치에 디버그 마커 표시
		this.portalCollisionAreas.forEach(portal => {
			const marker = document.createElement('div');
			marker.style.cssText = `
                position: absolute;
                width: ${portal.collisionRadius * 2}px;
                height: ${portal.collisionRadius * 2}px;
                border: 2px solid red;
                border-radius: 50%;
                background: rgba(255, 0, 0, 0.2);
                pointer-events: none;
                z-index: 100;
                left: ${portal.x - portal.collisionRadius}px;
                top: ${portal.y - portal.collisionRadius}px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 10px;
                color: red;
            `;
			marker.textContent = portal.id;

			if (this.mapInner) {
				this.mapInner.appendChild(marker);
			}
		});

		console.log('🎯 포털 디버그 마커 표시됨');
	}

	// ===== 리소스 정리 =====
	dispose() {
		console.log('🧹 MapModule 리소스 정리');

		// 전환 효과 제거
		this.hideTransitionEffect();

		// 이벤트 리스너 제거
		if (this.container) {
			this.container.removeEventListener('wheel', this.handleWheel);
			this.container.removeEventListener('pointerdown', this.handlePointerDown);
			this.container.removeEventListener('pointermove', this.handlePointerMove);
			this.container.removeEventListener('pointerup', this.handlePointerUp);
		}

		// 씬 그룹 정리
		if (this.mapGroup) {
			const threeCore = this.gameClient.getThreeCore();
			if (threeCore) {
				threeCore.removeGroup('map');
			}
		}

		// 상태 초기화
		this.isInitialized = false;
		this.isTransitioning = false;

		console.log('✅ MapModule 정리 완료');
	}
}

// ===== 전역 접근용 (테스트/디버그) =====
if (typeof window !== 'undefined') {
	window.MapModule = MapModule;
}

console.log('📦 MapModule 로드 완료');