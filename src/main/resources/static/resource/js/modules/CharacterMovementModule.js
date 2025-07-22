
export class CharacterMovementModule {
    constructor(gameClient) {
        this.gameClient = gameClient;
        this.keys = {};
        this.speed = gameClient.getConfig('MOVEMENT_SPEED') || 0.2;
        this.isCharacterMoving = false;
        this.lastPositionSent = null;
        this.positionUpdateThrottle = 50; // 50ms마다 위치 업데이트
        this.lastPositionUpdate = 0;
        
        console.log('📦 CharacterMovementModule 생성됨');
    }
    
    // ===== 모듈 초기화 =====
    async initialize() {
        try {
            console.log('🎮 캐릭터 이동 모듈 초기화');
            
            // 키보드 컨트롤 설정
            this.setupKeyboardControls();
			
			// 카메라 설정 추가!!! 👇
	        this.camera = this.gameClient.getCamera();
	        this.followZOffset = 15;
            
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
    
    // ===== 이동 업데이트 (애니메이션 루프에서 호출) =====
    updateMovement() {
		if (!this.myCharacter) {
		        const characterRenderModule = this.gameClient.getCharacterRenderModule();
		        this.myCharacter = characterRenderModule?.getMyCharacter();

		        // 디버깅 로그
		        if (!this.myCharacter) {
		            console.warn('🚨 myCharacter가 아직 정의되지 않았습니다!');
		            return;
		        } else {
		            console.log('✅ myCharacter 할당 성공:', this.myCharacter);
		        }
		    }

		    if (!this.keys) return;
		
		// ✅ 항상 스케일과 높이 고정 (혹시라도 애니메이션에 의해 덮어씌워질 경우 방지)
        if (this.myCharacter) {
            this.myCharacter.scale.set(0.3, 0.3, 0.3);
            this.myCharacter.position.y = 0;
        }
        
     	// 애니메이션 업데이트
        if (this.mixer && this.clock) {
	        const delta = this.clock.getDelta();
	        this.mixer.update(delta);
	    }

        // 내 캐릭터 이동 처리
        if (this.myCharacter && this.keys) {
            let moved = false;

            if (this.keys['ArrowUp'] || this.keys['w'] || this.keys['W']) {
				console.log('⬆️ 위로 이동!');
                this.myCharacter.position.z -= this.speed;
                moved = true;
            }
            if (this.keys['ArrowDown'] || this.keys['s'] || this.keys['S']) {
                this.myCharacter.position.z += this.speed;
                moved = true;
            }
            if (this.keys['ArrowLeft'] || this.keys['a'] || this.keys['A']) {
                this.myCharacter.position.x -= this.speed;
                moved = true;
            }
            if (this.keys['ArrowRight'] || this.keys['d'] || this.keys['D']) {
                this.myCharacter.position.x += this.speed;
                moved = true;
            }

            // ✅ 걷기 애니메이션 시작/정지 처리
            if (moved) {
			    // ✅ 이동 방향에 따라 회전 (항상 적용해야 함)
			    const moveX = (this.keys['ArrowLeft'] || this.keys['a'] || this.keys['A'] ? 1 : 0)
				            - (this.keys['ArrowRight'] || this.keys['d'] || this.keys['D'] ? 1 : 0);
				
				const moveZ = (this.keys['ArrowUp'] || this.keys['w'] || this.keys['W'] ? 1 : 0)
				            - (this.keys['ArrowDown'] || this.keys['s'] || this.keys['S'] ? 1 : 0);


			
			    if (moveX !== 0 || moveZ !== 0) {
			        const angle = Math.atan2(moveX, moveZ);
			        this.myCharacter.rotation.y = angle + Math.PI; // 💡 쿼터뷰라면 +보정 필요
			    }
			
			    // 걷기 애니메이션 시작
			    if (this.walkAction && !this.walkAction.isRunning()) {
			        this.myCharacter.scale.set(0.3, 0.3, 0.3);
			        this.myCharacter.position.y = 0;
			        this.myCharacter.updateMatrixWorld(true);
			        this.walkAction.reset().play();
			    }
			
			    // 카메라 따라가기
			    this.camera.position.set(
			        this.myCharacter.position.x,
			        this.myCharacter.position.y + 25,
			        this.myCharacter.position.z + this.followZOffset
			    );
			    this.camera.lookAt(this.myCharacter.position);
			
			    this.sendPositionUpdateThrottled();
			    this.updateMapToFollowCharacter(this.myCharacter);
			} else {
			    // 멈추면 애니메이션 정지
			    if (this.walkAction && this.walkAction.isRunning()) {
			        this.walkAction.stop();
			    }
			}

            if (moved) {
                // 카메라 따라가기
                this.camera.position.set(
                    this.myCharacter.position.x,
                    this.myCharacter.position.y + 25,
                    this.myCharacter.position.z + this.followZOffset
                );
                this.camera.lookAt(this.myCharacter.position);

                this.sendPositionUpdateThrottled();
                this.updateMapToFollowCharacter(this.myCharacter);
            }

           // 포털 충돌 검사
            this.checkPortalCollision(this.myCharacter);
        }

    }
	
    // ===== 카메라가 캐릭터를 따라다니도록 업데이트 =====
    updateCameraToFollowCharacter(character) {
        const camera = this.gameClient.getCamera();
        if (!camera) return;
        
        camera.position.set(
            character.position.x,
            character.position.y + 25,
            character.position.z
        );
        camera.lookAt(character.position);
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
    
    // ===== 이동 중인지 확인 =====
    isMoving() {
        return this.isCharacterMoving;
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