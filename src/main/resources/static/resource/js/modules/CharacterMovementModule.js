
export class CharacterMovementModule {
	constructor(gameClient) {
		this.gameClient = gameClient;
		this.keys = {};
		this.speed = gameClient.getConfig('MOVEMENT_SPEED') || 0.2;
		this.lastPositionSent = null;
		this.positionUpdateThrottle = 100; // 50ms마다 위치 업데이트
		this.lastPositionUpdate = 0;

		console.log('📦 CharacterMovementModule 생성됨');
	}

	// ===== 모듈 초기화 =====
	async initialize() {
		try {
			console.log('🎮 캐릭터 이동 모듈 초기화');

			// 키보드 컨트롤 설정
			this.setupKeyboardControls();

			// 전역 변수 설정 (기존 코드와의 호환성)
			if (typeof window !== 'undefined') {
				window.mapDragEnabled = true;
			}

			console.log('✅ 캐릭터 이동 모듈 초기화 완료');

		} catch (error) {
			console.error('❌ 캐릭터 이동 모듈 초기화 실패:', error);
			throw error;
		}
	}
	// ✅ 애니메이션 액션 설정 (RenderModule에서 호출)
	setAnimationActions(walkAction) {
		this.walkAction = walkAction;
		console.log('🎬 MovementModule 애니메이션 액션 설정 완료');
	}
	// ===== 키보드 컨트롤 설정 =====
	setupKeyboardControls() {
		const canvas = this.gameClient.getCanvas();

		if (!canvas) {
			console.error('캔버스를 찾을 수 없습니다.');
			return;
		}

		// 캔버스 포커스 설정
		canvas.style.pointerEvents = 'auto';
		canvas.tabIndex = 0;

		// 캐릭터 모드 표시 함수
		const showCharacterMode = () => {
			canvas.focus();
			if (typeof window !== 'undefined') {
				window.mapDragEnabled = false;
			}
		};

		// 맵 모드로 전환
		const showMapMode = () => {
			canvas.blur();
			if (typeof window !== 'undefined') {
				window.mapDragEnabled = true;
			}
		};

		// 캔버스 클릭 시 포커스
		canvas.addEventListener('click', () => {
			showCharacterMode();
		});

		// 캔버스 밖 클릭 시 포커스 해제 (채팅 제외)
		document.addEventListener('click', (e) => {
			if (!canvas.contains(e.target) && !e.target.closest('.player-chat-container')) {
				showMapMode();
			}
		});

		// 전역 키보드 이벤트 - 방향키나 WASD 입력 시 자동으로 캐릭터 모드 활성화
		document.addEventListener('keydown', (e) => {
			const key = e.key; // 🔥 대소문자 그대로!
			if (document.activeElement.id === 'chatInput') return;
			const movementKeys = ['w', 'a', 's', 'd', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
			if (movementKeys.includes(key)) {
				this.keys[key] = true;
				e.preventDefault();
			}
		});

		document.addEventListener('keyup', (e) => {
			const key = e.key;
			const movementKeys = ['w', 'a', 's', 'd', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
			if (movementKeys.includes(key)) {
				this.keys[key] = false;
				e.preventDefault();
				console.log('🔑 키 입력됨:', e.key);
			}
		});

		// 캔버스별 키보드 이벤트 (추가 제어를 위해 유지)
		canvas.addEventListener('keydown', (e) => {
			this.keys[e.key.toLowerCase()] = true;
			e.preventDefault();
		});

		canvas.addEventListener('keyup', (e) => {
			this.keys[e.key.toLowerCase()] = false;
			e.preventDefault();
		});

		// 초기 포커스
		setTimeout(() => canvas.focus(), 1000);

		console.log('✅ 키보드 컨트롤 설정 완료');
	}
	updateMovement() {
		if (!this.myCharacter) {
			const characterRenderModule = this.gameClient.getCharacterRenderModule();
			this.myCharacter = characterRenderModule?.getMyCharacter();

			if (!this.myCharacter) {
				console.warn('🚨 myCharacter가 아직 정의되지 않았습니다!');
				return;
			} else {
				console.log('✅ myCharacter 할당 성공:', this.myCharacter);
				this.initializeCharacterPosition();
			}
		}

		if (!this.keys) return;


		// 애니메이션 업데이트
		if (this.mixer && this.clock) {
			const delta = this.clock.getDelta();
			this.mixer.update(delta);
		}

		// 내 캐릭터 이동 처리
		if (this.myCharacter && this.keys) {
			// 🔥 이동 입력 감지 및 새 위치 계산
			let deltaX = 0;
			let deltaZ = 0;
			let moved = false;

			if (this.keys['ArrowUp'] || this.keys['w'] || this.keys['W']) {
				deltaZ -= this.speed;
				moved = true;
			}
			if (this.keys['ArrowDown'] || this.keys['s'] || this.keys['S']) {
				deltaZ += this.speed;
				moved = true;
			}
			if (this.keys['ArrowLeft'] || this.keys['a'] || this.keys['A']) {
				deltaX -= this.speed;
				moved = true;
			}
			if (this.keys['ArrowRight'] || this.keys['d'] || this.keys['D']) {
				deltaX += this.speed;
				moved = true;
			}
			if (moved) {
				// 🔥 새 위치 계산
				const newPosition = {
					x: this.myCharacter.position.x + deltaX,
					y: 0,
					z: this.myCharacter.position.z + deltaZ
				};

				// 🔥 이동 가능 여부 체크
				const mapModule = this.gameClient.getMapModule();
				const isAllowed = mapModule.isMovementAllowed(newPosition);


				if (isAllowed) {
					// ✅ 이동 허용 - 위치 업데이트
					this.myCharacter.position.set(newPosition.x, newPosition.y, newPosition.z);

					// ✅ 이동 방향에 따라 회전
					if (deltaX !== 0 || deltaZ !== 0) {
						const angle = Math.atan2(deltaX, deltaZ);
						this.myCharacter.rotation.y = angle;
					}

					// ✅ 걷기 애니메이션 시작
					if (this.walkAction && !this.walkAction.isRunning()) {
						this.walkAction.reset().play();
						// 🆕 내 캐릭터의 파츠 애니메이션도 시작
						const characterRenderModule = this.gameClient.getCharacterRenderModule();
						if (characterRenderModule && this.myCharacter) {
							let partCount = 0;
							this.myCharacter.traverse(child => {
								if (child.userData?.walkAction && !child.userData.walkAction.isRunning()) {
									child.userData.walkAction.reset().play();
									partCount++;
								}
							});
						}

					}

					// ✅ 서버 전송 및 맵 업데이트
					this.sendPositionUpdateThrottled();
					this.updateMapToFollowCharacter(this.myCharacter);

				} else {
					// ❌ 이동 차단
					console.log('❌ 마스킹 영역: 이동 불가');

					// 애니메이션 정지 (이동하지 않으므로)
					if (this.walkAction && this.walkAction.isRunning()) {
						this.walkAction.stop();
						if (this.myCharacter) {
							this.myCharacter.traverse(child => {
								if (child.userData?.walkAction && child.userData.walkAction.isRunning()) {
									child.userData.walkAction.stop();
								}
							});
						}
					}
				}

			} else {
				// 입력이 없으면 애니메이션 정지
				if (this.walkAction && this.walkAction.isRunning()) {
					this.walkAction.stop();
					if (this.myCharacter) {
						this.myCharacter.traverse(child => {
							if (child.userData?.walkAction && child.userData.walkAction.isRunning()) {
								child.userData.walkAction.stop();
							}
						});
					}
				}
			}

			// 포털 충돌 검사 (현재 위치 기준)
		
			this.checkPortalCollision(this.myCharacter);
		}
	}

	initializeCharacterPosition() {
		const config = this.gameClient.getCharacterConfig();

		if (!this.myCharacter) {
			console.warn('⚠️ myCharacter가 없어서 초기 위치 설정을 건너뜁니다.');
			return;
		}

		// 2D 맵 좌표를 3D 월드 좌표로 변환
		const worldPos = this.imageToWorldCoordinates(
			config.MAP_POSITION.x,
			config.MAP_POSITION.y
		);

		// 캐릭터를 계산된 위치로 배치
		this.myCharacter.position.set(worldPos.x, 0, worldPos.z);
		console.log(`🎯 캐릭터 초기 위치 설정: 3D(${worldPos.x}, 0, ${worldPos.z}) <- 2D(${config.MAP_POSITION.x}, ${config.MAP_POSITION.y})`);

	}


	// ===== 캐릭터를 따라 맵 중심 이동 =====
	updateMapToFollowCharacter(character) {
		const mapModule = this.gameClient.getMapModule();
		if (!mapModule) return;

		// ✅ MapModule 메서드 사용
		const currentTransform = mapModule.getTransform();
		const imageCoord = this.worldToImageCoordinates(
			character.position.x,
			character.position.z
		);

		const screenCenterX = window.innerWidth / 2;
		const screenCenterY = window.innerHeight / 2;

		const newPosX = screenCenterX - (imageCoord.x * currentTransform.scale);
		const newPosY = screenCenterY - (imageCoord.y * currentTransform.scale);

		// ✅ MapModule 메서드로 이동
		mapModule.smoothMoveTo(newPosX, newPosY, 0.05);
	}

	setMapDragEnabled(enabled) {
		const mapModule = this.gameClient.getMapModule();
		if (mapModule) {
			mapModule.setDragEnabled(enabled);
		}
	}

	// ===== 3D 좌표를 배경 이미지 좌표로 변환 =====
	worldToImageCoordinates(worldX, worldZ) {
		const mapConfig = this.gameClient.getMapConfig();
		const scaleRatio = mapConfig.IMAGE_WIDTH / 100; // 3D 100 단위를 이미지 픽셀로 매핑
		const imageCenterX = mapConfig.IMAGE_WIDTH / 2;
		const imageCenterY = mapConfig.IMAGE_HEIGHT / 2;

		return {
			x: worldX * scaleRatio + imageCenterX,
			y: worldZ * scaleRatio + imageCenterY
		};
	}

	// ===== 배경 이미지 좌표를 3D 좌표로 변환 =====
	imageToWorldCoordinates(imageX, imageY) {
		const mapConfig = this.gameClient.getMapConfig();
		const scaleRatio = 100 / mapConfig.IMAGE_WIDTH; // 이미지 픽셀을 3D 100 단위로 매핑
		const imageCenterX = mapConfig.IMAGE_WIDTH / 2;
		const imageCenterY = mapConfig.IMAGE_HEIGHT / 2;

		return {
			x: (imageX - imageCenterX) * scaleRatio,
			z: (imageY - imageCenterY) * scaleRatio
		};
	}

	// ===== 위치 업데이트 전송 (스로틀링 적용) =====
	sendPositionUpdateThrottled() {
		const now = Date.now();
		if (now - this.lastPositionUpdate < this.positionUpdateThrottle) {
			return;
		}

		this.lastPositionUpdate = now;
		this.sendPositionUpdate();
	}

	// ===== 위치 업데이트 전송 =====
	sendPositionUpdate() {
		const webSocketModule = this.gameClient.getWebSocketChatModule();
		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		const myCharacter = characterRenderModule?.getMyCharacter();

		if (!webSocketModule || !myCharacter) {
			return;
		}

		const socket = webSocketModule.getSocket();
		if (!socket || socket.readyState !== WebSocket.OPEN) {
			return;
		}

		const moveMessage = {
			type: 'player-move',
			position: {
				x: myCharacter.position.x,
				y: myCharacter.position.y,
				z: myCharacter.position.z
			},
			rotation: {  
				x: myCharacter.rotation.x,
				y: myCharacter.rotation.y,
				z: myCharacter.rotation.z
			}
		};

		try {
			socket.send(JSON.stringify(moveMessage));
		} catch (error) {
			console.error('위치 업데이트 전송 실패:', error);
		}
	}

	// ===== 포털 충돌 검사 =====
	checkPortalCollision(character) {
		const mapModule = this.gameClient.getMapModule();
		if (!mapModule) return;

		const characterPos = character.position;
		// ✅ MapModule의 실제 메서드 사용
		const targetMap = mapModule.checkPortalCollision(characterPos);
		if (targetMap) {
			console.log(targetMap);
			this.enterPortal(targetMap);
		}
	}
	// ===== 이동 가능 여부 검사 =====
	isMovementAllowed(newPosition) {
		const mapModule = this.gameClient.getMapModule();
		if (!mapModule) return true;

		return mapModule.isMovementAllowed(newPosition);
	}
	// ===== 포털 진입 처리 =====
	enterPortal(targetMap) {
		
		const mapModule = this.gameClient.getMapModule();
		if (!mapModule) return;

		// MapModule의 포털 진입 메서드 호출
		mapModule.handlePortalEntry(targetMap);
	}

	// ===== 이동 속도 설정 =====
	setSpeed(speed) {
		this.speed = speed;
		console.log('이동 속도 변경:', speed);
	}

	// ===== 이동 속도 반환 =====
	getSpeed() {
		return this.speed;
	}

	// ===== 키 상태 반환 =====
	getKeys() {
		return this.keys;
	}
	// ✅ setMyCharacter 메서드 추가
	setMyCharacter(character) {
		this.myCharacter = character;
		console.log('🎯 MovementModule: myCharacter 설정됨', character);
	}


	// ===== 리소스 정리 =====
	dispose() {
		console.log('🧹 캐릭터 이동 모듈 정리');

		// 키 상태 초기화
		this.keys = {};
		this.isCharacterMoving = false;

		// 이벤트 리스너 제거는 브라우저가 자동으로 처리
		console.log('✅ 캐릭터 이동 모듈 정리 완료');
	}
}