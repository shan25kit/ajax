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
            avatarInfo: JSON.parse('${player.avatarInfo}') // JsonNode를 JavaScript 객체로
        };

        console.log('플레이어 데이터:', player);

        // 웹소켓 연결 및 게임 시작
        class GameClient {
            constructor() {
                this.socket = null;
                this.player = player;
                this.scene = null;
                this.camera = null;
                this.renderer = null;
                this.loader = null;
                this.playerCharacters = new Map(); // sessionId -> character 매핑
                this.myCharacter = null;
                this.initThreeJS();
            }

            // Three.js 초기화 (기존 코드 기반)
            initThreeJS() {
                // 씬, 카메라, 렌더러 설정
                this.scene = new THREE.Scene();
                this.scene.background = new THREE.Color(0x000000);

                this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
                const distance = 30;
                const angle45 = Math.PI / 4;
                
                this.camera.position.set(
                    distance * Math.cos(angle45) * Math.cos(angle45),
                    distance * Math.sin(angle45),
                    distance * Math.cos(angle45) * Math.sin(angle45)
                );
                this.camera.lookAt(0, 0, 0);

                this.renderer = new THREE.WebGLRenderer({ antialias: true });
                this.renderer.setSize(window.innerWidth, window.innerHeight);
                
                if (this.renderer.outputEncoding !== undefined) {
                    this.renderer.outputEncoding = THREE.sRGBEncoding;
                }
                
                $('body').append(this.renderer.domElement);

                // 조명 설정
                this.setupLighting();
                
                // 맵 로드
                this.loadMap();

                // GLTFLoader 초기화
                if (typeof THREE.GLTFLoader !== 'undefined') {
                    this.loader = new THREE.GLTFLoader();
                }

                // 애니메이션 시작
                this.animate();
            }

            setupLighting() {
                const ambient = new THREE.AmbientLight(0xffffff, 2.0);
                this.scene.add(ambient);

                const light = new THREE.DirectionalLight(0xffffff, 2.5);
                light.position.set(5, 10, 5);
                this.scene.add(light);

                const light2 = new THREE.DirectionalLight(0xffffff, 2.0);
                light2.position.set(-5, 5, 10);
                this.scene.add(light2);

                const pointLight = new THREE.PointLight(0xffffff, 2.0, 50);
                pointLight.position.set(0, 5, 5);
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
                            side: THREE.FrontSide
                        });
                        
                        const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
                        mapPlane.position.z = -0.1;
                        mapPlane.userData.isMap = true;
                        this.scene.add(mapPlane);
                    },
                    undefined,
                    (error) => {
                        console.log('맵 이미지 로드 실패, 기본 패턴 사용');
                        this.createDefaultMap();
                    }
                );
            }

            createDefaultMap() {
                const canvas = document.createElement('canvas');
                canvas.width = 256;
                canvas.height = 256;
                const ctx = canvas.getContext('2d');
                
                const gradient = ctx.createRadialGradient(128, 128, 0, 128, 128, 128);
                gradient.addColorStop(0, '#404040');
                gradient.addColorStop(1, '#202020');
                ctx.fillStyle = gradient;
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                
                const mapTexture = new THREE.CanvasTexture(canvas);
                const mapGeometry = new THREE.PlaneGeometry(500, 500);
                const mapMaterial = new THREE.MeshBasicMaterial({ map: mapTexture });
                const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
                mapPlane.position.z = -0.1;
                this.scene.add(mapPlane);
            }

            connect() {
                this.socket = new WebSocket('ws://localhost:8081/game');

                this.socket.onopen = () => {
                    console.log('웹소켓 연결됨');
                    this.joinMap();
                };

                this.socket.onmessage = (event) => {
                    const message = JSON.parse(event.data);
                    this.handleMessage(message);
                };
            }

            joinMap() {
                const joinMessage = {
                    type: 'join-map',
                    memberId: this.player.memberId,
                    nickName: this.player.nickName,
                    character: this.player.avatarInfo // 서버에서 준비된 완전한 아바타 데이터
                };

                this.socket.send(JSON.stringify(joinMessage));
                console.log('맵 입장 요청:', joinMessage);
            }

            handleMessage(message) {
                switch (message.type) {
                    case 'player-joined':
                        console.log('새 플레이어 입장:', message.player);
                        this.renderPlayer(message.player);
                        break;

                    case 'existing-players':
                        console.log('기존 플레이어들:', message.players);
                        message.players.forEach(player => {
                            this.renderPlayer(player);
                        });
                        break;

                    case 'player-moved':
                        this.updatePlayerPosition(message.memberId, message.position);
                        break;

                    case 'player-left':
                        this.removePlayer(message.memberId);
                        break;
                }
            }

            renderPlayer(player) {
                // 플레이어 데이터에서 캐릭터 정보 추출
                const avatarInfo = typeof player.avatarInfo === 'string' 
                    ? JSON.parse(player.avatarInfo) 
                    : player.avatarInfo;

                console.log('플레이어 렌더링:', player.nickName, avatarInfo);

                // Three.js로 캐릭터 로딩
                this.loadCharacter(avatarInfo, player.position, player.memberId, player.nickName);
            }

            // 실제 캐릭터 로딩 로직 (테스트 데이터 구조에 맞춤)
            loadCharacter(avatarInfo, position, memberId, nickName) {
                console.log('캐릭터 로딩 시작:', nickName, avatarInfo);

                // 베이스 모델 경로
                const baseModelPath = avatarInfo.baseModel || '/resource/images/default.glb';
                
                if (this.loader) {
                    // 1. 베이스 모델 먼저 로드
                    this.loader.load(
                        baseModelPath,
                        (gltf) => {
                            console.log('베이스 모델 로드 성공:', nickName);
                            const character = gltf.scene;
                            
                            // 스케일 적용 (테스트 데이터의 transform.scale 사용)
                            const scale = avatarInfo.transform?.scale || 0.3;
                            character.scale.set(scale, scale, scale);
                            
                            // 위치 설정
                            if (position) {
                                character.position.set(position.x || 0, position.y || 0, (position.z || 0) + 1);
                            } else {
                                character.position.set(0, 0, 1);
                            }

                            // 기본 회전 설정
                            character.rotation.y = Math.PI / 4;
                            character.rotation.x = Math.PI / 6;

                            // 기본 재질 설정
                            this.applyBaseMaterialSettings(character);

                            // 씬에 추가
                            this.scene.add(character);
                            
                            // 캐릭터 저장
                            this.playerCharacters.set(memberId, character);
                            
                            // 내 캐릭터인 경우 별도 저장
                            if (memberId === this.player.memberId) {
                                this.myCharacter = character;
                                this.setupCameraFollow();
                            }

                            // 2. 파츠 로딩 (hair 등)
                            if (avatarInfo.parts) {
                                this.loadCharacterParts(character, avatarInfo.parts, nickName);
                            }

                            console.log('베이스 캐릭터 렌더링 완료:', nickName);
                        },
                        undefined,
                        (error) => {
                            console.log('베이스 모델 로드 실패, 기본 캐릭터 사용:', nickName, error);
                            const character = this.createDefaultCharacter();
                            
                            if (position) {
                                character.position.set(position.x || 0, position.y || 0, (position.z || 0) + 1);
                            }
                            
                            this.scene.add(character);
                            this.playerCharacters.set(memberId, character);
                            
                            if (memberId === this.socket?.id || memberId === 'me') {
                                this.myCharacter = character;
                                this.setupCameraFollow();
                            }
                        }
                    );
                } else {
                    console.log('GLTFLoader 사용 불가, 기본 캐릭터 사용:', nickName);
                    const character = this.createDefaultCharacter();
                    
                    if (position) {
                        character.position.set(position.x || 0, position.y || 0, (position.z || 0) + 1);
                    }
                    
                    this.scene.add(character);
                    this.playerCharacters.set(memberId, character);
                    
                    if (memberId === this.socket?.id || memberId === 'me') {
                        this.myCharacter = character;
                        this.setupCameraFollow();
                    }
                }
            }

            // 캐릭터 파츠 로딩 (테스트 데이터: hair3.glb)
            loadCharacterParts(baseCharacter, parts, nickName) {
                console.log('캐릭터 파츠 로딩 시작:', nickName, parts);

                // hair 파츠 로딩
                if (parts.hair) {
                    console.log('머리 파츠 로딩:', parts.hair);
                    this.loader.load(
                        parts.hair, // '/resource/model/hair3.glb'
                        (gltf) => {
                            console.log('머리 파츠 로드 성공:', parts.hair);
                            const hairModel = gltf.scene;
                            
                            // 머리 파츠를 베이스 캐릭터에 추가
                            this.attachPartToCharacter(baseCharacter, hairModel, 'hair');
                            
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

            // 파츠를 캐릭터에 부착
            attachPartToCharacter(baseCharacter, partModel, partType) {
                // 파츠 스케일을 베이스 캐릭터와 맞춤
                const baseScale = baseCharacter.scale.x;
                partModel.scale.set(baseScale, baseScale, baseScale);
                
                // 파츠 타입에 따른 위치 조정
                switch (partType) {
                    case 'hair':
                        // 머리는 베이스 캐릭터의 머리 위치에 맞춤
                        partModel.position.set(0, 0, 0); // 상대 위치
                        break;
                    case 'clothing':
                        partModel.position.set(0, 0, 0);
                        break;
                    default:
                        partModel.position.set(0, 0, 0);
                }

                // 베이스 캐릭터에 파츠 추가
                baseCharacter.add(partModel);
                
                // 파츠에도 기본 재질 설정 적용
                this.applyBaseMaterialSettings(partModel);
            }

            // 기본 재질 설정 (기존 코드 기반)
            applyBaseMaterialSettings(model) {
                model.traverse((child) => {
                    if (child.isMesh && child.material) {
                        child.material = child.material.clone();

                        // 밝기 조정
                        if (child.material.color) {
                            child.material.color.multiplyScalar(1.5);
                        }

                        // 재질 속성 조정
                        if (child.material.metalness !== undefined) {
                            child.material.metalness = 0.1;
                        }
                        if (child.material.roughness !== undefined) {
                            child.material.roughness = 0.8;
                        }
                    }
                });
            }


            // 기본 캐릭터 생성 (기존 코드 기반)
            createDefaultCharacter() {
                const geometry = new THREE.BoxGeometry(1, 2, 0.5);
                const material = new THREE.MeshLambertMaterial({ color: 0x00ff00 });
                const character = new THREE.Mesh(geometry, material);
                
                character.scale.set(2, 2, 2);
                character.rotation.y = Math.PI / 4;
                character.rotation.x = Math.PI / 6;
                
                return character;
            }

            // 플레이어 위치 업데이트
            updatePlayerPosition(memberId, position) {
                const character = this.playerCharacters.get(memberId);
                if (character) {
                    character.position.set(position.x, position.y, (position.z || 0) + 1);
                }
            }

            // 플레이어 제거
            removePlayer(memberId) {
                const character = this.playerCharacters.get(memberId);
                if (character) {
                    this.scene.remove(character);
                    this.playerCharacters.delete(memberId);
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
                        this.myCharacter.position.y += this.speed;
                        moved = true;
                    }
                    if (this.keys['ArrowDown'] || this.keys['s'] || this.keys['S']) {
                        this.myCharacter.position.y -= this.speed;
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

                    // 이동했으면 서버에 위치 전송
                    if (moved) {
                        this.sendPositionUpdate();
                    }

                    // 카메라가 내 캐릭터를 따라다니기 (기존 코드 기반)
                    this.camera.position.set(
                        this.myCharacter.position.x,
                        this.myCharacter.position.y,
                        this.myCharacter.position.z + 30
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
                            z: this.myCharacter.position.z - 1 // z축 보정
                        }
                    };
                    this.socket.send(JSON.stringify(moveMessage));
                }
            }
        }

        // 페이지 로드 시 게임 시작
        $(document).ready(() => {
            const gameClient = new GameClient();
            gameClient.connect();
            
            // 로딩 숨기기
            setTimeout(() => {
                $('#loading').fadeOut(500);
            }, 2000);
            
            console.log('멀티플레이어 게임 클라이언트 초기화 완료!');
        });
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>