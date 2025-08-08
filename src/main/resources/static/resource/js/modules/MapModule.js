
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
				[1240.54, 0.00], [1471.04, 18.50], [1634.11, 55.51], [1781.67, 107.52],
				  [1910.74, 178.56], [1981.78, 227.59], [2064.90, 335.19], [2101.97, 433.82],
				  [2083.49, 511.11], [2043.46, 600.20], [1957.36, 689.84], [1849.29, 766.40],
				  [1658.66, 830.97], [1511.13, 870.98], [1268.04, 892.50], [1031.40, 892.49],
				  [828.40, 852.99], [637.84, 787.97], [468.25, 689.93], [379.11, 578.81],
				  [360.51, 471.08], [379.01, 387.89], [412.84, 308.25], [1.30, 126.95],
				  [99.66, 37.12], [548.39, 196.93], [569.67, 178.62], [619.26, 154.05],
				  [735.74, 83.07], [871.33, 37.02], [1086.42, 0.00], [1240.54, 0.00], // 경로 닫힘

				  // 🔸 구멍 (반시계 방향)
				  [1071.64, 203.98], [1323.42, 179.50], [1470.74, 228.43], [1556.58, 308.29],
				  [1590.45, 387.98], [1532.12, 510.62], [1390.86, 578.01], [1213.01, 599.49],
				  [1086.61, 578.01], [988.70, 550.53], [896.38, 492.14], [853.50, 335.71],
				  [945.76, 246.93], [1071.64, 203.98] // 경로 닫힘
			];
			this.restrictedEllipse = {
				centerX: 0,  // 중심 위치 (X)
				centerY: -220,  // 중심 위치 (Y)
				radiusX: 350,
				radiusY: 200
			};
			this.maskingOffsets = { offsetX: -170, offsetY: -150 };

		} else if (mapName === 'sadMap') {
			this.maskingPolygon = [
				[64.5, 671.5], [1.0, 700.0], [103.5, 792.5], [147.0, 881.0],
				[197.0, 941.5], [246.0, 980.0], [304.5, 1015.5], [316.0, 1034.0],
				[246.0, 1087.5], [224.0, 1034.0], [180.5, 1015.5], [103.5, 1087.5],
				[333.0, 1184.5], [509.0, 1106.0], [479.0, 1059.0], [520.5, 1000.0],
				[584.5, 1025.5], [616.0, 1015.5], [663.0, 1034.0], [901.0, 965.0],
				[1109.0, 1059.0], [1203.0, 1034.0], [1142.5, 965.0], [998.5, 921.5],
				[1348.5, 718.5], [1387.5, 643.0], [1397.5, 593.0], [1360.5, 504.0],
				[1313.5, 417.0], [968.0, 231.0], [921.5, 184.0], [857.5, 130.0],
				[799.0, 95.0], [789.0, 71.5], [732.0, 23.0], [675.0, 1.0],
				[633.0, 23.0], [655.0, 39.5], [683.5, 41.5], [717.0, 71.5],
				[743.5, 145.5], [760.5, 164.0], [807.5, 215.5], [825.5, 262.5],
				[1167.5, 437.0], [1183.0, 465.5], [1203.0, 519.0], [1213.0, 611.5],
				[1167.5, 744.0], [705.0, 965.0], [663.0, 953.5], [633.0, 899.5],
				[509.0, 881.0], [467.0, 899.5], [457.0, 921.5], [445.0, 953.5],
				[433.5, 980.0], [354.5, 953.5], [304.5, 931.5], [271.0, 899.5],
				[235.5, 881.0], [224.0, 847.5], [235.5, 809.0], [197.0, 782.5],
				[180.5, 744.0], [158.5, 718.5], [115.0, 710.0], [64.5, 671.5]
			];
			this.restrictedEllipse = {
				centerX: 0,  // 중심 위치 (X)
				centerY: 0,  // 중심 위치 (Y)
				radiusX: 0,
				radiusY: 0
			};
			this.maskingOffsets = { offsetX: 180, offsetY: -150 };

			} else if (mapName === 'zenMap') {
				this.maskingPolygon = [
					[874.031, 0.500977], [1065.03, 12.501], [1065.05, 12.502], [1065.06, 12.5039],
					  [1254.56, 37.0039], [1254.62, 37.0117], [1254.68, 37.0332], [1437.18, 107.533],
					  [1437.23, 107.554], [1437.28, 107.586], [1623.28, 233.586], [1623.34, 233.626],
					  [1623.38, 233.681], [1712.38, 340.681], [1712.44, 340.75], [1712.47, 340.835],
					  [1747.97, 442.335], [1748.01, 442.434], [1748.0, 442.538], [1739.0, 560.038],
					  [1738.99, 560.118], [1738.96, 560.191], [1687.96, 683.191], [1687.92, 683.301],
					  [1687.83, 683.379], [1559.83, 793.879], [1559.79, 793.912], [1559.74, 793.937],
					  [1405.74, 879.937], [1405.72, 879.95], [1405.69, 879.961], [1272.19, 935.961],
					  [1272.14, 935.981], [1272.09, 935.991], [1038.59, 979.991], [1038.56, 979.997],
					  [1038.53, 979.999], [858.033, 991.999], [857.995, 992.001], [857.956, 991.998],
					  [721.456, 979.998], [721.438, 979.996], [550.938, 958.996], [550.912, 958.993],
					  [550.887, 958.987], [370.387, 916.987], [370.335, 916.975], [370.286, 916.952],
					  [210.786, 841.452], [210.739, 841.43], [210.699, 841.399], [159.699, 802.899],
					  [159.143, 802.479], [159.718, 802.087], [190.724, 780.924], [103.644, 692.351],
					  [103.62, 692.327], [103.601, 692.301], [44.1006, 613.301], [44.0801, 613.273],
					  [44.0635, 613.243], [0.0635, 534.243], [0.0, 534.13], [0.0, 484.5],
					  [54.8623, 484.5], [89.5264, 463.701], [103.457, 321.9], [44.4014, 309.99],
					  [44.0, 309.909], [44.0, 263.76], [44.1875, 263.609], [119.212, 203.59],
					  [119.238, 203.574], [147.738, 186.074], [147.744, 186.07], [147.751, 186.066],
					  [247.79, 128.544], [247.833, 128.528], [407.333, 72.0283], [407.361, 72.0186],
					  [407.392, 72.0117], [564.892, 37.0117], [564.904, 37.0088], [564.917, 37.0068],
					  [710.917, 12.5068], [710.94, 12.5029], [710.963, 12.501], [873.963, 0.500977]
				];
				this.restrictedEllipse = {
					centerX: 0,  // 중심 위치 (X)
					centerY: 0,  // 중심 위치 (Y)
					radiusX: 0,
					radiusY: 0
				};
				this.maskingOffsets = { offsetX: -30, offsetY: -20 };

			} else if (mapName === 'anxietyMap') {
				this.maskingPolygon = [
					[963.0, 1.5], [1.0, 468.0], [201.5, 603.0],
					[245.0, 581.5], [320.0, 644.5], [320.0, 673.5],
					[443.0, 746.0], [1001.5, 1096.5], [1436.5, 806.5],
					[1526.0, 746.0], [1473.0, 688.0], [1543.0, 673.5],
					[1620.5, 688.0], [1956.5, 468.0], [963.0, 1.5]
				];
				this.restrictedEllipse = {
					centerX: 0,  // 중심 위치 (X)
					centerY: 0,  // 중심 위치 (Y)
					radiusX: 0,
					radiusY: 0
				};
				this.maskingOffsets = { offsetX: 100, offsetY: -150 };
			
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

		this.ctx.strokeStyle = 'rgba(255, 0, 0, 0.5)';

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
		if (this.restrictedEllipse) {
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
	}

	// ===== 이동 가능 여부 검사 =====
	isMovementAllowed(position3D) {
		if (!position3D) return true;
		console.log(position3D);
		// 3D 좌표를 2D 이미지 좌표로 변환
		const imageCoord = this.worldToImageCoordinates(position3D.x, position3D.z);
		console.log(imageCoord);
		// 1. 다각형 내부에 있는지 검사 (이동 가능 영역)
		if (this.isPointInPolygon(imageCoord, this.maskingPolygon)) {
			// 2. 타원 내부에 있는지 검사 (이동 불가능 구멍)
			if (this.isPointInEllipse(imageCoord, this.restrictedEllipse)) {
				return false; // 타원 내부는 이동 불가능
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
					collisionRadius: itemData.id === 'object' ? 20 : 40,
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
				this.aiChatbotMapX = 2450;
				this.aiChatbotMapY = 930;
				break;

			case 'anxietyMap':
				this.aiChatbotMapX = 2480;
				this.aiChatbotMapY = 1530;
				break;

			case 'zenMap':
				this.aiChatbotMapX = 2250;
				this.aiChatbotMapY = 1630;
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
			'portal_5': { x: 0, y: 0 }
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
			redirectPath = '/usr/game/chatBot';
			console.log(`🤖 AI 상담 페이지 이동: ${redirectPath}`);

			// AI 챗봇은 즉시 이동 (딜레이 없음)
			window.location.href = redirectPath;
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
