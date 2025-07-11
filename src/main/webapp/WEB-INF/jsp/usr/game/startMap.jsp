<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="startMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>



<div class="map-container" id="mapContainer">

	<div class="map-inner" id="mapInner">
		<img id="zoomMap" src="/resource/img/background-1.png" alt="map" />

		<div class="map_field">

			<div class="object1">
				<img src="/resource/img/fountain.png" alt="분수대" />
			</div>

			<div class="portal">
				<img src="/resource/img/portal.gif" alt="portal" />
			</div>

		</div>
		<div class="clouds">
			<img class="first_cloud" src="/resource/img/cloud1.png" alt="구름1" />
			<img class="second_cloud" src="/resource/img/cloud2.png" alt="구름2" />
			<img class="third_cloud" src="/resource/img/cloud3.png" alt="구름3" />
		</div>
	</div>
	<div class="clean-chat-container" id="chatContainer">
		<div class="chat-header">
			<div class="chat-title-wrapper">
				<div class="chat-icon">💬</div>
				<span class="chat-title">대화</span>
			</div>
			<button class="chat-toggle" id="chatToggle">−</button>
		</div>
		<div class="chat-messages" id="chatMessages">
			<!-- 채팅 메시지들이 여기에 추가됩니다 -->
		</div>
		<div class="chat-input-area">
			<div class="input-wrapper">
				<input type="text" id="chatInput" class="clean-input"
					placeholder="메시지를 입력하세요..." maxlength="200">
				<button id="chatSend" class="send-button">
					<span class="send-icon">↗</span>
				</button>
			</div>
			<!-- 메시지 종류 선택 버튼 숨김 -->
			<input type="hidden" id="chatType" value="MAP">
		</div>
	</div>
</div>




<script>
const container = document.getElementById('mapContainer');
const mapInner = document.getElementById('mapInner');

let scale = 0.5;
let posX = -200;
let posY = -150;
const minScale = 0.5;
const maxScale = 2.0;
const step = 0.1;

let isDragging = false;
let startX = 0;
let startY = 0;

const imageWidth = 4000;  // 실제 이미지 너비
const imageHeight = 2754; // 실제 이미지 높이

function applyTransform() {
  const containerWidth = container.clientWidth;
  const containerHeight = container.clientHeight;
  const scaledWidth = imageWidth * scale;
  const scaledHeight = imageHeight * scale;

  // ❗ 드래그 한계 계산
  const maxPosX = 0;
  const minPosX = containerWidth - scaledWidth;
  const maxPosY = 0;
  const minPosY = containerHeight - scaledHeight;

  // ❗ 범위 제한
  posX = Math.min(maxPosX, Math.max(minPosX, posX));
  posY = Math.min(maxPosY, Math.max(minPosY, posY));

  mapInner.style.transform = `translate(\${posX}px, \${posY}px) scale(\${scale})`;
}

// 줌
container.addEventListener('wheel', function (e) {
  e.preventDefault();

  const rect = container.getBoundingClientRect();
  const mouseX = e.clientX - rect.left;
  const mouseY = e.clientY - rect.top;

  const prevScale = scale;
  scale = e.deltaY < 0
    ? Math.min(maxScale, scale + step)
    : Math.max(minScale, scale - step);

  const scaleChange = scale / prevScale;
  posX = mouseX - (mouseX - posX) * scaleChange;
  posY = mouseY - (mouseY - posY) * scaleChange;

  applyTransform();
}, { passive: false });

// 드래그
container.addEventListener('pointerdown', (e) => {
  isDragging = true;
  startX = e.clientX;
  startY = e.clientY;
  container.setPointerCapture(e.pointerId);
  container.style.cursor = 'grabbing';
});

container.addEventListener('pointermove', (e) => {
  if (!isDragging) return;
  const dx = e.clientX - startX;
  const dy = e.clientY - startY;
  startX = e.clientX;
  startY = e.clientY;
  posX += dx;
  posY += dy;
  applyTransform();
});

container.addEventListener('pointerup', (e) => {
  isDragging = false;
  container.releasePointerCapture(e.pointerId);
  container.style.cursor = 'grab';
});

applyTransform(); // 최초 적용



 console.log('=== 서버 데이터 원본 ===');
 console.log('Member ID Raw:', '${player.memberId}');
 console.log('Nick Name Raw:', '${player.nickName}');
 console.log('Avatar Info Raw:', '${player.avatarInfo}');
 console.log('Avatar Info Type:', typeof '${player.avatarInfo}');
 
        // 서버에서 전달받은 플레이어 데이터
        let player = {
            memberId: ${player.memberId},
            nickName: "${player.nickName}",
            avatarInfo: typeof '${player.avatarInfo}' === 'string' ? JSON.parse('${player.avatarInfo}') : '${player.avatarInfo}' // 문자열 체크 후 파싱
        };
		
     // 채팅 시스템 클래스 추가
        class ChatSystem {
    	 
            constructor(gameClient) {
                this.gameClient = gameClient;
                this.currentMap = 'startMap';
                this.isMinimized = false;
                this.unreadCount = 0;
                this.currentChatType = 'chat-inMap';
                
                this.initializeUI();
            }
            
            
            initializeUI() {
                $('.chat-header').on('click', () => this.toggleChat());
                $('#chatToggle').on('click', (e) => {
                    e.stopPropagation();
                    this.toggleChat();
                });
                
                $('#chatSend').on('click', () => this.sendMessage());
                $('#chatInput').on('keypress', (e) => {
                    if (e.which === 13 || e.keyCode === 13) { // Enter key
                        e.preventDefault(); // 기본 동작 방지
                        this.sendMessage();
                    }
                });
                
                // 추가 보장: keydown 이벤트도 처리
                $('#chatInput').on('keydown', (e) => {
                    if (e.key === 'Enter' && !e.shiftKey) { // Shift+Enter는 제외
                        e.preventDefault();
                        this.sendMessage();
                    }
                });
                
                $(document).on('keydown', (e) => {
                    if (e.ctrlKey && e.key === 't' && !this.isMinimized) {
                        e.preventDefault();
                        this.toggleChatType();
                    }
                });
                
                console.log('채팅 UI 초기화 완료 (Ctrl+T: 채팅 타입 변경)');
            }
            
            toggleChatType() {
                this.currentChatType = this.currentChatType === 'MAP' ? 'GLOBAL' : 'MAP';
                $('#chatType').val(this.currentChatType);
                this.updateInputPlaceholder();
                console.log('채팅 타입 변경:', this.currentChatType);
            }
            
            updateInputPlaceholder() {
                const placeholder = this.currentChatType === 'GLOBAL' 
                    ? '전체 공지를 입력하세요... (Ctrl+T: 맵 채팅)'
                    : '메시지를 입력하세요... (Ctrl+T: 전체 공지)';
                $('#chatInput').attr('placeholder', placeholder);
            }
            
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
                
                if (!this.gameClient.socket || this.gameClient.socket.readyState !== WebSocket.OPEN) {
                    this.showSystemMessage('서버와 연결이 끊어졌습니다.');
                    sendBtn.prop('disabled', false);
                    return;
                }
                
                const chatData = {
                    type: this.currentChatType === 'GLOBAL' ? 'chat-global' : 'chat-inMap',
                    message: message
                };
                
                try {
                    this.gameClient.socket.send(JSON.stringify(chatData));
                    input.val('');
                    console.log(`\${this.currentChatType} 채팅 전송:`, message);
                    
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
                    'map': '🗺️',
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
                
                const messages = messagesContainer.children();
                if (messages.length > 100) {
                    messages.first().fadeOut(200, function() {
                        $(this).remove();
                    });
                }
            }
            
            showSystemMessage(message) {
                const systemData = {
                    nickName: '시스템',
                    message: message,
                    timestamp: Date.now()
                };
                this.displayMessage(systemData, 'system');
            }
            
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
            
            showNotification() {
                this.unreadCount++;
                this.updateTitle();
                
                $('#chatContainer').addClass('notification');
                setTimeout(() => {
                    $('#chatContainer').removeClass('notification');
                }, 500);
            }
            
            updateTitle() {
                const title = this.unreadCount > 0 ? '대화 (' + this.unreadCount + ')' : '대화';
                $('.chat-title').text(title);
            }
            
            escapeHtml(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }
            
            changeMap(newMap) {
                this.currentMap = newMap;
                this.showSystemMessage(`${newMap}로 이동했습니다.`);
            }
        }
        

        // 웹소켓 연결 및 게임 시작
        class GameClient {
            constructor() {
                this.socket = null;
                this.player = player;
                this.scene = null;
                this.camera = null;
                this.renderer = null;
                this.loader = null;
         		this.playerCharacters = new Map();
                this.myCharacter = null;
                this.keys = {};
                this.speed = 0.2;
                this.isChangingMap = false;
                this.chatSystem = null;
            }

            // Three.js 초기화 (기존 코드 기반)
            initThreeJS() {
                // 씬, 카메라, 렌더러 설정
                this.scene = new THREE.Scene();

                this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
                // 카메라를 정면에서 내려다보는 위치로 설정
                const distance = 30;
                this.camera.position.set(0, distance, 0); // 위에서 내려다보는 시점
                this.camera.lookAt(0, 0, 0);

                this.renderer = new THREE.WebGLRenderer({ 
                    antialias: true,
                    alpha: true // 투명 배경 활성화
                });
                this.renderer.setSize(window.innerWidth, window.innerHeight);
                // 배경을 투명하게 설정
                this.renderer.setClearColor(0x000000, 0); // 두 번째 매개변수가 알파값 (0 = 완전투명)
                
                if (this.renderer.outputColorSpace !== undefined) {
                    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
                } else if (this.renderer.outputEncoding !== undefined) {
                    this.renderer.outputEncoding = THREE.sRGBEncoding;
                }
                
                $('body').append(this.renderer.domElement);

                // 조명 설정
                this.setupLighting();
                
                // GLTFLoader 초기화
                if (typeof THREE.GLTFLoader !== 'undefined') {
                    this.loader = new THREE.GLTFLoader();
                }
                // 애니메이션 시작
                this.animate();
            }

            setupLighting() {
                const ambient = new THREE.AmbientLight(0xffffff, .5);
                this.scene.add(ambient);

                const light = new THREE.DirectionalLight(0xffffff, .5);
                light.position.set(0, 20, 10);
                this.scene.add(light);

            /*     const light2 = new THREE.DirectionalLight(0xffffff, .5);
                light2.position.set(10, 15, 0);
                this.scene.add(light2); */

                const pointLight = new THREE.PointLight(0xffffff, .5, 50);
                pointLight.position.set(0, 15, 0);
                this.scene.add(pointLight);
            }

            /*  loadMap() {
                const mapTexture = new THREE.TextureLoader().load(
                    '/resource/img/map.png',
                    (texture) => {
                        console.log('맵 이미지 로드 성공');
                        texture.minFilter = THREE.LinearFilter;
                        texture.magFilter = THREE.LinearFilter;
                        texture.wrapS = THREE.ClampToEdgeWrapping;
                        texture.wrapT = THREE.ClampToEdgeWrapping;
                        
                        const mapGeometry = new THREE.PlaneGeometry(50, 50);
                        const mapMaterial = new THREE.MeshBasicMaterial({
                            map: texture,
                            transparent: false,
                            side: THREE.DoubleSide
                        });
                        
                        const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
                        // 맵을 수평으로 눕혀서 위에서 내려다볼 수 있게 설정
                        mapPlane.rotation.x = -Math.PI / 2; // 90도 회전
                        mapPlane.position.set(0, -0.5, 0);
                        this.scene.add(mapPlane);
                        
                        // 포털 생성
                        this.createPortals();
                        
                    },
                    undefined,
                    (error) => {
                        console.log('맵 이미지 로드 실패');
                    }
                );
            }  */
            // 포털 생성
            createPortals() {
                // 포털 1: 테스트 맵으로 이동
                const portal1 = this.createPortal(15, 0, 15, 0x00ff00, '/testMap');
                this.scene.add(portal1);
                
                // 포털 2: 테스트 맵으로 이동  
                const portal2 = this.createPortal(-15, 0, -15, 0xff0000, '/testMap');
                this.scene.add(portal2);
                
                console.log('포털 생성 완료');
            }

            // 개별 포털 생성
            createPortal(x, y, z, color, targetMap) {
                // 포털 베이스 (원형 플랫폼)
                const portalGeometry = new THREE.CylinderGeometry(2, 2, 0.2, 16);
                const portalMaterial = new THREE.MeshLambertMaterial({ 
                    color: color,
                    transparent: true,
                    opacity: 0.7
                });
                const portalBase = new THREE.Mesh(portalGeometry, portalMaterial);
                portalBase.position.set(x, y, z);
                
                // 포털 이펙트 (회전하는 링)
                const ringGeometry = new THREE.TorusGeometry(1.5, 0.2, 8, 16);
                const ringMaterial = new THREE.MeshLambertMaterial({ 
                    color: color,
                    transparent: true,
                    opacity: 0.5
                });
                const portalRing = new THREE.Mesh(ringGeometry, ringMaterial);
                portalRing.position.set(x, y + 1, z);
                portalRing.rotation.x = Math.PI / 2;
                
                // 포털 그룹 생성
                const portalGroup = new THREE.Group();
                portalGroup.add(portalBase);
                portalGroup.add(portalRing);
                
                // 포털 정보 저장
                portalGroup.userData = {
                    type: 'portal',
                    targetMap: targetMap,
                    position: { x, y, z },
                    ring: portalRing  // 회전 애니메이션용
                };
                
                // 포털 목록에 추가
                if (!this.portals) this.portals = [];
                this.portals.push(portalGroup);
                
                return portalGroup;
            }
            
            async connect() {
            	return new Promise((resolve, reject) => {
            		 console.log('웹소켓 연결 시작');
                     this.socket = new WebSocket('ws://localhost:8081/game');

                     this.socket.onopen = async () => {
                         console.log('웹소켓 연결 완료, readyState:', this.socket.readyState);
                         // 웹소켓이 완전히 열릴 때까지 잠시 대기
                         setTimeout(async () => {
                             await this.joinMap();
                             resolve();
                         }, 100);
                     };

                     this.socket.onmessage = async (event) => {
                    	 console.log('=== 웹소켓 메시지 수신 ===');
                    	 console.log('Raw message:', event.data);
                         const message = JSON.parse(event.data);
                         await this.handleMessage(message);
                     };

                     this.socket.onerror = (error) => {
                         console.error('웹소켓 오류:', error);
                         reject(error);
                     };

                     this.socket.onclose = () => {
                         console.log('웹소켓 연결 종료');
                     };
                 });
             }
            
            joinMap() {
                const joinMessage = {
                    type: 'join-map',
                    memberId: this.player.memberId,
                    nickName: this.player.nickName,
                    avatarInfo: this.player.avatarInfo, // 서버에서 준비된 완전한 아바타 데이터
                    currentMap: 'startMap'
                };
                console.log('=== 맵 입장 요청 전송 ===');
                console.log('메시지 내용:', joinMessage);
                console.log('JSON 문자열:', JSON.stringify(joinMessage));
                
                try {
                    this.socket.send(JSON.stringify(joinMessage));
                    console.log('✓ 맵 입장 요청 전송 완료');
                    
              
                } catch (sendError) {
                    console.error('메시지 전송 실패:', sendError);
                }
            }
            
            
            async handleMessage(message) {
                console.log('메시지 수신:', message.type, message);
                try {
                    switch (message.type) {
                        case 'player-joined':
                            console.log('새 플레이어 입장:', message.player);
                            // 플레이어 데이터에서 캐릭터 정보 추출
                            const avatarInfo = typeof message.player.avatarInfo === 'string' 
                                ? JSON.parse(message.player.avatarInfo) 
                                : message.player.avatarInfo;
                            const defaultPosition = message.player.position;
                              await this.loadCharacter(avatarInfo, defaultPosition, message.player.memberId, message.player.sessionId, message.player.nickName);  
                              console.log('✓ 내 캐릭터 로드 완료');
                            break;

                        case 'existing-players':
                            console.log('기존 플레이어들:', message.players);
                            // 다른 플레이어들 순차적으로 로드
                            for (const player of message.players) {
                                if (player.memberId !== this.player.memberId) {
                                	 const avatarInfo = typeof player.avatarInfo === 'string' 
                                           ? JSON.parse(player.avatarInfo) 
                                           : player.avatarInfo;
                                    await this.loadCharacter(avatarInfo, player.position, player.memberId, player.sessionId, player.nickName);
                                }
                            }
                            break;

                        case 'player-moved':
                        	 console.log('=== 플레이어 이동 메시지 수신 ===');
                        	    console.log('받은 메시지:', message);
                        	    console.log('sessionId:', message.sessionId);
                        	    console.log('position:', message.position);
                            this.updatePlayerPosition(message.sessionId, message.position);
                            break;

                        case 'player-left':
                            this.removePlayer(message.sessionId);
                            break;
                            
                        case 'map-change-success':  
                            console.log('맵 변경 성공:', message.targetMap);
                            this.handleMapTransition(message.targetMap);
                            break;
                            
                        case 'player-left-map':
                            console.log('플레이어가 다른 맵으로 이동:', message);
                            this.removePlayer(message.sessionId);
                            break;
                            
                        case 'chat-inMap':
                            this.handleChatMessage(message, 'inMap');
                            break;
                            
                        case 'chat-global':
                            this.handleChatMessage(message, 'global');
                            break;
                       
                    }
                } catch (error) {
                    console.error('메시지 처리 중 오류:', error);
                }
            }   
            
       handleChatMessage(messageData, messageType) {
    	   console.log('채팅 메시지 처리:', messageData, messageType);  // 이 로그가 나오는지
                if (this.chatSystem) {
                    this.chatSystem.displayMessage(messageData, messageType);
                }  }  
         
     loadCharacter(avatarInfo, position, memberId, sessionId, nickName) {
        return new Promise((resolve) => {
            console.log('=== 캐릭터 로딩 시작 ===');
            console.log('닉네임:', nickName);
            console.log('멤버ID:', memberId);
            console.log('세션ID:', sessionId);
            console.log('위치:', position);
            console.log('아바타 정보:', avatarInfo);
            
           this.loader.load(
                        avatarInfo.baseModel,
                        (gltf) => {
                            console.log('✓ GLTF 모델 로드 성공:', nickName);
                            const character = gltf.scene;
                            // 먼저 스케일 설정 (원하는 크기로 조정)
                            const characterScale = 0.8; 
                            character.scale.set(characterScale, characterScale, characterScale);
                          
                            // 위치 설정
          					character.position.set(position.x, position.y, position.z);
          					character.rotation.y = Math.PI / 4;
          					character.rotation.x = -Math.PI / 6;
         
            // 내 캐릭터인 경우 설정
            if (memberId === this.player.memberId) {
                this.myCharacter = character;
                this.setupCameraFollow();
                console.log('✓ 내 캐릭터 설정 완료');
            }


            this.scene.add(character);
            this.playerCharacters.set(sessionId, character);
            
     		// 파츠 로딩
            if (avatarInfo.parts) {
            this.loadCharacterParts(character, avatarInfo.parts, nickName);
             } 
     		resolve(character);
             },
                    (error) => {
                        console.log('GLTF 모델 로드 실패', nickName, error);
                    }
                );
            });
        }
   

     // 캐릭터 파츠 로딩 
        loadCharacterParts(character, parts, nickName) {
            console.log('캐릭터 파츠 로딩 시작:', nickName, parts);

            // hair 파츠 로딩
            if (parts.hair) {
                console.log('머리 파츠 로딩:', parts.hair);
                this.loader.load(
                    parts.hair,
                    (gltf) => {
                        console.log('머리 파츠 로드 성공:', parts.hair);
                        const hairModel = gltf.scene;
                        // 바운딩 박스 계산
                        const box = new THREE.Box3().setFromObject(hairModel);
                        const center = box.getCenter(new THREE.Vector3());
                     // 파츠 스케일을 베이스 캐릭터와 맞춤
                        const baseScale = character.scale.x;
                        const hairScale = baseScale * 1.2;
                        hairModel.scale.set(hairScale, hairScale, hairScale);
                        // 머리 파츠 위치 조정
                         // 동적 위치 계산
               			 hairModel.position.set(
                   			 -center.x * hairScale-.2,
                   			 1.5 * baseScale-.1 - center.y * hairScale + 3.2,
                 			   -center.z * hairScale-.1
               			 );
                        
                        character.add(hairModel);
                        console.log('머리 파츠 부착 완료:', nickName);
                    },
                    undefined,
                    (error) => {
                        console.log('머리 파츠 로드 실패:', parts.hair, error);
                    }
                );
            }

            // 추후 추가될 다른 파츠들 (clothing, accessories 등)
            if (parts.clothing) {
                this.loadClothingPart(baseCharacter, parts.clothing, nickName);
            }
            
            if (parts.accessories) {
                this.loadAccessoryParts(baseCharacter, parts.accessories, nickName);
            }
        }
            
            // 플레이어 위치 업데이트
            updatePlayerPosition(sessionId, position) {
            	console.log('=== 위치 업데이트 시도 ===');
                console.log('새 위치:', position);
                console.log('찾는 sessionId:', sessionId);
                console.log('sessionId 타입:', typeof sessionId);
                console.log('playerCharacters에 저장된 키들:', [...this.playerCharacters.keys()]);
            	
                const character = this.playerCharacters.get(sessionId);
                console.log('찾은 캐릭터:', character);
                if (character) {
                    character.position.set(position.x, position.y, position.z);
                    console.log('위치 업데이트 완료');
                }else {
                    console.log('캐릭터를 찾을 수 없음!');
                    console.log('playerCharacters 목록:', this.playerCharacters);
                }
            }

            // 플레이어 제거
            removePlayer(sessionId) {
                const character = this.playerCharacters.get(sessionId);
                if (character) {
                    this.scene.remove(character);
                    this.playerCharacters.delete(sessionId);
                }
            }

            // 카메라 따라다니기 설정
            setupCameraFollow() {
                // 키보드 이벤트 설정 (기존 코드 기반)
                const keys = {};
                $(document).on('keydown', (e) => { keys[e.key] = true; });
                $(document).on('keyup', (e) => { keys[e.key] = false; });

                const speed = 0.2;

                // 이동 처리를 animate 루프에서 할 수 있도록 저장
                this.keys = keys;
                this.speed = speed;
            }

            // 애니메이션 루프 (기존 코드 기반)
            animate() {
                requestAnimationFrame(() => this.animate());

                // 내 캐릭터 이동 처리
                if (this.myCharacter && this.keys) {
                    let moved = false;
                    
                    if (this.keys['ArrowUp'] || this.keys['w'] || this.keys['W']) {
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
                    // y축은 항상 0.5로 고정 (맵 위)
                    this.myCharacter.position.y = 1;
                    
                    // 포털 충돌 검사
                    this.checkPortalCollision();
                    
                    // 이동했으면 서버에 위치 전송
                    if (moved) {
                        this.sendPositionUpdate();
                    }

                    // 카메라가 내 캐릭터를 따라다니기 (기존 코드 기반)
                    this.camera.position.set(
                        this.myCharacter.position.x,
                        this.myCharacter.position.y + 25,
                        this.myCharacter.position.z 
                    );
                    this.camera.lookAt(this.myCharacter.position.x, this.myCharacter.position.y, this.myCharacter.position.z);
                }
             // 포털 애니메이션
                this.animatePortals();
                this.renderer.render(this.scene, this.camera);
            }
            
            // 포털 충돌 검사
            checkPortalCollision() {
                if (!this.portals || !this.myCharacter) return;
                
                const characterPos = this.myCharacter.position;
                
                this.portals.forEach(portal => {
                    const portalPos = portal.userData.position;
                    const distance = Math.sqrt(
                        Math.pow(characterPos.x - portalPos.x, 2) + 
                        Math.pow(characterPos.z - portalPos.z, 2)
                    );
                    
                    // 포털 반경 2 이내에 들어오면 이동
                    if (distance < 2) {
                        this.enterPortal(portal.userData.targetMap);
                    }
                });
            }

            // 포털 진입 처리
            enterPortal(targetMap) {
                // 중복 진입 방지
                if (this.isChangingMap) return;
                this.isChangingMap = true;
                
                console.log('포털 진입:', targetMap);
                
                // 서버에 맵 변경 요청
                const mapChangeMessage = {
                    type: 'change-map',
                    targetMap: targetMap
                };
                
                this.socket.send(JSON.stringify(mapChangeMessage));
                
                // 화면에 전환 효과 표시
                this.showMapTransition(targetMap);
                
                // 3초 후 플래그 해제 (중복 진입 방지)
                setTimeout(() => {
                    this.isChangingMap = false;
                }, 3000);
            }

            // 맵 전환 효과
            showMapTransition(targetMap) {
                // 간단한 알림 (나중에 더 멋진 효과로 변경 가능)
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
                overlay.textContent = `감정을 찾아 이동 중...`;
                
                document.body.appendChild(overlay);
                
                // 2초 후 제거
                setTimeout(() => {
                    document.body.removeChild(overlay);
                }, 2000);
            }
            
            // 맵 전환 처리
            handleMapTransition(targetMap) {
                console.log('맵 전환 시작:', targetMap);
                
                this.showMapTransition(targetMap);
                
             // JSP 경로 결정
                let redirectPath;
                
                switch (targetMap) {
                    case '/testMap':
                        redirectPath = 'game/testMap';
                        break;
                    case '/testMap':
                        redirectPath = 'game/testMap';
                        break;
                    case '/testMap':
                        redirectPath = 'game/testMap';
                        break;
                }
                setTimeout(() => {
                    window.location.href = redirectPath;
                }, 2000);
                console.log('리다이렉트 경로:', redirectPath);
            }
            

            // 포털 애니메이션
            animatePortals() {
                if (!this.portals) return;
                
                this.portals.forEach(portal => {
                    const ring = portal.userData.ring;
                    if (ring) {
                        ring.rotation.z += 0.02; // 링 회전
                    }
                });
            }

            // 위치 업데이트 전송
            sendPositionUpdate() {
                if (this.socket && this.myCharacter) {
                    const moveMessage = {
                        type: 'player-move',
                        position: {
                            x: this.myCharacter.position.x,
                            y: this.myCharacter.position.y,
                            z: this.myCharacter.position.z 
                        }
                    };
                    this.socket.send(JSON.stringify(moveMessage));
                }
            }
        }
        $(document).ready(async () => {
            try {
                console.log('게임 초기화 시작');
                console.log('플레이어 정보 확인:', player);
                
                // 게임 클라이언트 생성 및 시작
                const gameClient = new GameClient();
                
                // 1. Three.js 초기화
                gameClient.initThreeJS();
                console.log('1. Three.js 초기화완료');
                
                // 2. 맵 로드
                /*     gameClient.loadMap();
                console.log('2. 맵 로드 완료'); */
                function animateCloud($cloud, speed, delay, verticalShift = 20) {
                    const screenWidth = $(window).width();
                    const cloudWidth = $cloud.width();
                    const initialTop = parseInt($cloud.css('top')) || 0;

                    const farRight = screenWidth + cloudWidth + 1000;

                    // ⭐ top 위치 살짝 위아래 랜덤
                    function getRandomTop() {
                      const offset = Math.floor(Math.random() * verticalShift * 2) - verticalShift; // -20 ~ +20
                      return initialTop + offset;
                    }

                    // ⭐ 처음 이동
                    function startFromInitial() {
                      $cloud.animate(
                        {
                          left: farRight + 'px',
                          top: getRandomTop() + 'px'
                        },
                        speed,
                        'linear',
                        moveLoop
                      );
                    }

                    // ⭐ 이후 반복
                    function moveLoop() {
                      $cloud.css({
                        left: -cloudWidth + 'px'
                      }).animate(
                        {
                          left: farRight + 'px',
                          top: getRandomTop() + 'px'
                        },
                        speed,
                        'linear',
                        moveLoop
                      );
                    }

                    setTimeout(startFromInitial, delay);
                  }

                  // ⚠️ 반드시 구름 클래스에 position:absolute 있어야 top이 적용됨!
                  // 예시: .first_cloud, .second_cloud, .third_cloud { position: absolute; }

                  animateCloud($('.first_cloud'), 70000, 0);
                  animateCloud($('.second_cloud'), 50000, 0);
                  animateCloud($('.third_cloud'), 70000, 0);
                
                
                // 3. 웹소켓 연결 후 캐릭터 로드
                gameClient.connect();
                console.log('3. 웹소켓 연결 및 캐릭터 로드 완료');
                
              //  4. 채팅 시스템 초기화 추가!
                gameClient.chatSystem = new ChatSystem(gameClient);
                console.log('4. 채팅 시스템 초기화 완료');
                
                
                console.log('카메라 위치:', gameClient.camera.position);
            } catch (error) {
                console.error('게임 초기화 중 오류 발생:', error);
                alert('게임을 시작할 수 없습니다: ' + error.message);
            }
        });
 
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>