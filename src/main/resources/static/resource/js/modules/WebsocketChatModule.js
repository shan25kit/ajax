export class WebsocketChatModule {
	constructor(gameClient) {
		this.gameClient = gameClient;
		this.socket = null;
		this.isConnected = false;
		this.isChangingMap = false;
		this.chatSystem = null;
		this.reconnectAttempts = 0;
		this.maxReconnectAttempts = 5;
		this.reconnectDelay = 1000;
		this.activeBubbles = new Map();

		console.log('📦 WebSocketChatModule 생성됨');
	}

	// ===== 웹소켓 연결 =====
	async connect() {
		return new Promise((resolve, reject) => {
			try {
				console.log('🌐 웹소켓 연결 시작');
				const wsUrl = this.gameClient.getConfig('WEBSOCKET_URL');
				this.socket = new WebSocket(wsUrl);

				this.socket.onopen = async () => {
					console.log('✅ 웹소켓 연결 완료, readyState:', this.socket.readyState);
					this.isConnected = true;
					this.reconnectAttempts = 0;

					// 채팅 시스템 초기화
					this.initializeChatSystem();

					// 웹소켓이 완전히 열릴 때까지 잠시 대기
					setTimeout(() => {
						resolve();
					}, 100);
				};

				this.socket.onmessage = async (event) => {
					console.log('=== 웹소켓 메시지 수신 ===');
					console.log('Raw message:', event.data);
					try {
						const message = JSON.parse(event.data);
						await this.handleMessage(message);
					} catch (parseError) {
						console.error('메시지 파싱 오류:', parseError);
					}
				};

				this.socket.onerror = (error) => {
					console.error('❌ 웹소켓 오류:', error);
					this.isConnected = false;
					reject(error);
				};

				this.socket.onclose = (event) => {
					console.log('🔌 웹소켓 연결 종료', event.code, event.reason);
					this.isConnected = false;

					// 의도적인 종료가 아니라면 재연결 시도
					if (!event.wasClean && this.reconnectAttempts < this.maxReconnectAttempts) {
						this.attemptReconnect();
					}
				};

			} catch (error) {
				console.error('❌ 웹소켓 연결 설정 실패:', error);
				reject(error);
			}
		});
	}

	// ===== 재연결 시도 =====
	attemptReconnect() {
		this.reconnectAttempts++;
		console.log(`🔄 재연결 시도 ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);

		setTimeout(() => {
			this.connect().catch(error => {
				console.error('재연결 실패:', error);
				if (this.reconnectAttempts >= this.maxReconnectAttempts) {
					console.error('❌ 최대 재연결 시도 횟수 초과');
					this.showSystemMessage('서버 연결이 끊어졌습니다. 페이지를 새로고침해주세요.');
				}
			});
		}, this.reconnectDelay * this.reconnectAttempts);
	}

	// ===== 채팅 시스템 초기화 =====
	initializeChatSystem() {
		if (!this.chatSystem) {
			this.chatSystem = new ChatSystem(this);
			console.log('💬 채팅 시스템 초기화 완료');
		}
	}

	// ===== 맵 입장 요청 =====
	async joinMap(player) {
		if (!this.isConnected || !this.socket) {
			throw new Error('웹소켓이 연결되지 않았습니다.');
		}

		const joinMessage = {
			type: 'join-map',
			memberId: player.memberId,
			nickName: player.nickName,
			avatarInfo: player.avatarInfo,
			currentMap: 'startMap'
		};

		console.log('=== 맵 입장 요청 전송 ===');
		console.log('메시지 내용:', joinMessage);

		try {
			this.socket.send(JSON.stringify(joinMessage));
			console.log('✓ 맵 입장 요청 전송 완료');
		} catch (error) {
			console.error('❌ 맵 입장 요청 전송 실패:', error);
			throw error;
		}
	}

	// ===== 메시지 처리 =====
	async handleMessage(message) {
		console.log('📨 메시지 수신:', message.type, message);

		try {
			switch (message.type) {
				case 'player-joined':
					await this.handlePlayerJoined(message);
					break;

				case 'existing-players':
					await this.handleExistingPlayers(message);
					break;

				case 'player-move':
					this.handlePlayerMove(message);
					break;

				case 'player-left':
					this.handlePlayerLeft(message);
					break;

				case 'map-change-success':
					this.handleMapChangeSuccess(message);
					break;

				case 'player-left-map':
					this.handlePlayerLeftMap(message);
					break;

				case 'chat-inMap':
					this.handleChatMessage(message, 'map');
					break;

				case 'chat-global':
					this.handleChatMessage(message, 'global');
					break;

				default:
					console.warn('알 수 없는 메시지 타입:', message.type);
			}
		} catch (error) {
			console.error('❌ 메시지 처리 중 오류:', error, message);
		}
	}

	// ===== 플레이어 입장 처리 =====
	async handlePlayerJoined(message) {
		console.log('👤 새 플레이어 입장:', message.player);

		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		if (!characterRenderModule) return;

		const avatarInfo = typeof message.player.avatarInfo === 'string'
			? JSON.parse(message.player.avatarInfo)
			: message.player.avatarInfo;

		const defaultPosition = message.player.position;
		console.log(defaultPosition)
		await characterRenderModule.loadCharacter(
			avatarInfo,
			defaultPosition,
			message.player.memberId,
			message.player.sessionId,
			message.player.nickName
		);

		console.log('✓ 새 플레이어 캐릭터 로드 완료');
	}

	// ===== 기존 플레이어들 처리 =====
	async handleExistingPlayers(message) {
		console.log('👥 기존 플레이어들:', message.players);

		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		if (!characterRenderModule) return;

		// 다른 플레이어들 순차적으로 로드
		for (const player of message.players) {
			if (player.memberId !== this.gameClient.player.memberId) {
				const avatarInfo = typeof player.avatarInfo === 'string'
					? JSON.parse(player.avatarInfo)
					: player.avatarInfo;

				await characterRenderModule.loadCharacter(
					avatarInfo,
					player.position,
					player.memberId,
					player.sessionId,
					player.nickName
				);
			}
		}
	}

	// ===== 플레이어 이동 처리 =====
	handlePlayerMove(message) {
		console.log('🚶 플레이어 이동:', message.sessionId, message.position);

		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		if (characterRenderModule) {
			characterRenderModule.updatePlayerPosition(message.sessionId, message.position);
		}
	}

	// ===== 플레이어 퇴장 처리 =====
	handlePlayerLeft(message) {
		console.log('👋 플레이어 퇴장:', message.sessionId);

		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		if (characterRenderModule) {
			characterRenderModule.removePlayer(message.sessionId);
		}
	}

	// ===== 맵 변경 성공 처리 =====
	handleMapChangeSuccess(message) {
		console.log('🗺️ 맵 변경 성공:', message.targetMap);
		this.handleMapTransition(message.targetMap);
	}

	// ===== 플레이어 맵 이동 처리 =====
	handlePlayerLeftMap(message) {
		console.log('🚪 플레이어가 다른 맵으로 이동:', message.sessionId);

		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		if (characterRenderModule) {
			characterRenderModule.removePlayer(message.sessionId);
		}
	}

	// ===== 채팅 메시지 처리 =====
	handleChatMessage(messageData, messageType) {
		console.log('💬 채팅 메시지 처리:', messageData, messageType);

		if (this.chatSystem) {
			this.chatSystem.displayMessage(messageData, messageType);
		}
		// 버블 생성 추가
		if (messageType === 'map') {
			let senderId;

			// 내 메시지인 경우
			if (messageData.memberId === this.gameClient.player.memberId) {
				senderId = this.gameClient.player.memberId; // memberId 사용
			}
			// 다른 플레이어 메시지인 경우  
			else if (messageData.sessionId) {
				senderId = messageData.sessionId; // sessionId 사용
			}

			if (senderId) {
				this.createChatBubble(senderId, messageData.message);
			}
		}
	}
	createChatBubble(playerId, message) {
		// 기존 버블 제거
		this.removeChatBubble(playerId);
		const characterRenderModule = this.gameClient.getCharacterRenderModule();
		const mapModule = this.gameClient.getMapModule();
		let playerMesh = null;

		// 내 캐릭터인지 확인
		if (playerId === this.gameClient.player.memberId) {
			playerMesh = characterRenderModule.getMyCharacter();
		} else {
			playerMesh = characterRenderModule.getCharacter(playerId);
		}

		if (!playerMesh) {
			console.log('플레이어 메쉬를 찾을 수 없음:', playerId);
			return;
		}

		// 🔥 MapModule로 3D → 2D → 화면 좌표 변환
		const imageCoord = mapModule.worldToImageCoordinates(
			playerMesh.position.x,
			playerMesh.position.z
		);

		const mapTransform = mapModule.getTransform();
		const screenX = imageCoord.x * mapTransform.scale + mapTransform.posX;
		const screenY = imageCoord.y * mapTransform.scale + mapTransform.posY;

		console.log('버블 위치 계산:', {
			playerId,
			world3D: { x: playerMesh.position.x, z: playerMesh.position.z },
			image2D: imageCoord,
			mapTransform,
			screen2D: { x: screenX, y: screenY }
		});
		// 버블 생성
		const bubble = document.createElement('div');
		bubble.textContent = message;
		bubble.style.cssText = `
	        position: absolute;
	        left: ${screenX + 15}px;
	        top: ${screenY - 85}px;
	        background: white;
	        color: black;
			border: 0.5px solid black;
	        padding: 8px 10px;
	        border-radius: 10px;
	        font-size: 10px;
	        max-width: 200px;
			max-height: 100px;
			word-wrap: break-word;
			word-break: break-all;
			white-space: pre-wrap;
	        transform: translateX(-50%) translateY(-100%);
	        z-index: 1000;
	        pointer-events: none;
			box-shadow: 0 2px 8px rgba(0,0,0,0.15);
	    `;
		const mapContainer = document.getElementById('mapContainer');
		mapContainer.appendChild(bubble);
		this.activeBubbles.set(playerId, bubble);

		// 1초 후 제거
		setTimeout(() => this.removeChatBubble(playerId), 1000);
	}

	removeChatBubble(playerId) {
		const bubble = this.activeBubbles.get(playerId);
		if (bubble) {
			const mapContainer = document.getElementById('mapContainer');
					mapContainer.removeChild(bubble);
			this.activeBubbles.delete(playerId);
		}
	}
	// ===== 맵 전환 처리 =====
	handleMapTransition(targetMap) {
		console.log('🔄 맵 전환 시작:', targetMap);

		this.showMapTransition(targetMap);

		// JSP 경로 결정
		let redirectPath;

		switch (targetMap) {
			case '/testMap':
				redirectPath = 'game/testMap';
				break;
			case '/emotionMap':
				redirectPath = 'game/emotionMap';
				break;
			case '/happyMap':
				redirectPath = 'game/happyMap';
				break;
			case '/sadMap':
				redirectPath = 'game/sadMap';
				break;
			default:
				redirectPath = 'game/testMap';
		}

		setTimeout(() => {
			window.location.href = redirectPath;
		}, 2000);

		console.log('🔗 리다이렉트 경로:', redirectPath);
	}

	// ===== 맵 전환 효과 =====
	showMapTransition(targetMap) {
		const overlay = document.createElement('div');
		overlay.style.cssText = `
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
        `;
		overlay.textContent = '감정을 찾아 이동 중...';

		document.body.appendChild(overlay);

		// 2초 후 제거
		setTimeout(() => {
			if (document.body.contains(overlay)) {
				document.body.removeChild(overlay);
			}
		}, 2000);
	}

	// ===== 맵 변경 요청 =====
	requestMapChange(targetMap) {
		if (this.isChangingMap) return;

		this.isChangingMap = true;

		const mapChangeMessage = {
			type: 'change-map',
			targetMap: targetMap
		};

		if (this.socket && this.socket.readyState === WebSocket.OPEN) {
			try {
				this.socket.send(JSON.stringify(mapChangeMessage));
				console.log('🗺️ 맵 변경 요청 전송:', targetMap);
			} catch (error) {
				console.error('맵 변경 요청 전송 실패:', error);
				this.isChangingMap = false;
			}
		}

		// 3초 후 플래그 해제
		setTimeout(() => {
			this.isChangingMap = false;
		}, 3000);
	}

	// ===== 시스템 메시지 표시 =====
	showSystemMessage(message) {
		if (this.chatSystem) {
			this.chatSystem.showSystemMessage(message);
		} else {
			console.log('시스템 메시지:', message);
		}
	}

	// ===== 소켓 반환 =====
	getSocket() {
		return this.socket;
	}

	// ===== 연결 상태 확인 =====
	isSocketConnected() {
		return this.isConnected && this.socket && this.socket.readyState === WebSocket.OPEN;
	}

	// ===== 채팅 시스템 반환 =====
	getChatSystem() {
		return this.chatSystem;
	}

	// ===== 연결 해제 =====
	disconnect() {
		console.log('🔌 웹소켓 연결 해제');

		if (this.socket) {
			this.socket.close(1000, 'Client disconnect');
			this.socket = null;
		}

		this.isConnected = false;
		this.isChangingMap = false;
	}

	// ===== 리소스 정리 =====
	dispose() {
		console.log('🧹 웹소켓 채팅 모듈 정리');

		// 연결 해제
		this.disconnect();

		// 채팅 시스템 정리
		if (this.chatSystem && typeof this.chatSystem.dispose === 'function') {
			this.chatSystem.dispose();
		}
		this.chatSystem = null;

		console.log('✅ 웹소켓 채팅 모듈 정리 완료');
	}
}

// ===== 채팅 시스템 클래스 =====
class ChatSystem {
	constructor(webSocketModule) {
		this.webSocketModule = webSocketModule;
		this.gameClient = webSocketModule.gameClient;
		this.currentMap = 'startMap';
		this.isMinimized = false;
		this.unreadCount = 0;
		this.currentChatType = 'MAP';

		this.initializeUI();
	}

	// ===== UI 초기화 =====
	initializeUI() {
		// jQuery 이벤트 바인딩
		$('.player-chat-header').on('click', () => this.toggleChat());
		$('#chatToggle').on('click', (e) => {
			e.stopPropagation();
			this.toggleChat();
		});

		$('#chatSend').on('click', () => this.sendMessage());

		// Enter 키 이벤트
		$('#chatInput').on('keypress', (e) => {
			if (e.which === 13 || e.keyCode === 13) {
				e.preventDefault();
				this.sendMessage();
			}
		});

		$('#chatInput').on('keydown', (e) => {
			if (e.key === 'Enter' && !e.shiftKey) {
				e.preventDefault();
				this.sendMessage();
			}
		});

		// Ctrl+T로 채팅 타입 변경
		$(document).on('keydown', (e) => {
			if (e.ctrlKey && e.key === 't' && !this.isMinimized) {
				e.preventDefault();
				this.toggleChatType();
			}
		});

		console.log('💬 채팅 UI 초기화 완료 (Ctrl+T: 채팅 타입 변경)');
	}

	// ===== 채팅 타입 토글 =====
	toggleChatType() {
		this.currentChatType = this.currentChatType === 'MAP' ? 'GLOBAL' : 'MAP';
		$('#chatType').val(this.currentChatType);
		this.updateInputPlaceholder();
		console.log('채팅 타입 변경:', this.currentChatType);
	}

	// ===== 입력창 플레이스홀더 업데이트 =====
	updateInputPlaceholder() {
		const placeholder = this.currentChatType === 'GLOBAL'
			? '전체 공지를 입력하세요... (Ctrl+T: 맵 채팅)'
			: '메시지를 입력하세요... (Ctrl+T: 전체 공지)';
		$('#chatInput').attr('placeholder', placeholder);
	}

	// ===== 메시지 전송 =====
	sendMessage() {
		const input = $('#chatInput');
		const message = input.val().trim();

		if (!message) return;

		const sendBtn = $('#chatSend');
		sendBtn.prop('disabled', true);

		if (message.length > 200) {
			this.showSystemMessage('메시지가 너무 깁니다. (최대 200자)');
			sendBtn.prop('disabled', false);
			return;
		}

		if (!this.webSocketModule.isSocketConnected()) {
			this.showSystemMessage('서버와 연결이 끊어졌습니다.');
			sendBtn.prop('disabled', false);
			return;
		}

		const chatData = {
			type: this.currentChatType === 'GLOBAL' ? 'chat-global' : 'chat-inMap',
			memberId: this.webSocketModule.gameClient.player.memberId,  // 추가
			nickName: this.webSocketModule.gameClient.player.nickName,   // 추가
			message: message
		};

		try {
			this.webSocketModule.getSocket().send(JSON.stringify(chatData));
			input.val('');
			console.log(`${this.currentChatType} 채팅 전송:`, message);

			setTimeout(() => {
				input.focus();
			}, 200);

		} catch (error) {
			console.error('메시지 전송 실패:', error);
			this.showSystemMessage('메시지 전송에 실패했습니다.');
		} finally {
			setTimeout(() => sendBtn.prop('disabled', false), 500);
		}
	}

	// ===== 메시지 표시 =====
	displayMessage(messageData, messageType = 'map') {
		const messagesContainer = $('#chatMessages');

		let nickName, message, timestamp;

		if (typeof messageData === 'string') {
			try {
				const parsed = JSON.parse(messageData);
				nickName = parsed.nickName || '알 수 없음';
				message = parsed.message || '';
				timestamp = parsed.timestamp || Date.now();
			} catch (e) {
				console.error('메시지 파싱 실패:', e);
				return;
			}
		} else {
			nickName = messageData.nickName || '알 수 없음';
			message = messageData.message || '';
			timestamp = messageData.timestamp || Date.now();
		}

		const timeStr = new Date(timestamp).toLocaleTimeString('ko-KR', {
			hour: '2-digit',
			minute: '2-digit'
		});

		const typeIcon = {
			'map': '',
			'global': '📢',
			'system': '⚙️'
		};

		const messageElement = $('<div class="chat-message ' + messageType + '">' +
			'<span class="chat-nickname">' +
			(typeIcon[messageType] || '') + ' ' + this.escapeHtml(nickName) +
			'</span>' +
			'<div class="chat-content">' + this.escapeHtml(message) + '</div>' +
			'<span class="chat-timestamp">' + timeStr + '</span>' +
			'</div>');

		messagesContainer.append(messageElement);
		messagesContainer.animate({
			scrollTop: messagesContainer[0].scrollHeight
		}, 200);

		if (this.isMinimized) {
			this.showNotification();
		}

		// 메시지 개수 제한
		const messages = messagesContainer.children();
		if (messages.length > 100) {
			messages.first().fadeOut(200, function() {
				$(this).remove();
			});
		}
	}

	// ===== 시스템 메시지 표시 =====
	showSystemMessage(message) {
		const systemData = {
			nickName: '시스템',
			message: message,
			timestamp: Date.now()
		};
		this.displayMessage(systemData, 'system');
	}

	// ===== 채팅창 토글 =====
	toggleChat() {
		this.isMinimized = !this.isMinimized;
		$('#chatContainer').toggleClass('minimized');
		$('#chatToggle').text(this.isMinimized ? '+' : '−');

		if (!this.isMinimized) {
			this.unreadCount = 0;
			this.updateTitle();
			setTimeout(() => {
				$('#chatInput').focus();
				this.updateInputPlaceholder();
			}, 300);
		}
	}

	// ===== 알림 표시 =====
	showNotification() {
		this.unreadCount++;
		this.updateTitle();

		$('#chatContainer').addClass('notification');
		setTimeout(() => {
			$('#chatContainer').removeClass('notification');
		}, 500);
	}

	// ===== 제목 업데이트 =====
	updateTitle() {
		const title = this.unreadCount > 0 ? '대화 (' + this.unreadCount + ')' : '대화';
		$('.chat-title').text(title);
	}

	// ===== HTML 이스케이프 =====
	escapeHtml(text) {
		const div = document.createElement('div');
		div.textContent = text;
		return div.innerHTML;
	}

	// ===== 맵 변경 =====
	changeMap(newMap) {
		this.currentMap = newMap;
		this.showSystemMessage(`${newMap}로 이동했습니다.`);
	}

	// ===== 리소스 정리 =====
	dispose() {
		// jQuery 이벤트 해제
		$('.chat-header').off('click');
		$('#chatToggle').off('click');
		$('#chatSend').off('click');
		$('#chatInput').off('keypress keydown');
		$(document).off('keydown');

		console.log('💬 채팅 시스템 정리 완료');
	}
}
