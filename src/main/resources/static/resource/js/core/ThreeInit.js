export class ThreeInit {
	constructor(existingCanvas = null) {
		// Three.js 핵심 객체들
		this.scene = null;
		this.camera = null;
		this.renderer = null;
		this.sceneGroups = new Map();
		this.existingCanvas = existingCanvas;
		// 렌더링 상태
		this.isInitialized = false;

		this.initThreeJS();
	}

	// ===== Three.js 초기화 =====
	initThreeJS() {
		console.log('ThreeJSCore 초기화 시작');

		try {
			// 씬 생성
			this.scene = new THREE.Scene();
			// 카메라 설정 (공통 메서드 사용)
			this.camera = this.createCamera();

			// 렌더러 설정 (공통 메서드 사용)
			this.renderer = this.createRenderer();

			// DOM에 캔버스 추가
			this.setupCanvas();

			// 조명 설정
			this.setupLighting()

			// 이벤트 리스너 등록
			this.setupEventListeners();

			this.isInitialized = true;
			console.log('ThreeJSCore 초기화 완료');

		} catch (error) {
			console.error('ThreeJSCore 초기화 실패:', error);
			throw error;
		}
	}

	// ===== 캔버스 설정 =====
	setupCanvas() {
		if (this.existingCanvas) {
			// 전달받은 캔버스 사용 (이미 DOM에 추가됨)
			console.log('✅ 기존 캔버스 사용:', this.existingCanvas.id);
		} else {
			const character3D = document.getElementById('character3D');
			if (!character3D) {
				console.warn('character3D 컨테이너를 찾을 수 없습니다.');
				return;
			}
			/*		character3D.innerHTML = '';*/
			character3D.appendChild(this.renderer.domElement);

			this.renderer.domElement.style.zIndex = '9998';
			this.renderer.domElement.style.position = 'relative';
		}
	}
	// ===== 공통 렌더러 설정 메서드 =====
	createRenderer() {
		const rendererConfig = {
			antialias: true,
			alpha: true,
			powerPreference: "high-performance"
		};
		if (this.existingCanvas) {
			rendererConfig.canvas = this.existingCanvas;
			console.log('✅ 기존 캔버스 사용');
		} else {
			console.log('⚠️ 캔버스 없음, WebGLRenderer가 자동 생성');
		}
		const renderer = new THREE.WebGLRenderer(rendererConfig);
		renderer.setSize(500, 500);
		renderer.setClearColor(0x000000, 0);
		
		// 그림자 설정
		renderer.shadowMap.enabled = true;
		renderer.shadowMap.type = THREE.BasicShadowMap;
		// 색상 공간 설정
		if (renderer.outputColorSpace !== undefined) {
			renderer.outputColorSpace = THREE.SRGBColorSpace;
		} else if (renderer.outputEncoding !== undefined) {
			renderer.outputEncoding = THREE.sRGBEncoding;
		}
		return renderer;
	}

	// ===== 공통 카메라 설정 메서드 =====
	createCamera() {
		const camera = new THREE.OrthographicCamera(
			-35, 35,  // left, right
			35, -35,  // top, bottom
			0.1, 1000 // near, far
		);
		camera.position.set(0, 0, 30);
		camera.lookAt(0, 0, 0);

		return camera;
	}
	// ===== 조명 설정 =====
	setupLighting() {
		// 환경광 (전체적으로 부드러운 조명)
		const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
		this.scene.add(ambientLight);

		// 방향광 (태양광 같은 효과)
		const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
		directionalLight.position.set(10, 50, 20);
		directionalLight.castShadow = true;
		this.scene.add(directionalLight);

	}

	// ===== 이벤트 리스너 설정 =====
	setupEventListeners() {

		// 페이지 언로드 시 정리
		window.addEventListener('beforeunload', () => this.dispose());
	}

	// ===== 씬 그룹 관리 =====
	createGroup(moduleName) {
		if (!this.isInitialized) {
			console.error('ThreeJSCore가 초기화되지 않았습니다.');
			return null;
		}

		const group = new THREE.Group();
		group.name = moduleName;
		this.scene.add(group);
		this.sceneGroups.set(moduleName, group);

		console.log(`씬 그룹 생성: ${moduleName}`);
		return group;
	}

	getGroup(moduleName) {
		return this.sceneGroups.get(moduleName);
	}

	removeGroup(moduleName) {
		const group = this.sceneGroups.get(moduleName);
		if (group) {
			this.scene.remove(group);
			this.sceneGroups.delete(moduleName);
			console.log(`씬 그룹 제거: ${moduleName}`);
		}
	}

	// ===== 렌더링 메서드 =====
	render() {
		if (!this.isInitialized) return;

		try {
			this.renderer.render(this.scene, this.camera);
		} catch (error) {
			console.error('렌더링 오류:', error);
		}
	}

	// ===== 카메라 제어 =====
	setCameraPosition(x, y, z) {
		if (this.camera) {
			this.camera.position.set(x, y, z);
		}
	}

	setCameraLookAt(x, y, z) {
		if (this.camera) {
			this.camera.lookAt(x, y, z);
		}
	}

	updateCamera(position, lookAt) {
		if (this.camera) {
			if (position) {
				this.camera.position.set(position.x, position.y, position.z);
			}
			if (lookAt) {
				this.camera.lookAt(lookAt.x, lookAt.y, lookAt.z);
			}
		}
	}

	// ===== 접근자 메서드들 =====
	getScene() {
		return this.scene;
	}

	getCamera() {
		return this.camera;
	}

	getRenderer() {
		return this.renderer;
	}

	getCanvas() {
		return this.renderer ? this.renderer.domElement : null;
	}

	isReady() {
		return this.isInitialized;
	}

	// ===== 씬 정보 조회 =====
	getSceneInfo() {
		return {
			groups: Array.from(this.sceneGroups.keys()),
			totalObjects: this.scene.children.length,
			isInitialized: this.isInitialized
		};
	}

	// ===== 성능 정보 조회 =====
	getPerformanceInfo() {
		if (!this.renderer) return null;

		const info = this.renderer.info;
		return {
			geometries: info.memory.geometries,
			textures: info.memory.textures,
			drawCalls: info.render.calls,
			triangles: info.render.triangles,
			points: info.render.points
		};
	}

	enableDebugMode() {
		console.log('🔍 디버그 모드 활성화');

		try {
/*
			// 축 헬퍼 추가
			const axesHelper = new THREE.AxesHelper(5);
			this.scene.add(axesHelper);
*/
			// 그리드 헬퍼 추가
			/*      const gridHelper = new THREE.GridHelper(50, 50);
				  this.scene.add(gridHelper);
				  */
			console.log('✅ 디버그 헬퍼 활성화 완료');

		} catch (error) {
			console.warn('⚠️ 일부 디버그 헬퍼 로드 실패:', error);
		}
	}

	logSceneHierarchy() {
		console.log('=== 씬 계층 구조 ===');

		// ✅ 직접 계산
		this.scene.traverse((object) => {
			let depth = 0;
			let parent = object.parent;
			while (parent && parent !== this.scene) {
				depth++;
				parent = parent.parent;
			}

			const indent = '  '.repeat(depth);
			console.log(`${indent}${object.type}: ${object.name || 'unnamed'}`);
		});
	}

	// ===== 리소스 정리 =====
	dispose() {
		console.log('ThreeJSCore 리소스 정리 시작');

		// 씬 그룹들 정리
		this.sceneGroups.forEach((group, name) => {
			this.scene.remove(group);
			console.log(`씬 그룹 정리: ${name}`);
		});
		this.sceneGroups.clear();

		// 렌더러 정리
		if (this.renderer) {
			this.renderer.dispose();
			const canvas = this.renderer.domElement;
			if (canvas && canvas.parentNode) {
				canvas.parentNode.removeChild(canvas);
			}
		}

		// 이벤트 리스너 제거
		window.removeEventListener('resize', this.onWindowResize);
		window.removeEventListener('beforeunload', this.dispose);

		this.isInitialized = false;
		console.log('ThreeJSCore 리소스 정리 완료');
	}
}