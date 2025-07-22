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
//전역 변수
let gameClient = null;
let mapDragEnabled = true;

//맵 드래그 시스템
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

const ASSET_CONFIG = {
	    MODEL: { base: '/resource/model/', ext: '.glb' },
	};
	
function getModelPath(partType, styleNumber) {
    if (!styleNumber) return null;
    
    const path = ASSET_CONFIG.MODEL.base + String(partType) + String(styleNumber) + ASSET_CONFIG.MODEL.ext;
    console.log('🔗 생성된 경로:', path);
    return path;
}
	
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
  
//CSS 변환 적용
  mapInner.style.transform = `translate(${posX}px, ${posY}px) scale(${scale})`;
  
  // Three.js 씬과 좌표계 동기화
  if (gameClient && gameClient.scene) {
    gameClient.updateSceneTransform(posX, posY, scale);
  }
}

//줌 
container.addEventListener('wheel', function (e) {
	  if (!mapDragEnabled) return;
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
	 if (!mapDragEnabled) return;
	  // 채팅 영역 클릭 시 드래그 비활성화
	    if (e.target.closest('.clean-chat-container')) return;
  isDragging = true;
  startX = e.clientX;
  startY = e.clientY;
  container.setPointerCapture(e.pointerId);
  container.style.cursor = 'grabbing';
});

container.addEventListener('pointermove', (e) => {
	  if (!isDragging || !mapDragEnabled) return;
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



 console.log('=== 서버 데이터 원본 ===');
 console.log('Member ID Raw:', '${player.memberId}');
 console.log('Nick Name Raw:', '${player.nickName}');
 console.log('Avatar Info Raw:', '${player.avatarInfo}');
 
        // 서버에서 전달받은 플레이어 데이터
        let player = {
            memberId: ${player.memberId},
            nickName: "${player.nickName}",
            avatarInfo: JSON.parse('${player.avatarInfo}')
        };
        console.log('🔍 파싱된 avatarInfo:', player.avatarInfo);
		
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
                
                this.followZOffset = 15; // ✅ 카메라가 따라갈 거리 설정 (적당히 조절 가능)
            }

            // Three.js 초기화 (기존 코드 기반)
            initThreeJS() {
                // 씬, 카메라, 렌더러 설정
                this.scene = new THREE.Scene();

                this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
                // 카메라를 정면에서 내려다보는 위치로 설정
                const distance = 30;
                this.camera.position.set(0, distance, 15); // 위에서 내려다보는 시점
                this.camera.lookAt(0, 5, 0);

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
                
                const canvas = this.renderer.domElement;
                canvas.style.position = 'fixed';
                canvas.style.top = '0';
                canvas.style.left = '0';
                canvas.style.zIndex = '10';
                canvas.style.pointerEvents = 'auto'; // 키보드 포커스를 위해 활성화
                canvas.tabIndex = 0; // 포커스 가능하게 설정
                document.body.appendChild(canvas);
          
                // 씬 그룹 생성 (모든 게임 오브젝트를 이 그룹에 추가)
                this.sceneGroup = new THREE.Group();
                this.scene.add(this.sceneGroup);
                
                // 조명 설정
                this.setupLighting();
                
                // GLTFLoader 초기화
                if (typeof THREE.GLTFLoader !== 'undefined') {
                    this.loader = new THREE.GLTFLoader();
                }
          	   // 키보드 이벤트 설정 - 캔버스에 포커스가 있을 때만
                this.setupKeyboardControls();
                // 애니메이션 시작
                this.animate();
            }
       
            // 맵 변환과 3D 씬 동기화 (수정된 버전)
            updateSceneTransform(mapPosX, mapPosY, mapScale) {
                if (!this.sceneGroup) return;
                
                this.currentMapTransform = { posX: mapPosX, posY: mapPosY, scale: mapScale };
                
                // 화면 중심점
                const screenCenterX = window.innerWidth / 2;
                const screenCenterY = window.innerHeight / 2;
                
                // CSS 변환된 맵에서 화면 중심에 해당하는 원본 이미지 좌표
                const imageX = (screenCenterX - mapPosX) / mapScale;
                const imageY = (screenCenterY - mapPosY) / mapScale;
                
                // 이미지 좌표를 3D 월드 좌표로 변환
                // 이미지 중심을 (0,0)으로, 이미지 전체를 100x70 정도의 3D 공간으로 매핑
                const worldScale = 100 / imageWidth; // 4000px → 100 units
                const worldX = (imageX - imageWidth / 2) * worldScale;
                const worldZ = (imageY - imageHeight / 2) * worldScale;
                
                // 카메라 위치를 화면 중심에 맞춤 (캐릭터 추적 시가 아닐 때)
                if (!this.myCharacter || !this.isCharacterMoving) {
                    this.camera.position.set(worldX, 30, worldZ + 10);
                    this.camera.lookAt(worldX, 0, worldZ);
                }
                
                // 씬 그룹은 원점에 고정 (카메라만 움직임)
                this.sceneGroup.position.set(0, 0, 0);
                this.sceneGroup.scale.set(1, 1, 1);
                
                console.log('좌표 동기화:', { 
                    imageCoord: { x: imageX, y: imageY },
                    worldCoord: { x: worldX, z: worldZ },
                    mapTransform: { posX: mapPosX, posY: mapPosY, scale: mapScale }
                });
            }
            // 3D 좌표를 배경 이미지 좌표로 변환
            worldToImageCoordinates(worldX, worldZ) {
                const scaleRatio = imageWidth / 100; // 3D 100 단위를 이미지 4000px로 매핑
                const imageCenterX = imageWidth / 2;
                const imageCenterY = imageHeight / 2;
                
                return {
                    x: worldX * scaleRatio + imageCenterX,
                    y: worldZ * scaleRatio + imageCenterY
                };
            }

            // 배경 이미지 좌표를 3D 좌표로 변환
            imageToWorldCoordinates(imageX, imageY) {
                const scaleRatio = 100 / imageWidth; // 이미지 4000px을 3D 100 단위로 매핑
                const imageCenterX = imageWidth / 2;
                const imageCenterY = imageHeight / 2;
                
                return {
                    x: (imageX - imageCenterX) * scaleRatio,
                    z: (imageY - imageCenterY) * scaleRatio
                };
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
			
            setupKeyboardControls() {
                const canvas = this.renderer.domElement;
                
                // 캐릭터 모드 표시 함수
                const showCharacterMode = () => {
                    canvas.focus();
                    mapDragEnabled = false;
                };
                
                // 맵 모드로 전환
                const showMapMode = () => {
                    canvas.blur();
                    mapDragEnabled = true;
                };
                
                // 캔버스 클릭 시 포커스
                canvas.addEventListener('click', () => {
                    showCharacterMode();
                });
                
                // 캔버스 밖 클릭 시 포커스 해제 (채팅 제외)
                document.addEventListener('click', (e) => {
                    if (!canvas.contains(e.target) && !e.target.closest('.clean-chat-container')) {
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
            }
            
            
            // 애니메이션 루프 (기존 코드 기반)
            animate() {
                requestAnimationFrame(() => this.animate());
                
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
             
             /*    this.renderer.render(this.scene, this.camera); */

                // 내 캐릭터 이동 처리
                if (this.myCharacter && this.keys) {
                    let moved = false;

                    if (this.keys['arrowup'] || this.keys['w'] || this.keys['W']) {
                        this.myCharacter.position.z -= this.speed;
                        moved = true;
                    }
                    if (this.keys['arrowdown'] || this.keys['s'] || this.keys['S']) {
                        this.myCharacter.position.z += this.speed;
                        moved = true;
                    }
                    if (this.keys['arrowleft'] || this.keys['a'] || this.keys['A']) {
                        this.myCharacter.position.x -= this.speed;
                        moved = true;
                    }
                    if (this.keys['arrowright'] || this.keys['d'] || this.keys['D']) {
                        this.myCharacter.position.x += this.speed;
                        moved = true;
                    }

                    // ✅ 걷기 애니메이션 시작/정지 처리
                    if (moved) {
                        if (this.walkAction && !this.walkAction.isRunning()) {
                        	
                        	 // 🔍 진단용 로그 (걷기 시작 시점)
                            console.log('🧍‍♀️ 캐릭터 위치:', this.myCharacter.position);
                            console.log('📏 캐릭터 스케일:', this.myCharacter.scale);
                            console.log('📷 카메라와 거리:',
                                this.camera.position.distanceTo(this.myCharacter.position)
                            );
                            
                            this.myCharacter.scale.set(0.3, 0.3, 0.3); // 다시 한 번 크기 보정
                            this.myCharacter.position.y = 0; // ← 혹시 위로 뜨는 문제일 수 있으므로
                            this.myCharacter.updateMatrixWorld(true);
                            
                            this.walkAction.reset().play();
                            console.log('🚶‍♀️ 걷기 애니메이션 실행됨!');
                        }
                    } else {
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

                        this.sendPositionUpdate();
                        this.updateMapToFollowCharacter();
                    }

                    // 포털 충돌 검사
                    this.checkPortalCollision();
                }

                // 포털 애니메이션
                this.animatePortals();

                // 렌더링
                this.renderer.render(this.scene, this.camera);
            }
            
            
            // 캐릭터를 따라 맵 중심 이동 (선택사항)
            updateMapToFollowCharacter() {
                if (!this.myCharacter) return;
                
                // 캐릭터 3D 좌표를 이미지 좌표로 변환
                const imageCoord = this.worldToImageCoordinates(
                    this.myCharacter.position.x, 
                    this.myCharacter.position.z
                );
                
                // 화면 중심에 캐릭터가 오도록 맵 위치 조정
                const screenCenterX = window.innerWidth / 2;
                const screenCenterY = window.innerHeight / 2;
                
                const newPosX = screenCenterX - (imageCoord.x * scale);
                const newPosY = screenCenterY - (imageCoord.y * scale);
                
                // 부드러운 카메라 이동을 위한 lerp 적용
                const lerpFactor = 0.05;
                posX += (newPosX - posX) * lerpFactor;
                posY += (newPosY - posY) * lerpFactor;
                
                // 맵 변환 적용
                applyTransform();
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
            

         
         
            // 포털 생성
            createPortals() {
            	 // 배경 이미지 좌표계 기준으로 포털 위치 설정 (분수대 근처와 다른 위치)
                const portal1ImagePos = { x: 1200, y: 1377 }; // 분수대 근처 (배경 이미지 픽셀 좌표)
                const portal2ImagePos = { x: 3200, y: 1100 }; // 오른쪽 상단
                
                // 3D 좌표로 변환
                const portal1WorldPos = this.imageToWorldCoordinates(portal1ImagePos.x, portal1ImagePos.y);
                const portal2WorldPos = this.imageToWorldCoordinates(portal2ImagePos.x, portal2ImagePos.y);
                
                const portal1 = this.createPortal(portal1WorldPos.x, 0, portal1WorldPos.z, 0x00ff00, '/testMap');
                const portal2 = this.createPortal(portal2WorldPos.x, 0, portal2WorldPos.z, 0xff0000, '/testMap');
                
                // sceneGroup에 추가
                this.sceneGroup.add(portal1);
                this.sceneGroup.add(portal2);
                
                console.log('포털 생성 완료 - 분수대 근처와 우상단');
                console.log('Portal 1 (분수대 근처):', portal1WorldPos);
                console.log('Portal 2 (우상단):', portal2WorldPos);
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
        		   '/resource/model/body_anim.glb',
                        (gltf) => {
                            console.log('✓ 베이스 모델 로드 성공:', nickName);
                            const character = gltf.scene;
                            
                            character.traverse((child) => {
                            	  if (child.isMesh && child.material && child.material.color) {
                            	    console.log('🎨 기존 재질에 색상 적용:', avatarInfo.skinColor);
                            	    child.material.color = new THREE.Color(avatarInfo.skinColor || 0xffe0bd);
                            	    child.material.needsUpdate = true;
                            	  }
                            	});
                            
                            // 스케일 설정 
                            const characterScale = 0.3; 
                            character.scale.set(characterScale, characterScale, characterScale);
                            // 위치 설정
          					character.position.set(position.x, position.y, position.z);
                            character.position.z = 5;
          					character.rotation.y = Math.PI / 4;
          					character.rotation.x = -Math.PI / 6;
         
            // 내 캐릭터인 경우 설정
            if (memberId === this.player.memberId) {
                this.myCharacter = character;
                
             // ✅ Clock 먼저 선언!
                this.clock = new THREE.Clock();
                
             // ✅ 애니메이션 Mixer와 Action 설정
                this.mixer = new THREE.AnimationMixer(character);
                console.log('🎬 애니메이션 클립 수:', gltf.animations.length);
                console.log('📋 애니메이션 클립 이름들:', gltf.animations.map(c => c.name));
             // 'Walk' 애니메이션이 있을 때만 적용
                if (gltf.animations && gltf.animations.length > 0) {
                    const walkClip = gltf.animations.find(clip => clip.name === "Armature|mixamo.com|Layer0");

                    if (walkClip) {

                        console.log('🎯 전체 트랙 이름들:');
                        walkClip.tracks.forEach((track, idx) => {
                            console.log(`${idx}: ${track.name}`);
                        });

                        console.log('🧹 제거 전 트랙들:', walkClip.tracks.map(t => t.name));

                        // ✅ walkClip 복제 후 scale 트랙 제거
                        const walkClipClone = walkClip.clone();
                        walkClipClone.tracks = walkClipClone.tracks.filter(track => {
                            return !track.name.endsWith('.scale') && !track.name.endsWith('scale');
                        });
                        
                        console.log('✅ 제거 후 트랙들:', walkClipClone.tracks.map(t => t.name));

                        // ✅ 이전 캐시 제거 (혹시 몰라서 원본도 제거)
                        this.mixer.uncacheClip(walkClip);
                        this.mixer.uncacheClip(walkClipClone);

                        // ✅ 꼭 clone으로 넣기!
                        this.walkAction = this.mixer.clipAction(walkClipClone);
                        this.walkAction.loop = THREE.LoopRepeat;
                        this.walkAction.enabled = true;
                        this.walkAction.paused = false; // 필요 시 play()

                        console.log('🏃‍♀️ walkAction 준비 완료!');
                    }
                }



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
         console.log('📊 파츠 키들:', Object.keys(parts));

         // 모든 파츠를 순회하면서 로딩
         for (const [partType, partData] of Object.entries(parts)) {
             if (partData && partData.style) {
                 const modelPath = getModelPath(partType, partData.style);
                 console.log(`${partType} 파츠 로딩:`, modelPath);
                 
                 this.loader.load(
                     modelPath,
                     (gltf) => {
                         console.log(`${partType} 파츠 로드 성공:`, modelPath);
                         const partModel = gltf.scene;
                         console.log(`🔍 ${partType} scene:`, partModel);
                         console.log(`🔍 ${partType} children 수:`, partModel.children.length);
                         
                         // 색상 적용 (있는 경우)
                         if (partData.color) {
                             partModel.traverse((child) => {
                                 if (child.isMesh && child.material && child.material.color) {
                                     if (child.material.map) child.material.map = null;
                                     child.material.color.set(partData.color);
                                     child.material.needsUpdate = true;
                                 }
                             });
                         }
                         
                         // 파츠별 특별 설정
                         this.applyPartSettings(partModel, partType, character);
                         
                         character.add(partModel);
                         console.log(`${partType} 파츠 부착 완료:`, nickName);
                         console.log(`${partType} 파츠 최종 위치:`, partModel.position);
                      // 🔍 베이스 캐릭터의 children 수 확인
                         console.log('🔍 베이스 캐릭터 children 수:', character.children.length);
                         console.log('🔍 베이스 캐릭터 children 목록:', character.children);
                     },
                     undefined,
                     (error) => {
                         console.log(`${partType} 파츠 로드 실패:`, modelPath, error);
                     }
                 );
             }
         }
     }

     // 파츠별 위치/스케일 설정
     applyPartSettings(partModel, partType, character) {
         const baseScale = character.scale.x * 75;
         
         switch (partType) {
         	 case 'face':
             case 'hair':
            	  partModel.scale.set(baseScale*1.6, baseScale*1.6, baseScale*1.6);
                  partModel.position.set(0, -20 , 0);
                  break;
             case 'dress':   
             case 'top':
             case 'bottom':
             case 'shoes':
             case 'accessory':
             default:
                 // 기본 설정s
                 partModel.scale.set(baseScale, baseScale, baseScale);
                 partModel.position.set(0, -4, 0);
                 break;
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

      
        }
        $(document).ready(async () => {
            try {
                console.log('게임 초기화 시작');
                console.log('플레이어 정보 확인:', player);
                // 구름 애니메이션 시작
                animateCloud($('.first_cloud'), 70000, 0);
                animateCloud($('.second_cloud'), 50000, 0);
                animateCloud($('.third_cloud'), 70000, 0);
                
                // 게임 클라이언트 생성 및 시작
                const gameClient = new GameClient();
                
                // 1. Three.js 초기화
                gameClient.initThreeJS();
                console.log('1. Three.js 초기화완료');
                gameClient.createPortals();
                
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