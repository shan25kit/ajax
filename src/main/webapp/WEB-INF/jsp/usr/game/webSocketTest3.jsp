<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="testMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script
	src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script
	src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
<script>
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

            loadMap() {
                const mapTexture = new THREE.TextureLoader().load(
                    '/resource/images/map.png',
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
                        
                    },
                    undefined,
                    (error) => {
                        console.log('맵 이미지 로드 실패');
                    }
                );
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
                    avatarInfo: this.player.avatarInfo // 서버에서 준비된 완전한 아바타 데이터
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
                    }
                } catch (error) {
                    console.error('메시지 처리 중 오류:', error);
                }
            }   
            
         
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
                this.renderer.render(this.scene, this.camera);
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
                gameClient.loadMap();
                console.log('2. 맵 로드 완료');
                
                // 3. 웹소켓 연결 후 캐릭터 로드
                gameClient.connect();
                console.log('3. 웹소켓 연결 및 캐릭터 로드 완료');
                
                console.log('카메라 위치:', gameClient.camera.position);
                
            } catch (error) {
                console.error('게임 초기화 중 오류 발생:', error);
                alert('게임을 시작할 수 없습니다: ' + error.message);
            }
        });
 
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>