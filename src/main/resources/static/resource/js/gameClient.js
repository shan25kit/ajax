class GameClient {
    constructor(playerData) {
        this.player = playerData;
        this.isChangingMap = false;
        
        // 모듈 초기화
        this.assetManager = new AssetManager();
        this.mapDragSystem = new MapDragSystem('mapContainer', 'mapInner');
        this.cloudAnimation = new CloudAnimation();
        this.threeJSRenderer = new ThreeJSRenderer();
        this.characterSystem = new CharacterSystem(this.threeJSRenderer, this.assetManager);
        this.webSocketManager = new WebSocketManager();
        this.movementSystem = new PlayerMovementSystem(
            this.characterSystem, 
            this.webSocketManager, 
            this.threeJSRenderer
        );
        this.inputSystem = null;
        this.chatSystem = null;
        
        this.setupModuleInteractions();
    }

    setupModuleInteractions() {
        // 맵 드래그와 Three.js 연동
        this.mapDragSystem.onTransformChange = (posX, posY, scale) => {
            this.threeJSRenderer.updateSceneTransform(posX, posY, scale);
        };

        // 웹소켓 메시지 핸들러 설정
        this.setupWebSocketHandlers();
    }

    setupWebSocketHandlers() {
        this.webSocketManager.onMessage('player-joined', async (message) => {
            console.log('새 플레이어 입장:', message.player);
            const avatarInfo = typeof message.player.avatarInfo === 'string' 
                ? JSON.parse(message.player.avatarInfo) 
                : message.player.avatarInfo;
            
            await this.characterSystem.loadCharacter(
                avatarInfo, 
                message.player.position, 
                message.player.memberId, 
                message.player.sessionId, 
                message.player.nickName
            );
        });

        this.webSocketManager.onMessage('existing-players', async (message) => {
            console.log('기존 플레이어들:', message.players);
            for (const player of message.players) {
                if (player.memberId !== this.player.memberId) {
                    const avatarInfo = typeof player.avatarInfo === 'string' 
                        ? JSON.parse(player.avatarInfo) 
                        : player.avatarInfo;
                    
                    await this.characterSystem.loadCharacter(
                        avatarInfo, 
                        player.position, 
                        player.memberId, 
                        player.sessionId, 
                        player.nickName
                    );
                }
            }
        });

        this.webSocketManager.onMessage('player-moved', (message) => {
            this.characterSystem.updatePlayerPosition(message.sessionId, message.position);
        });

        this.webSocketManager.onMessage('player-left', (message) => {
            this.characterSystem.removePlayer(message.sessionId);
        });

        this.webSocketManager.onMessage('player-left-map', (message) => {
            this.characterSystem.removePlayer(message.sessionId);
        });

        this.webSocketManager.onMessage('map-change-success', (message) => {
            console.log('맵 변경 성공:', message.targetMap);
            this.handleMapTransition(message.targetMap);
        });

        this.webSocketManager.onMessage('chat-inMap', (message) => {
            if (this.chatSystem) {
                this.chatSystem.displayMessage(message, 'map');
            }
        });

        this.webSocketManager.onMessage('chat-global', (message) => {
            if (this.chatSystem) {
                this.chatSystem.displayMessage(message, 'global');
            }
        });
    }

    async init() {
        try {
            console.log('게임 초기화 시작');
            
            // 1. Three.js 렌더링 시스템 초기화
            this.threeJSRenderer.init();
            console.log('1. Three.js 초기화 완료');
            
            // 2. 입력 시스템 초기화
            this.inputSystem = new InputSystem(this.threeJSRenderer.getCanvas());
            this.inputSystem.onMapDragToggle = (enabled) => {
                this.mapDragSystem.setEnabled(enabled);
            };
            this.inputSystem.onKeyStateChange = (keys) => {
                this.movementSystem.update(keys);
                this.movementSystem.checkPortalCollision();
            };
            console.log('2. 입력 시스템 초기화 완료');
            
            // 3. 구름 애니메이션 시작
            this.cloudAnimation.init();
            console.log('3. 구름 애니메이션 시작');
            
            // 4. 웹소켓 연결
            await this.webSocketManager.connect();
            console.log('4. 웹소켓 연결 완료');
            
            // 5. 맵 입장
            await this.joinMap();
            console.log('5. 맵 입장 완료');
            
            // 6. 채팅 시스템 초기화
            this.chatSystem = new ChatSystem(this);
            console.log('6. 채팅 시스템 초기화 완료');
            
            console.log('게임 초기화 완료!');
            
        } catch (error) {
            console.error('게임 초기화 중 오류:', error);
            throw error;
        }
    }

    async joinMap() {
        const joinMessage = {
            type: 'join-map',
            memberId: this.player.memberId,
            nickName: this.player.nickName,
            avatarInfo: this.player.avatarInfo,
            currentMap: 'startMap'
        };
        
        console.log('맵 입장 요청 전송:', joinMessage);
        return this.webSocketManager.send(joinMessage);
    }

    handleMapTransition(targetMap) {
        if (this.isChangingMap) return;
        this.isChangingMap = true;
        
        console.log('맵 전환 시작:', targetMap);
        
        let redirectPath;
        switch (targetMap) {
            case '/testMap':
                redirectPath = 'game/testMap';
                break;
            default:
                redirectPath = 'game/testMap';
                break;
        }
        
        setTimeout(() => {
            window.location.href = redirectPath;
        }, 2000);
        
        setTimeout(() => {
            this.isChangingMap = false;
        }, 3000);
    }
	}