import { ThreeInit } from './ThreeInit.js';
import { MapModule } from '../modules/MapModule.js';
import { CharacterRenderModule } from '../modules/CharacterRenderModule.js';
import { CharacterMovementModule } from '../modules/CharacterMovementModule.js';
import { WebsocketChatModule } from '../modules/WebsocketChatModule.js';

export class GameClient {
	constructor() {
		// ===== 게임 설정 상수들 =====
		this.CONFIG = {
			// 서버 설정
			WEBSOCKET_URL: 'ws://localhost:8081/game',

			// 게임플레이 설정
			MOVEMENT_SPEED: 0.1,

			// 맵 설정
			MIN_SCALE: 0.5,
			MAX_SCALE: 2.0,
			ZOOM_STEP: 0.1,
			IMAGE_WIDTH: 5055,
			IMAGE_HEIGHT: 3904,

			// 캐릭터 설정
			CHARACTER: {
				SCALE: 1.6,
				DEFAULT_SKIN_COLOR: 0xffe0bd,
				COLLISION_RADIUS: 2,
				MAP_POSITION: { x: 2400, y: 1800 }
			},

			// 포털 위치 설정
			PORTAL_POSITIONS: [
				{ id: 'portal_1', x: 2200, y: 900, targetMap: '/angerMap' },
				{ id: 'portal_2', x: 2978, y: 1150, targetMap: '/zenMap' },
				{ id: 'portal_3', x: 2795, y: 1350, targetMap: '/happyMap' },
				{ id: 'portal_4', x: 1875, y: 1200, targetMap: '/sadMap' },
				{ id: 'portal_5', x: 1538, y: 1370, targetMap: '/anxietyMap' },
				{ id: 'object', x: 2260, y: 1550, type: 'fountain' }
			]
		};

		// ===== 게임 데이터 =====
		this.player = null;
		this.isInitialized = false;
		this.isConnected = false;
		this.isRunning = false;

		// ===== 통합 애니메이션 관리 =====
		this.animationLoopActive = false;
		this.globalClock = new THREE.Clock();

		// ===== 코어 시스템 =====
		this.ThreeInit = null;

		// ===== 게임 모듈들 =====
		this.mapModule = null;
		this.characterRenderModule = null;
		this.characterMovementModule = null;
		this.websocketChatModule = null;
	}

	// ===== 게임 클라이언트 초기화 =====
	async initialize(player,currentMapName) {
		try {
			console.log('=== 게임 클라이언트 초기화 시작 ===');
			console.log('플레이어 정보:', player);
			console.log('맵 정보:', currentMapName);
			// 플레이어 정보 저장
			this.player = player;
			this.currentMapName = currentMapName;
			// 1. ThreeJS 코어 초기화
			console.log('1. ThreeJS 코어 초기화');
			this.threeInit = new ThreeInit();

			if (!this.threeInit.isReady()) {
				throw new Error('ThreeJS 코어 초기화 실패');
			}

			// 2. 게임 모듈들 생성
			console.log('2. 게임 모듈들 생성');
			this.createModules();

			// 3. 각 모듈 초기화
			console.log('3. 각 모듈 초기화');
			await this.initializeModules(currentMapName);

			this.isInitialized = true;
			console.log('=== 게임 클라이언트 초기화 완료 ===');

		} catch (error) {
			console.error('게임 클라이언트 초기화 실패:', error);
			this.cleanup();
			throw error;
		}
	}

	// ===== 모듈 생성 =====
	createModules() {
		try {
			// 각 모듈에 GameClient 인스턴스를 전달
			this.mapModule = new MapModule(this);
			this.characterRenderModule = new CharacterRenderModule(this);
			this.characterMovementModule = new CharacterMovementModule(this);
			this.websocketChatModule = new WebsocketChatModule(this);

			console.log('모듈 생성 완료');
		} catch (error) {
			console.error('모듈 생성 실패:', error);
			throw error;
		}
	}

	// ===== 모듈 초기화 =====
	async initializeModules(currentMapName) {
		try {
			// 맵 모듈 초기화 (포털, 맵 컨트롤)
			if (this.mapModule.initialize) {
				await this.mapModule.initialize(currentMapName);
			}

			// 캐릭터 이동 모듈 초기화 (키보드 이벤트)
			if (this.characterMovementModule.initialize) {
				await this.characterMovementModule.initialize();
			}

			// 웹소켓 채팅 모듈은 connect 시점에 초기화

			console.log('모듈 초기화 완료');
		} catch (error) {
			console.error('모듈 초기화 실패:', error);
			throw error;
		}
	}

	// ===== 서버 연결 =====
	async connect() {
		try {
			console.log('=== 서버 연결 시작 ===');

			if (!this.isInitialized) {
				throw new Error('게임 클라이언트가 초기화되지 않았습니다.');
			}

			// 웹소켓 연결
			await this.websocketChatModule.connect();

			// 맵 입장 요청
			await this.websocketChatModule.joinMap(this.player);

			this.isConnected = true;
			console.log('=== 서버 연결 완료 ===');

		} catch (error) {
			console.error('서버 연결 실패:', error);
			throw error;
		}
	}
	async connect() {
	 try {
		 console.log('=== 서버 연결 시작 (테스트 모드) ===');
		 
		 if (!this.isInitialized) {
			 throw new Error('게임 클라이언트가 초기화되지 않았습니다.');
		 }
		 
		 // 🚫 테스트용: 웹소켓 연결 비활성화
		 console.log('⚠️ 테스트 모드: 웹소켓 연결 생략');
		 
		 
		 // 웹소켓 연결
		 await this.websocketChatModule.connect();
		 
		 // 맵 입장 요청
		 await this.websocketChatModule.joinMap(this.player);
		 
		 
		 this.isConnected = true;
		 console.log('=== 서버 연결 완료 (테스트 모드) ===');
		 
	 } catch (error) {
		 console.error('서버 연결 실패:', error);
		 throw error;
	 }
 }
	// ===== 게임 루프 시작 =====
	async startGame() {
		if (!this.isInitialized || !this.isConnected) {
			console.error('게임을 시작할 수 없습니다. 초기화 또는 연결 상태를 확인하세요.');
			return;
		}

		// 🚫 테스트용: 캐릭터 렌더링 모듈 초기화 (웹소켓 없이)
		if (this.characterRenderModule && this.characterRenderModule.initialize) {
			await this.characterRenderModule.initialize();
		}
		
		// ✅ (추가) 맵 마스킹 설정: happyMap
		if (this.mapModule && this.mapModule.initializeMaskingAreas) {
			this.mapModule.initializeMaskingAreas('happyMap');
			console.log('🎈 happyMap 마스킹 적용 완료');
		}

		// ✅ 캐릭터 렌더링 완료될 때까지 기다리기
		await this.waitForMyCharacter();

		this.isRunning = true;
		this.startAnimationLoop();
	}

	async waitForMyCharacter() {
		return new Promise((resolve) => {
			const check = () => {
				const myChar = this.characterRenderModule.getMyCharacter();
				if (myChar) {
					console.log('✅ myCharacter 로딩 확인 완료');
					resolve();
				} else {
					console.log('⏳ myCharacter 로딩 대기 중...');
					setTimeout(check, 100); // 100ms 단위로 재확인
				}
			};
			check();
		});
	}


	// ===== 애니메이션 루프 =====
	startAnimationLoop() {
		if (this.animationLoopActive) {
			console.log('⚠️ 애니메이션 루프가 이미 실행 중입니다.');
			return;
		}
		console.log('애니메이션 루프 시작');
		this.animationLoopActive = true;
		const animate = () => {
			if (!this.isRunning || !this.animationLoopActive) {
				console.log('🛑 애니메이션 루프 중지');
				this.animationLoopActive = false;
				return;
			};

			requestAnimationFrame(animate);

			try {
				const delta = this.globalClock.getDelta();
				if (this.isRunning) {

					if (this.characterRenderModule) {
						this.characterRenderModule.updateAllPlayersAnimation(delta);
					}
					if (this.characterMovementModule?.updateMovement) {
						this.characterMovementModule.updateMovement();
					}
				
					if (this.mapModule?.updatePortals) {
						this.mapModule.updatePortals();
					}
					if (this.mapModule?.updateCharacterDOM) {
						this.mapModule.updateCharacterDOM();
					}
				}
				// Three.js 렌더링
				if (this.threeInit) {
					this.threeInit.render();
				}
			} catch (error) {
				console.error('애니메이션 루프 오류:', error);
			}
		};

		animate();
	}

	// ===== 게임 일시정지/재개 =====
	stopAnimationLoop() {
		this.animationLoopActive = false;
		console.log('🛑 애니메이션 루프 중지 요청');
	}
	pauseGame() {
		this.isRunning = false;
		console.log('게임 일시정지');
	}

	resumeGame() {
		if (this.isInitialized && this.isConnected) {
			this.isRunning = true;
			// 애니메이션 루프가 중지되었다면 재시작
			if (!this.animationLoopActive) {
				this.startAnimationLoop();
			}
			console.log('게임 재개');
		}
	}

	// ===== 설정값 접근 헬퍼 메서드들 =====
	getConfig(key) {
		return this.CONFIG[key];
	}

	getCharacterConfig() {
		return this.CONFIG.CHARACTER;
	}

	getPortalPositions() {
		return this.CONFIG.PORTAL_POSITIONS;
	}

	getMapConfig() {
		return {
			MIN_SCALE: this.CONFIG.MIN_SCALE,
			MAX_SCALE: this.CONFIG.MAX_SCALE,
			ZOOM_STEP: this.CONFIG.ZOOM_STEP,
			IMAGE_WIDTH: this.CONFIG.IMAGE_WIDTH,
			IMAGE_HEIGHT: this.CONFIG.IMAGE_HEIGHT
		};
	}

	// ===== ThreeJS 관련 접근자 =====
	getThreeInit() {
		return this.threeInit;
	}

	getScene() {
		return this.threeInit?.getScene();
	}

	getCamera() {
		return this.threeInit?.getCamera();
	}

	getRenderer() {
		return this.threeInit?.getRenderer();
	}

	getCanvas() {
		return this.threeInit?.getCanvas();
	}

	createSceneGroup(moduleName) {
		return this.threeInit?.createGroup(moduleName);
	}

	getSceneGroup(moduleName) {
		return this.threeInit?.getGroup(moduleName);
	}

	// ===== 모듈 접근자 =====
	getMapModule() {
		return this.mapModule;
	}

	getCharacterRenderModule() {
		return this.characterRenderModule;
	}

	getCharacterMovementModule() {
		return this.characterMovementModule;
	}

	getWebSocketChatModule() {
		return this.websocketChatModule;
	}

	// ===== 게임 상태 조회 =====
	getGameState() {
		return {
			isInitialized: this.isInitialized,
			isConnected: this.isConnected,
			isRunning: this.isRunning,
			player: this.player,
			threeJsInfo: this.threeInit?.getSceneInfo(),
			performanceInfo: this.threeInit?.getPerformanceInfo()
		};
	}

	// ===== 디버그 메서드들 =====
	enableDebugMode() {
		console.log('=== 디버그 모드 활성화 ===');

		// ThreeJS 디버그 모드
		if (this.threeInit) {
			this.threeInit.enableDebugMode();
		}

		// 게임 상태 로그
		console.log('게임 상태:', this.getGameState());

		// 씬 계층 구조 로그
		if (this.threeInit) {
			this.threeInit.logSceneHierarchy();
		}

		// 전역 디버그 객체 등록
		window.gameDebug = {
			gameClient: this,
			threeInit: this.threeInit,
			modules: {
				map: this.mapModule,
				characterRender: this.characterRenderModule,
				characterMovement: this.characterMovementModule,
				websocketChat: this.websocketChatModule
			}
		};

		console.log('디버그 객체가 window.gameDebug에 등록되었습니다.');
	}

	// ===== 리소스 정리 =====
	cleanup() {
		console.log('=== 게임 클라이언트 정리 시작 ===');

		// 게임 루프 중지
		this.isRunning = false;
		this.stopAnimationLoop();
		// 웹소켓 연결 종료
		if (this.websocketChatModule) {
			this.websocketChatModule.disconnect?.();
		}

		// 모듈들 정리
		if (this.mapModule?.dispose) {
			this.mapModule.dispose();
		}
		if (this.characterRenderModule?.dispose) {
			this.characterRenderModule.dispose();
		}
		if (this.characterMovementModule?.dispose) {
			this.characterMovementModule.dispose();
		}
		if (this.websocketChatModule?.dispose) {
			this.websocketChatModule.dispose();
		}

		// ThreeJS 코어 정리
		if (this.threeInit) {
			this.threeInit.dispose();
		}

		// 상태 초기화
		this.isInitialized = false;
		this.isConnected = false;
		this.isRunning = false;

		console.log('=== 게임 클라이언트 정리 완료 ===');
	}

	// ===== 소멸자 (페이지 언로드 시 호출) =====
	destroy() {
		this.cleanup();
	}
}