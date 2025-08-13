
export class MapModule {
	constructor(gameClient, mapName) {
		this.gameClient = gameClient;
		this.isInitialized = false;

		// ===== 맵 렌더링 관련 =====
		this.container = null;
		this.currentMapName = mapName;
		this.scale = 0.5;
		this.posX = 0;
		this.posY = 0;
		this.isDragging = false;
		this.startX = 0;
		this.startY = 0;
		this.mapDragEnabled = true;

		// ===== 포털 관련 =====
		this.portalCollisionAreas = [];
		// ===== 단순 디버그 마커 관련 =====
		this.simpleMarkers = [];
		this.markersVisible = false;
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
		this.maskingOffsets = null;

		// ===== 캐릭터 DOM관련 =====
		this.characterContainer = null;
		this.lastCharacterScreenX = null;
		this.lastCharacterScreenY = null;
		this.lastCharacterScale = null;

		// ===== 캐릭터 DOM관련 =====
		this.aiChatbot = null;
		this.aiChatbotMapX = 1800; // 기본값
		this.aiChatbotMapY = 1500; // 기본값
		console.log('🗺️ MapModule 생성됨');

	}

	// ===== 외부에서 마스킹 데이터 설정 =====
	setMaskingData(polygon, ellipse) {
		this.maskingPolygon = polygon;
		this.restrictedEllipse = ellipse;
		console.log('📌 외부 마스킹 데이터 적용 완료');
	}

	// ===== 마스킹 영역 초기화 =====

	setupMaskingAreas(mapName) {

		if (mapName === 'startMap') {
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

			this.maskingOffsets = { offsetX: 70, offsetY: -130 };
		}
		// ✨ 추후 다른 맵들에 대한 조건 추가 가능
		else if (mapName === 'happyMap') {
			this.maskingPolygon = [
				[762.087, 143.519], [748.518, 150.891], [737.416, 143.519],
				[726.314, 137.376], [674.506, 98.0607], [631.333, 69.8025],
				[574.59, 40.3157], [453.705, 7.14308], [364.891, 1],
				[285.945, 7.14308], [200.832, 19.4292], [116.952, 47.6874],
				[52.8082, 98.0607], [15.8023, 150.891], [1, 202.493],
				[15.8023, 236.894], [7.16764, 278.667], [46.6405, 336.412],
				[110.784, 395.386], [223.035, 481.389], [326.651, 531.762],
				[419.166, 588.278], [507.98, 632.509], [654.77, 692.711],
				[726.314, 749.227], [780.59, 791], [812.661, 766.428],
				[890.374, 717.283], [1108.71, 599.336], [1262.9, 508.418],
				[1359.11, 438.387], [1399.82, 395.386], [1435.59, 354.841],
				[1450.4, 313.068], [1472.6, 278.667], [1472.6, 227.065],
				[1480, 187.75], [1456.56, 137.376], [1417.09, 88.2317],
				[1351.71, 47.6874], [1338.14, 69.8025], [1328.28, 98.0607],
				[1315.94, 122.633], [1296.2, 143.519], [1244.4, 159.491],
				[1174.09, 159.491], [1123.51, 137.376], [1097.61, 116.49],
				[1069.24, 77.1742], [1081.57, 47.6874], [1140.78, 1],
				[1097.61, 1], [1031, 7.14308], [961.918, 19.4292],
				[901.475, 40.3157], [858.302, 61.2022], [812.661, 98.0607],
				[780.59, 122.633], [762.087, 143.519]
			];
			this.restrictedEllipse = {
				centerX: 550,  // 중심 위치 (X)
				centerY: -400,  // 중심 위치 (Y)
				radiusX: 130,
				radiusY: 150
			};
			this.maskingOffsets = { offsetX: 70, offsetY: -20 };

		} else if (mapName === 'angerMap') {
			this.maskingPolygon = [
				[2, 115], [118, 29], [590, 181], [624, 157], [768, 79],
				[954, 29], [1148, 1], [1382, 1], [1580, 29], [1784, 99],
				[1990, 215], [2078, 321], [2106, 427], [2118, 473], [2078, 583],
				[2028, 651], [1878, 753], [1580, 857], [1340, 885], [1054, 885],
				[810, 829], [522, 705], [410, 583], [394, 509], [410, 383],
				[458, 297], [2, 115]
			];
			
			this.restrictedPolygon = [
				[944.992, 451.096], [994.512, 487.058], [1088.25, 523.019],
				[1243.88, 541], [1413.67, 523.019], [1525.09, 467.442],
				[1564, 410.231], [1564, 338.308], [1516.25, 276.192],
				[1413.67, 223.885], [1295.17, 201], [1181.98, 201],
				[1051.11, 235.327], [962.678, 284.365], [922, 346.481],
				[932.612, 410.231], [944.992, 451.096]
			];
			
			this.restrictedEllipse = {
				centerX: 0,  // 중심 위치 (X)
				centerY: -220,  // 중심 위치 (Y)
				radiusX: 350,
				radiusY: 200
			};
			this.maskingOffsets = { offsetX: -190, offsetY: -150 };

		} else if (mapName === 'sadMap') {
			this.maskingPolygon = [
				[96, 825], [2, 863], [110, 939], [182, 1047], [170, 1067],
				[388, 1251], [326, 1305], [246, 1231], [170, 1271], [246, 1333],
				[226, 1355], [410, 1439], [490, 1379], [632, 1333], [612, 1271],
				[642, 1251], [698, 1271], [770, 1251], [834, 1293], [1104, 1161],
				[1356, 1293], [1454, 1271], [1454, 1199], [1214, 1115], [1650, 853],
				[1688, 765], [1660, 629], [1576, 507], [1164, 289], [1056, 157],
				[1022, 157], [992, 119], [834, 1], [770, 33], [794, 59],
				[874, 129], [896, 177], [992, 271], [992, 349], [1438, 575],
				[1466, 683], [1466, 751], [1484, 751], [1484, 795], [1454, 883],
				[1400, 921], [1324, 955], [1192, 1037], [1008, 1129], [862, 1177],
				[794, 1105], [698, 1129], [642, 1161], [642, 1177], [600, 1199],
				[568, 1187], [536, 1187], [490, 1187], [462, 1199], [424, 1161],
				[362, 1147], [362, 1105], [326, 1089], [284, 1067], [284, 997],
				[226, 955], [182, 883], [120, 853], [96, 825]
			];
			this.restrictedEllipse = {
				centerX: 0,  // 중심 위치 (X)
				centerY: 0,  // 중심 위치 (Y)
				radiusX: 0,
				radiusY: 0
			};
			this.maskingOffsets = { offsetX: 80, offsetY: -160 };
		} else if (mapName === 'zenMap') {
			this.maskingPolygon = [
				[59, 465], [1, 465], [21, 553], [89, 649], [193, 755], [159, 773],
				[241, 827], [479, 909], [747, 947], [953, 947], [1195, 909], [1407, 827],
				[1591, 703], [1687, 543], [1697, 437], [1675, 349], [1615, 253], [1551, 201],
				[1437, 125], [1295, 67], [1019, 11], [837, 1], [689, 11], [499, 41],
				[353, 79], [241, 125], [149, 177], [59, 241], [59, 299], [149, 309],
				[193, 331], [229, 263], [605, 349], [659, 309], [353, 241], [309, 219],
				[427, 149], [559, 103], [747, 79], [941, 79], [1113, 103], [1251, 149],
				[1387, 219], [1459, 299], [1493, 385], [1493, 465], [1459, 543], [1367, 649],
				[1215, 727], [1019, 783], [837, 799], [659, 783], [523, 755], [383, 703],
				[289, 649], [211, 577], [159, 493], [159, 437], [101, 437], [59, 465]
			];
						
			this.restrictedEllipse = {
				centerX: 0,  // 중심 위치 (X)
				centerY: 0,  // 중심 위치 (Y)
				radiusX: 0,
				radiusY: 0
			};
			this.maskingOffsets = { offsetX: 115, offsetY: -45 };

		} else if (mapName === 'anxietyMap') {
			this.maskingPolygon = [
				[962, 0.5],
				[0, 467],
				[200.5, 602],
				[244, 580.5],
				[319, 643.5],
				[319, 672.5],
				[442, 745],
				[1000.5, 1095.5],
				[1435.5, 805.5],
				[1525, 745],
				[1472, 687],
				[1542, 672.5],
				[1619.5, 687],
				[1955.5, 467],
				[962, 0.5]
			];

			this.restrictedPolygon = [
				[979, 650],
				[689, 476],
				[979, 320],
				[1267, 476],
				[979, 650]
			];

			this.restrictedEllipse = {
				centerX: 0,
				centerY: 0,
				radiusX: 0,
				radiusY: 0
			};

			this.maskingOffsets = { offsetX: 100, offsetY: -150 };

			// ✅ 이동 가능 영역 내부 && restrictedPolygon 외부일 때만 이동 가능하도록 설정
			this.isWalkable = (x, y) => {
				return isInsidePolygon(x, y, this.maskingPolygon) &&
					!isInsidePolygon(x, y, this.restrictedPolygon) &&
					!isInsideEllipse(x, y, this.restrictedEllipse);
			};
		} else {
			console.warn(`⚠️ '${mapName}'에 대한 마스킹 데이터가 없습니다.`);
		}


		console.log('🎯 마스킹 영역 설정 완료');
	}
	// ===== 초기화 =====
	async initialize(currentMapName) {
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
			this.setupMaskingAreas(currentMapName);
			this.initMaskingCanvas();
			// DOM 포털 초기화
			this.initDOMPortals();

			// 챗봇 초기화
			this.setAIChatbotPositionByMap(currentMapName);
			this.initAIChatbotDOM();
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
		if (!this.ctx || !this.canvas || !this.maskingPolygon) {
			console.warn('⛔ 마스킹 데이터가 비어 있어 drawMaskArea를 건너뜁니다.');
			return;
		}
		this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

		this.ctx.fillStyle = 'rgba(255, 255, 0, 0)';

		this.ctx.strokeStyle = 'rgba(255, 0, 0, 0)';
		this.ctx.lineWidth = 2.3;

		const scale = 1;
		const offsetX = this.maskingOffsets?.offsetX;
		const offsetY = this.maskingOffsets?.offsetY;

		const points = this.maskingPolygon;
		const xs = points.map(p => p[0]);
		const ys = points.map(p => p[1]);
		const maskCenterX = (Math.min(...xs) + Math.max(...xs)) / 2;
		const maskCenterY = (Math.min(...ys) + Math.max(...ys)) / 2;

		const canvasCenterX = this.canvas.width / 2;
		const canvasCenterY = this.canvas.height / 2;

		// 1️⃣ 바깥 다각형 마스킹 (이동 가능 영역)
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

		// 2️⃣ 이동 불가능 타원 (구멍 만들기)
		if (this.restrictedEllipse) {
			this.ctx.save();
			this.ctx.globalCompositeOperation = 'destination-out';

			const ellipseX = canvasCenterX + this.restrictedEllipse.centerX;
			const ellipseY = canvasCenterY + this.restrictedEllipse.centerY;
			const radiusX = this.restrictedEllipse.radiusX;
			const radiusY = this.restrictedEllipse.radiusY;

			this.ctx.beginPath();
			this.ctx.ellipse(ellipseX, ellipseY, radiusX, radiusY, 0, 0, Math.PI * 2);
			this.ctx.fill();
			this.ctx.restore();
		}

		// 3️⃣ restrictedPolygon 다각형 구멍 처리
		if (this.restrictedPolygon) {
			this.ctx.save();
			this.ctx.globalCompositeOperation = 'destination-out';

			this.ctx.beginPath();
			for (let i = 0; i < this.restrictedPolygon.length; i++) {
				const x = (this.restrictedPolygon[i][0] - maskCenterX) * scale + canvasCenterX + offsetX;
				const y = (this.restrictedPolygon[i][1] - maskCenterY) * scale + canvasCenterY + offsetY;

				if (i === 0) this.ctx.moveTo(x, y);
				else this.ctx.lineTo(x, y);
			}
			this.ctx.closePath();
			this.ctx.fill();
			this.ctx.restore();

			// 🟥 빨간 테두리 그리기
			this.ctx.save();
			this.ctx.beginPath();
			for (let i = 0; i < this.restrictedPolygon.length; i++) {
				const x = (this.restrictedPolygon[i][0] - maskCenterX) * scale + canvasCenterX + offsetX;
				const y = (this.restrictedPolygon[i][1] - maskCenterY) * scale + canvasCenterY + offsetY;

				if (i === 0) this.ctx.moveTo(x, y);
				else this.ctx.lineTo(x, y);
			}
			this.ctx.closePath();
			this.ctx.stroke();
			this.ctx.restore();
		}
	}


	// ===== 이동 가능 여부 검사 =====
	isMovementAllowed(position3D) {
		if (!position3D) return true;
		// 3D 좌표를 2D 이미지 좌표로 변환
		const imageCoord = this.worldToImageCoordinates(position3D.x, position3D.z);
		// 1. 다각형 내부에 있는지 검사 (이동 가능 영역)
		if (this.isPointInPolygon(imageCoord, this.maskingPolygon)) {
			// 2. 타원 내부에 있는지 검사 (이동 불가능 구멍)
			if (this.isPointInEllipse(imageCoord, this.restrictedEllipse)) {
				return false; // 타원 내부는 이동 불가능
			}
			if (this.isPointInRestrictedPolygon(imageCoord, this.restrictedPolygon)) {
				return false; // 이동불가 폴리곤 내부는 이동 불가능
			}
			return true; // 다각형 내부이지만 타원 밖은 이동 가능
		}

		return false; // 다각형 밖은 이동 불가능
	}

	// ===== 점이 다각형 내부에 있는지 검사 (Ray casting algorithm) =====
	isPointInPolygon(point, polygon) {
		const mapConfig = this.gameClient.getMapConfig();

		// 다각형 좌표를 실제 캔버스 좌표로 변환
		const scale = 1;
		const offsetX = this.maskingOffsets?.offsetX;
		const offsetY = this.maskingOffsets?.offsetY;

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
	// ===== 점이 이동불가 다각형 내부에 있는지 검사 =====
	isPointInRestrictedPolygon(point, polygon) {
		if (!polygon || polygon.length < 3) return false;

		// 맵 정보와 스케일, 오프셋
		const mapConfig = this.gameClient.getMapConfig();
		const scale = 1;
		const offsetX = this.maskingOffsets?.offsetX ;
		const offsetY = this.maskingOffsets?.offsetY ;

		// 중심 기준 (이미지 중심)
		const canvasCenterX = mapConfig.IMAGE_WIDTH / 2;
		const canvasCenterY = mapConfig.IMAGE_HEIGHT / 2;

		// 마스킹 폴리곤 중심점 구하기
		const maskCenterX = polygon.reduce((sum, p) => sum + p[0], 0) / polygon.length;
		const maskCenterY = polygon.reduce((sum, p) => sum + p[1], 0) / polygon.length;

		// 실좌표 기준으로 변환된 폴리곤
		const transformedPolygon = polygon.map(p => [
			(p[0] - maskCenterX) * scale + canvasCenterX + offsetX,
			(p[1] - maskCenterY) * scale + canvasCenterY + offsetY
		]);

		// 포인트 비교
		const x = point.x;
		const y = point.y;
		let inside = false;

		for (let i = 0, j = transformedPolygon.length - 1; i < transformedPolygon.length; j = i++) {
			const xi = transformedPolygon[i][0], yi = transformedPolygon[i][1];
			const xj = transformedPolygon[j][0], yj = transformedPolygon[j][1];

			const intersect = ((yi > y) !== (yj > y)) &&
				(x < ((xj - xi) * (y - yi)) / (yj - yi) + xi);

			if (intersect) inside = !inside;
		}

		return inside;
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
					collisionRadius: itemData.id === 'object' ? 20 : 80,
					element: element,
					type: itemData.id === 'object' ? 'object' : 'portal'
				});
				console.log(`🌀 ${itemData.id === 'object' ? '오브젝트' : '포털'} 등록: ${itemData.id} (${itemData.x}, ${itemData.y})`);
				console.log(this.portalCollisionAreas);
			} else {
				console.warn(`⚠️ 요소를 찾을 수 없음: ${itemData.id}`);
			}
		});
		console.log(`✅ DOM 포털 초기화 완료: ${this.portalCollisionAreas.length}개`);
	}
	setAIChatbotPositionByMap(mapName) {
		switch (mapName) {
			case 'startMap':
				this.aiChatbotMapX = 2500;
				this.aiChatbotMapY = 1500;
				break;

			case 'happyMap':
				this.aiChatbotMapX = 2910;
				this.aiChatbotMapY = 1300;
				break;

			case 'angerMap':
				this.aiChatbotMapX = 1050;
				this.aiChatbotMapY = 1050;
				break;

			case 'sadMap':
				this.aiChatbotMapX = 2400;
				this.aiChatbotMapY = 800;
				break;

			case 'anxietyMap':
				this.aiChatbotMapX = 2480;
				this.aiChatbotMapY = 1530;
				break;

			case 'zenMap':
				this.aiChatbotMapX = 2425;
				this.aiChatbotMapY = 1600;
				break;

			default:
				this.aiChatbotMapX = 2500;
				this.aiChatbotMapY = 1500;
				console.warn(`⚠️ '${mapName}'에 대한 AI 챗봇 위치가 설정되지 않아 기본값을 사용합니다.`);
		}

		console.log(`🤖 ${mapName} AI 챗봇 위치 설정: (${this.aiChatbotMapX}, ${this.aiChatbotMapY})`);
	}

	initAIChatbotDOM() {
		this.aiChatbot = document.getElementById('aiChatbot');
		if (!this.aiChatbot) return;

		this.aiChatbot.addEventListener('click', (event) => {
			event.stopPropagation();

			// 기존 transform 값 백업
			const originalTransform = this.aiChatbot.style.transform || window.getComputedStyle(this.aiChatbot).transform || '';

			// 클릭 애니메이션 (translateY만 추가)
			this.aiChatbot.style.transition = 'transform 0.15s ease';
			this.aiChatbot.style.transform = `${originalTransform} translateY(-50px)`;

			// 원래 위치로 복귀
			setTimeout(() => {
				this.aiChatbot.style.transform = originalTransform;
			}, 150);

			// 0.8초 후 페이지 이동
			setTimeout(() => {
				this.executeTransition('chatBot');
			}, 800);
		});
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


		// 마스킹 영역 다시 그리기
		this.drawMaskArea();

		// 포털 위치 업데이트
		this.updatePortals();

		// ===== AI 챗봇 위치 업데이트 추가 =====
		this.updateAIChatbotPosition();

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
		// PORTAL_POSITIONS에서 등록되지 않은 포털들 별도 처리
		const portalPositions = this.gameClient.getPortalPositions();
		const additionalPortals = ['happy_portal', 'anxiety_portal', 'sad_portal', 'anger_portal', 'zen_portal'];

		additionalPortals.forEach(portalId => {
			const element = document.getElementById(portalId);
			if (element) {
				// PORTAL_POSITIONS에서 해당 포털의 좌표 찾기
				const portalData = portalPositions.find(p => p.id === portalId);
				if (portalData) {
					const cssOffset = this.getPortalCSSOffset(portalId);
					const tx = (portalData.x + cssOffset.x) * this.scale + this.posX;
					const ty = (portalData.y + cssOffset.y) * this.scale + this.posY;
					element.style.transform = `translate(${tx}px, ${ty}px) scale(${this.scale})`;
					element.style.transformOrigin = 'top left';
				}
			}
		});
	}

	updateAIChatbotPosition() {
		if (!this.aiChatbot) return;

		// 화면 좌표로 변환
		const screenX = this.aiChatbotMapX * this.scale + this.posX;
		const screenY = this.aiChatbotMapY * this.scale + this.posY;

		// AI 챗봇 위치 업데이트
		this.aiChatbot.style.left = screenX + 'px';
		this.aiChatbot.style.top = screenY + 'px';
		this.aiChatbot.style.transform = `scale(${this.scale})`;
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
			const characterRenderModule = this.gameClient.getCharacterRenderModule();

			if (!characterRenderModule) return;

			// ✅ 모든 캐릭터의 캔버스 위치 업데이트
			const allCharacters = characterRenderModule.getAllCharacters();
			const renderInstances = characterRenderModule.playerRenderInstances;

			allCharacters.forEach((character, sessionId) => {
				const instance = renderInstances.get(sessionId);
				if (!instance || !instance.canvas) return;

				// 좌표 계산
				const imageCoord = this.worldToImageCoordinates(
					character.position.x,
					character.position.z
				);

				const screenX = imageCoord.x * this.scale + this.posX;
				const screenY = imageCoord.y * this.scale + this.posY;

				// ✅ 성능 최적화: 위치나 스케일이 변경되었을 때만 업데이트
				const lastUpdate = instance.lastDOMUpdate || {};
				if (lastUpdate.screenX !== screenX ||
					lastUpdate.screenY !== screenY ||
					lastUpdate.scale !== this.scale) {

					const canvas = instance.canvas;
					canvas.style.position = 'absolute';
					canvas.style.left = (screenX - 180) + 'px';
					canvas.style.top = (screenY - 180) + 'px';
					canvas.style.transform = `scale(${this.scale})`;
					canvas.style.transformOrigin = 'center center';

					// 업데이트 기록
					instance.lastDOMUpdate = {
						screenX,
						screenY,
						scale: this.scale
					};
				}
			});


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
		const characterScreenX = character2DPos.x * this.scale + this.posX - 180;
		const characterScreenY = character2DPos.y * this.scale + this.posY - 180;

		// 각 포털과의 거리 계산
		for (const portal of this.portalCollisionAreas) {
			const cssOffset = this.getPortalCSSOffset(portal.id);
			const portalScreenX = (portal.x + cssOffset.x) * this.scale + this.posX;
			const portalScreenY = (portal.y + cssOffset.y) * this.scale + this.posY;
			const distance = Math.sqrt(
				Math.pow(characterScreenX - portalScreenX, 2) +
				Math.pow(characterScreenY - portalScreenY, 2)
			);
			const scaledRadius = portal.collisionRadius * this.scale;
			if (distance < scaledRadius) {
				console.log(`🌀 포털 충돌 감지: ${portal.id} -> ${portal.targetMap}`);
				return portal.targetMap;
			}
		}
		return null;
	}

	getPortalCSSOffset(portalId) {
		const offsets = {
			'portal_1': { x: 80, y: 225 },
			'portal_2': { x: -380, y: 20 },
			'portal_3': { x: -20, y: 20 },
			'portal_4': { x: 1, y: 15 },
			'portal_5': { x: 0, y: 0 },
			'sad_portal': { x: 0, y: 0 },
			'happy_portal': { x: 0, y: 0 },
			'anger_portal': { x: -150, y: 0 },
			'anxiety_portal': { x: 0, y: 0 },
			'zen_portal': { x: 0, y: 0 }
		};
		return offsets[portalId] || { x: 0, y: 0 };
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
		console.log('포털진입처리', targetMap);
		if (this.isTransitioning) return;

		console.log(`🌀 포털 진입: ${targetMap}`);
		this.isTransitioning = true;

		// 서버에 맵 변경 요청 (websocketChatModule을 통해)
		const websocketModule = this.gameClient.getWebSocketChatModule();
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
			case 'angerMap':
				message = '분노의 세계로 이동 중...';
				break;
			case 'zenMap':
				message = '평온의 호수으로 이동 중...';
				break;
			case 'happyMap':
				message = '행복의 공간으로 이동 중...';
				break;
			case 'sadMap':
				message = '슬픔의 공간으로 이동 중...';
				break;
			case 'anxietyMap':
				message = '불안의 공간으로 이동 중...';
				break;
			case 'startMap':
				message = '시작 맵으로 이동 중...';
				break;
		}

		this.transitionOverlay.innerHTML = `
            <div style="text-align: center;">
                <div style="font-size: 50px; margin-bottom: 20px;">🌀</div>
                <div>${message}</div>
            </div>
        `;

		document.body.appendChild(this.transitionOverlay);
	}

	// ===== 실제 페이지 전환 실행 =====
	executeTransition(targetMap) {

		let redirectPath;
		if (targetMap === 'chatBot') {
			this.createChatBotModal();
		
			/*redirectPath = `/usr/game/chatBot?currentMap=${currentMap}`;
			console.log(`🤖 AI 상담 페이지 이동: ${redirectPath}`);

			// AI 챗봇은 즉시 이동 (딜레이 없음)
			window.location.href = redirectPath;*/
			return;
		}

		switch (targetMap) {
			case 'angerMap':
				redirectPath = '/usr/game/angerMap';
				break;
			case 'zenMap':
				redirectPath = '/usr/game/zenMap';
				break;
			case 'happyMap':
				redirectPath = '/usr/game/happyMap';
				break;
			case 'sadMap':
				redirectPath = '/usr/game/sadMap';
				break;
			case 'anxietyMap':
				redirectPath = '/usr/game/anxietyMap';
				break;
			default:
				redirectPath = '/usr/game/startMap';
		}

		console.log(`🔄 페이지 이동: ${redirectPath}`);

		setTimeout(() => {
			window.location.href = redirectPath;
		}, 2000);
	}

	createChatBotModal() {
	    // 기존 모달이 있으면 제거
	    const existingModal = document.getElementById('chatBotModal');
	    if (existingModal) {
	        existingModal.remove();
	    }

	    // 현재 맵 정보 가져오기
	    const currentMap = this.gameClient.currentMapName;
	    
	    // 맵별 챗봇 타입 매핑 (기존 chatBot.jsp와 동일)
	    const mapToBotType = {
	        'startMap': null,
	        'angerMap': 'Anger',
	        'happyMap': 'Joy',
	        'sadMap': 'Hope',
	        'anxietyMap': 'Calm',
	        'zenMap': 'Zen'
	    };

	    // 봇 이모지 매핑 (기존과 동일)
	    const botEmojis = {
	        'Anger': '😤',
	        'Hope': '😢', 
	        'Calm': '😰',
	        'Joy': '😊',
	        'Zen': '😌'
	    };

	    // 봇 이름 매핑 (기존과 동일)
	    const getBotDisplayName = (botType) => {
	        const names = {
	            'Anger': '버럭이',
	            'Hope': '슬픔이', 
	            'Calm': '소심이',
	            'Joy': '기쁨이',
	            'Zen': '평온이'
	        };
	        return names[botType] || '상담사';
	    };

	    // 환영 메시지 매핑 (기존과 동일)
	    const mapWelcomeMessages = {
	        'angerMap': '분노의 세계에서 오셨군요. 버럭이가 당신의 화를 이해하고 도와드릴게요. 무엇이 화나게 했나요?',
	        'happyMap': '행복의 공간에서 오셨네요! 기쁨이와 함께 더 많은 기쁨을 나누어봐요. 오늘 좋은 일이 있으셨나요?',
	        'sadMap': '슬픔의 공간에서 오셨군요. 슬픔이가 당신의 마음을 이해하고 위로해드릴게요. 무엇이 슬프게 했나요?',
	        'anxietyMap': '불안의 공간에서 오셨네요. 소심이가 당신의 불안감을 달래드릴게요. 어떤 것이 불안하신가요?',
	        'zenMap': '평온의 호수에서 오셨군요. 평온이와 함께 마음의 평화를 찾아봐요. 어떻게 도와드릴까요?'
	    };

	    // 모달 HTML 구조 생성 (기존 chatBot.jsp 구조 활용)
	    const modalHTML = `
	        <div id="chatBotModal" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 10000; display: flex; justify-content: center; align-items: center;">
	            <div class="chatBot-container" style="width: 90%; max-width: 600px; height: 80%; max-height: 700px; display: flex; flex-direction: column;">
	                <!-- 헤더 -->
	                <div class="chatBot-header">
	                    <h1>감정별 전문 상담 AI 챗봇</h1>
	                    <button id="closeChatBotModal" class="map-icon-btn">
	                        🗺️ <span class="tooltip">맵으로 돌아가기</span>
	                    </button>
	                </div>

	                <!-- 현재 모드 표시 -->
	                <div class="current-mode">
	                    <span id="currentMode">일반 채팅 모드</span>
	                </div>

	                <!-- 메시지 영역 -->
	                <div class="chat-messages" id="chatMessages" style="flex: 1;">
	                    <div class="typing" id="typing">AI가 답변을 생각하고 있습니다</div>
	                </div>

	                <!-- 입력 영역 -->
	                <div class="chat-input">
	                    <textarea id="messageInput" placeholder="메시지를 입력하세요..." rows="1"></textarea>
	                    <button id="sendBtn">전송</button>
	                </div>
	            </div>
	        </div>
	    `;

	    // 모달을 body에 추가
	    document.body.insertAdjacentHTML('beforeend', modalHTML);

	    // 현재 맵에 따른 봇 설정
	    const currentBotType = mapToBotType[currentMap];
	    let currentBotEmoji = '🤖';

	    // 모달 요소들 참조
	    const modal = document.getElementById('chatBotModal');
	    const chatMessages = document.getElementById('chatMessages');
	    const currentModeElement = document.getElementById('currentMode');
	    const messageInput = document.getElementById('messageInput');
	    const sendBtn = document.getElementById('sendBtn');
	    const closeBtn = document.getElementById('closeChatBotModal');
	    const typing = document.getElementById('typing');

	    // 봇 설정 및 환영 메시지
	    if (currentBotType) {
	        currentBotEmoji = botEmojis[currentBotType];
	        currentModeElement.textContent = getBotDisplayName(currentBotType) + ' 모드';
	        
	        const welcomeMessage = mapWelcomeMessages[currentMap];
	        if (welcomeMessage) {
	            addMessage('bot', welcomeMessage);
	        }
	        
	        messageInput.disabled = false;
	        messageInput.placeholder = '메시지를 입력하세요...';
	        sendBtn.disabled = false;
	    } else {
	        messageInput.disabled = true;
	        messageInput.placeholder = '상담사를 먼저 선택해주세요...';
	        sendBtn.disabled = true;
	        currentModeElement.textContent = '상담사를 선택해주세요';
	    }

	    // 메시지 추가 함수 (기존 chatBot.jsp와 동일)
	    function addMessage(sender, content) {
	        let avatar;
	        if (sender === 'user') {
	            avatar = '👤';
	        } else {
	            avatar = currentBotEmoji || '🤖';
	        }
	        
	        const messageHtml = `
	            <div class="message ${sender}">
	                <div class="avatar">${avatar}</div>
	                <div class="message-bubble">${content}</div>
	            </div>
	        `;
	        
	        typing.insertAdjacentHTML('beforebegin', messageHtml);
	        scrollToBottom();
	    }

	    // 타이핑 표시/숨김 함수
	    function showTyping() {
	        typing.style.display = 'block';
	        scrollToBottom();
	    }

	    function hideTyping() {
	        typing.style.display = 'none';
	    }

	    // 스크롤을 맨 아래로
	    function scrollToBottom() {
	        chatMessages.scrollTop = chatMessages.scrollHeight;
	    }

	    // 메시지 전송 함수 (기존 chatBot.jsp 로직 활용)
	    function sendMessage() {
	        const message = messageInput.value.trim();
	        if (!message) return;

	        // 봇이 선택되지 않은 경우 처리
	        if (!currentBotType) {
	            addMessage('bot', '먼저 상담사를 선택해주세요!');
	            return;
	        }

	        // 사용자 메시지 추가
	        addMessage('user', message);
	        messageInput.value = '';
	        messageInput.style.height = 'auto';
	        sendBtn.disabled = true;

	        // 타이핑 표시
	        showTyping();

	        // API 호출 (기존 로직과 동일)
	        const apiUrl = `/api/chat/message/${currentBotType}`;
	        
	        fetch(apiUrl, {
	            method: 'POST',
	            headers: {
	                'Content-Type': 'application/json',
	            },
	            body: JSON.stringify({ 
	                message: message, 
	                botType: currentBotType 
	            })
	        })
	        .then(response => response.json())
	        .then(data => {
	            hideTyping();
	            addMessage('bot', data.response);
	            
	            if (data.response && data.response.includes('상담이 일시 중단됩니다')) {
	                messageInput.disabled = true;
	                messageInput.placeholder = '상담이 종료되었습니다.';
	                messageInput.style.backgroundColor = '#f5f5f5';
	                sendBtn.disabled = true;
	                sendBtn.textContent = '종료됨';
	                sendBtn.style.backgroundColor = '#ccc';
	                currentModeElement.textContent = '상담 종료';
	                currentModeElement.style.color = '#ff4444';
	                return;
	            }
	            sendBtn.disabled = false;
	        })
	        .catch(error => {
	            console.error('오류 상세:', error);
	            hideTyping();
	            addMessage('bot', '죄송합니다. 오류가 발생했습니다.');
	            sendBtn.disabled = false;
	        });
	    }

	    // 이벤트 리스너 등록
	    // 엔터키로 메시지 전송
	    messageInput.addEventListener('keypress', function(e) {
	        if (e.key === 'Enter' && !e.shiftKey) {
	            e.preventDefault();
	            sendMessage();
	        }
	    });

	    // 전송 버튼 클릭
	    sendBtn.addEventListener('click', sendMessage);

	    // 입력창 자동 높이 조절
	    messageInput.addEventListener('input', function() {
	        this.style.height = 'auto';
	        this.style.height = Math.min(this.scrollHeight, 100) + 'px';
	    });

	    // 모달 닫기 버튼
	    closeBtn.addEventListener('click', () => {
	        modal.remove();
	    });


	    // 입력창에 포커스
	    setTimeout(() => {
	        if (!messageInput.disabled) {
	            messageInput.focus();
	        }
	    }, 100);

	    console.log('🤖 ChatBot 모달 생성 완료');
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
	showPortalCenters() {
		console.log('📍 포털 중심점 마커 표시');

		this.hidePortalCenters(); // 기존 마커 제거

		this.portalCollisionAreas.forEach((portal) => {
			const marker = document.createElement('div');
			marker.id = `marker-${portal.id}`;
			marker.style.cssText = `
	              position: absolute;
	              width: 10px;
	              height: 10px;
	              background-color: ${portal.type === 'object' ? '#00ff00' : '#ff0000'};
	              border: 2px solid white;
	              border-radius: 50%;
	              transform: translate(-50%, -50%);
	              z-index: 1500;
	              pointer-events: none;
	              box-shadow: 0 0 5px rgba(0,0,0,0.5);
	          `;

			// 라벨 추가
			const label = document.createElement('div');
			label.style.cssText = `
	              position: absolute;
	              top: 15px;
	              left: 50%;
	              transform: translateX(-50%);
	              background: rgba(0,0,0,0.8);
	              color: white;
	              padding: 2px 6px;
	              border-radius: 3px;
	              font-size: 10px;
	              white-space: nowrap;
	              font-family: monospace;
	          `;
			label.textContent = `${portal.id}(${portal.x},${portal.y})`;
			marker.appendChild(label);

			// CSS 오프셋 적용된 위치 계산
			const cssOffset = this.getPortalCSSOffset(portal.id);
			const adjustedX = portal.x + cssOffset.x;
			const adjustedY = portal.y + cssOffset.y;

			// 화면 좌표로 변환
			const screenX = adjustedX * this.scale + this.posX;
			const screenY = adjustedY * this.scale + this.posY;

			marker.style.left = screenX + 'px';
			marker.style.top = screenY + 'px';

			// 맵 컨테이너에 추가
			const mapContainer = document.getElementById('mapContainer');
			if (mapContainer) {
				mapContainer.appendChild(marker);
			}

			this.simpleMarkers.push({
				element: marker,
				portalId: portal.id,
				originalX: portal.x,
				originalY: portal.y,
				offsetX: cssOffset.x,
				offsetY: cssOffset.y
			});

			console.log(`📍 ${portal.id}: 원본(${portal.x},${portal.y}) + 오프셋(${cssOffset.x},${cssOffset.y}) = 최종(${adjustedX},${adjustedY})`);
		});

		this.markersVisible = true;
		console.log(`✅ ${this.simpleMarkers.length}개 중심점 마커 생성 완료`);
	}
	updateSimpleMarkers() {
		if (!this.markersVisible || this.simpleMarkers.length === 0) return;

		this.simpleMarkers.forEach(marker => {
			// CSS 오프셋 적용된 위치
			const adjustedX = marker.originalX + marker.offsetX;
			const adjustedY = marker.originalY + marker.offsetY;

			// 화면 좌표로 변환
			const screenX = adjustedX * this.scale + this.posX;
			const screenY = adjustedY * this.scale + this.posY;

			marker.element.style.left = screenX + 'px';
			marker.element.style.top = screenY + 'px';
			marker.element.style.transform = `translate(-50%, -50%) scale(${Math.max(0.5, this.scale)})`;
		});
	}
	// ===== 포털 중심점 마커 숨기기 =====
	hidePortalCenters() {
		this.simpleMarkers.forEach(marker => {
			if (marker.element && marker.element.parentNode) {
				marker.element.parentNode.removeChild(marker.element);
			}
		});
		this.simpleMarkers = [];
		this.markersVisible = false;
		console.log('🙈 중심점 마커 숨김');
	}
	debugPortalOffsets() {
		console.log('🎯 === 포털 오프셋 정보 ===');
		this.portalCollisionAreas.forEach((portal) => {
			const cssOffset = this.getPortalCSSOffset(portal.id);
			const adjustedX = portal.x + cssOffset.x;
			const adjustedY = portal.y + cssOffset.y;

			console.log(`${portal.id}:`);
			console.log(`  원본 위치: (${portal.x}, ${portal.y})`);
			console.log(`  CSS 오프셋: (${cssOffset.x}, ${cssOffset.y})`);
			console.log(`  최종 위치: (${adjustedX}, ${adjustedY})`);
			console.log(`  타입: ${portal.type}, 반경: ${portal.collisionRadius}`);
			console.log('---');
		});
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
