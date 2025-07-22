
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
            const movementKeys = ['w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'];
            const key = e.key.toLowerCase();
            
            // 채팅 입력 중이면 무시
            if (document.activeElement.id === 'chatInput') {
                return;
            }
            
            // 이동 키가 눌렸을 때 자동으로 캐릭터 모드 활성화
            if (movementKeys.includes(key)) {
                showCharacterMode();
                this.keys[key] = true;
                e.preventDefault();
            }
        });
        
        document.addEventListener('keyup', (e) => {
            const movementKeys = ['w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'];
            const key = e.key.toLowerCase();
            
            if (movementKeys.includes(key)) {
                this.keys[key] = false;
                e.preventDefault();
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
        const characterRenderModule = this.gameClient.getCharacterRenderModule();
        const myCharacter = characterRenderModule?.getMyCharacter();
        
        if (!myCharacter || !this.keys) {
            return;
        }
        
        let moved = false;
        const originalPosition = {
            x: myCharacter.position.x,
            y: myCharacter.position.y,
            z: myCharacter.position.z
        };
          // 임시 새 위치 계산
        let newPosition = { ...originalPosition };
        // 키 입력에 따른 이동
        if (this.keys['arrowup'] || this.keys['w']) {
            newPosition.z -= this.speed;
            moved = true;
        }
        if (this.keys['arrowdown'] || this.keys['s']) {
            newPosition.z += this.speed;
            moved = true;
        }
        if (this.keys['arrowleft'] || this.keys['a']) {
            newPosition.x -= this.speed;
            moved = true;
        }
        if (this.keys['arrowright'] || this.keys['d']) {
            newPosition.x += this.speed;
            moved = true;
        }
        
        if (moved) {
             // 이동 가능 여부 검사
            if (this.isMovementAllowed(newPosition)) {
                // 실제 이동 적용
                myCharacter.position.set(newPosition.x, newPosition.y, newPosition.z);
            this.isCharacterMoving = true;
            
            // 카메라가 내 캐릭터를 따라다니기
            this.updateCameraToFollowCharacter(myCharacter);
            
            // 서버에 위치 전송 (스로틀링 적용)
            this.sendPositionUpdateThrottled();
            
            // 캐릭터 이동에 따라 맵도 함께 이동
            this.updateMapToFollowCharacter(myCharacter);
            
            // 포털 충돌 검사
            this.checkPortalCollision(myCharacter);
        } else {
              // 이동 불가능한 경우 원래 위치 유지
                console.log('🚫 이동 제한: 해당 영역으로 이동할 수 없습니다.');  // 이동 불가능한 경우 원래 위치 유지
               }
        } else {   
            this.isCharacterMoving = false;
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