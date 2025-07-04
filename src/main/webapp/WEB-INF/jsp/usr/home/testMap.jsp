<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="testMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script
	src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script
	src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
<!-- Three.js 캔버스 컨테이너 -->
<div id="canvas-container"></div>

 <script>
        $(document).ready(function() {
            // 씬, 카메라, 렌더러
            const scene = new THREE.Scene();
            scene.background = new THREE.Color(0x000000);

            const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
         // 카메라 위치를 45도씩 회전된 위치로 고정
            // 45도 = Math.PI / 4 라디안
            const distance = 30;
            const angle45 = Math.PI / 4; // 45도
            
            camera.position.set(
                distance * Math.cos(angle45) * Math.cos(angle45), // X: cos(45°) * cos(45°) * distance
                distance * Math.sin(angle45), // Y: sin(45°) * distance  
                distance * Math.cos(angle45) * Math.sin(angle45)  // Z: cos(45°) * sin(45°) * distance
            );
            camera.lookAt(0, 0, 0);

            const renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            
            // jQuery로 캔버스를 body에 추가 (기본 방식)
            $('body').append(renderer.domElement);
            
            // 기본 렌더러 크기 업데이트 함수
            function updateRendererSize() {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            }

            // Three.js r128에서 사용 가능한 설정
            if (renderer.outputEncoding !== undefined) {
                renderer.outputEncoding = THREE.sRGBEncoding;
            }
            if (renderer.toneMapping !== undefined) {
                renderer.toneMapping = THREE.NoToneMapping;
            }

            // 빛 - 더 강하게 설정
            const ambient = new THREE.AmbientLight(0xffffff, 2.0);
            scene.add(ambient);

            const light = new THREE.DirectionalLight(0xffffff, 2.5);
            light.position.set(5, 10, 5);
            scene.add(light);

            const light2 = new THREE.DirectionalLight(0xffffff, 2.0);
            light2.position.set(-5, 5, 10);
            scene.add(light2);

            const pointLight = new THREE.PointLight(0xffffff, 2.0, 50);
            pointLight.position.set(0, 5, 5);
            scene.add(pointLight);

            // 맵 생성 (실제 이미지가 없을 때를 위한 대체)
            function createMap() {
                const canvas = document.createElement('canvas');
                canvas.width = 256;
                canvas.height = 256;
                const ctx = canvas.getContext('2d');
                
                // 단순한 그라디언트 배경
                const gradient = ctx.createRadialGradient(128, 128, 0, 128, 128, 128);
                gradient.addColorStop(0, '#404040');
                gradient.addColorStop(1, '#202020');
                ctx.fillStyle = gradient;
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                 
                const mapTexture = new THREE.CanvasTexture(canvas);
                mapTexture.minFilter = THREE.LinearFilter;
                mapTexture.magFilter = THREE.LinearFilter;
                mapTexture.wrapS = THREE.ClampToEdgeWrapping;
                mapTexture.wrapT = THREE.ClampToEdgeWrapping;

                const mapGeometry = new THREE.PlaneGeometry(500, 500);
                const mapMaterial = new THREE.MeshBasicMaterial({
                    map: mapTexture,
                    transparent: false,
                    side: THREE.FrontSide
                });

                const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
                mapPlane.position.z = -0.1;
                scene.add(mapPlane);
                
                return mapPlane;
            }

            // 실제 맵 이미지 로드 시도, 실패시 패턴 사용
            function loadMap() {
                const mapTexture = new THREE.TextureLoader().load(
                    '/resource/images/map.png',
                    function(texture) {
                        console.log('맵 이미지 로드 성공');
                        texture.minFilter = THREE.LinearFilter;
                        texture.magFilter = THREE.LinearFilter;
                        // 타일링 제거 - 원본 비율 유지
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
                        mapPlane.userData.isMap = true; // 맵 식별용 추가!
                        scene.add(mapPlane);
                    },
                    undefined,
                    function(error) {
                        console.log('맵 이미지 로드 실패, 기본 패턴 사용');
                        createMap();
                    }
                );
            }

            // 맵 크기 업데이트 함수
            function updateMapSize() {
                // 기존 맵 찾기
                const mapPlane = scene.children.find(child => 
                    child.userData && child.userData.isMap
                );
                
                if (mapPlane) {
                    // 새로운 화면 비율에 맞는 크기 계산
                    const aspectRatio = window.innerWidth / window.innerHeight;
                    const mapSize = 1000;
                    const mapWidth = mapSize * Math.max(aspectRatio, 1);
                    const mapHeight = mapSize * Math.max(1 / aspectRatio, 1);
                    
                    // 기존 지오메트리 정리
                    mapPlane.geometry.dispose();
                    
                    // 새로운 크기로 지오메트리 생성
                    mapPlane.geometry = new THREE.PlaneGeometry(mapWidth, mapHeight);
                }
            }

            // 기본 캐릭터 생성 (GLTF 로드 실패시 사용)
            function createDefaultCharacter() {
                const geometry = new THREE.BoxGeometry(1, 2, 0.5);
                const material = new THREE.MeshLambertMaterial({ color: 0x00ff00 });
                const character = new THREE.Mesh(geometry, material);
                
                character.scale.set(2, 2, 2);
                character.position.set(0, 0, 1);
                character.rotation.y = Math.PI / 4;
                character.rotation.x = Math.PI / 6;
                
                scene.add(character);
                return character;
            }

            // 캐릭터 변수
            let aiChatbot;
            let character2;
            let loadedCharacters = 0; // 로딩 완료 카운터

            // jQuery로 로딩 숨기기
            function hideLoading() {
                loadedCharacters++;
                if (loadedCharacters >= 2) { // 두 캐릭터 모두 로딩 완료시
                    $('#loading').fadeOut(500);
                }
            }

            // GLTFLoader 사용 가능 여부 확인
            if (typeof THREE.GLTFLoader !== 'undefined') {
                const loader = new THREE.GLTFLoader();
                
                // 첫 번째 캐릭터 로드
                loader.load(
                    '/resource/images/default.glb',
                    function(gltf) {
                        console.log('첫 번째 GLTF 모델 로드 성공');
                        aiChatbot = gltf.scene;
                        
                        // 바운딩 박스 계산
                        const box = new THREE.Box3().setFromObject(aiChatbot);
                        console.log('aiChatbot Bounding Box:', box);
                        
                        aiChatbot.scale.set(2, 2, 2);
                        aiChatbot.position.set(0, -2, 1);

                        // 모든 메시의 재질 속성을 조정하여 더 밝게
                        aiChatbot.traverse((child) => {
                            if (child.isMesh && child.material) {
                                child.material = child.material.clone();

                                if (child.material.color) {
                                    child.material.color.multiplyScalar(1.5);
                                }

                                if (child.material.metalness !== undefined) {
                                    child.material.metalness = 0.1;
                                }
                                if (child.material.roughness !== undefined) {
                                    child.material.roughness = 0.8;
                                }
                            }
                        });

                        aiChatbot.rotation.y = Math.PI / 4;
                        aiChatbot.rotation.x = Math.PI / 6;

                        scene.add(aiChatbot);
                        hideLoading();
                    },
                    undefined,
                    function(error) {
                        console.log('첫 번째 GLTF 모델 로드 실패, 기본 캐릭터 사용');
                        aiChatbot = createDefaultCharacter();
                        aiChatbot.position.set(-2, 0, 1);
                        hideLoading();
                    }
                );

                // 두 번째 캐릭터 로드
                loader.load(
                    '/resource/images/default.glb',
                    function(gltf) {
                        console.log('두 번째 GLTF 모델 로드 성공');
                        character2 = gltf.scene;
                        character2.scale.set(2,2,2);
                        character2.position.set(-5, -20, 1);

                        // 모든 메시의 재질 속성을 조정하여 더 밝게
                        character2.traverse((child) => {
                            if (child.isMesh && child.material) {
                                child.material = child.material.clone();

                                if (child.material.color) {
                                    child.material.color.multiplyScalar(1.5);
                                }

                                if (child.material.metalness !== undefined) {
                                    child.material.metalness = 0.1;
                                }
                                if (child.material.roughness !== undefined) {
                                    child.material.roughness = 0.8;
                                }
                            }
                        });

                        character2.rotation.y = Math.PI / 4;
                        character2.rotation.x = Math.PI / 6;

                        scene.add(character2);
                        hideLoading();
                    },
                    undefined,
                    function(error) {
                        console.log('두 번째 GLTF 모델 로드 실패, 기본 캐릭터 사용');
                        character2 = createDefaultCharacter();
                        character2.position.set(2, 0, 1);
                        hideLoading();
                    }
                );
            } else {
                console.log('GLTFLoader 사용 불가, 기본 캐릭터 사용');
                aiChatbot = createDefaultCharacter();
                aiChatbot.position.set(-2, 0, 1);
                character2 = createDefaultCharacter();
                character2.position.set(2, 0, 1);
                hideLoading();
                hideLoading(); // 두 번 호출로 로딩 완료
            }

            // 맵 로드
            loadMap();

            // jQuery로 키보드 이벤트 처리
            const keys = {};
            $(document).on('keydown', function(e) {
                keys[e.key] = true;
            });

            $(document).on('keyup', function(e) {
                keys[e.key] = false;
            });

            const speed = 0.2;

            // jQuery로 마우스 클릭 이벤트 처리
            const mouse = new THREE.Vector2();
            const raycaster = new THREE.Raycaster();

            $(renderer.domElement).on('click', function(event) {
                // 마우스 좌표를 정규화된 장치 좌표로 변환
                mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
                mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

                // 레이캐스터 업데이트
                raycaster.setFromCamera(mouse, camera);

                if (character1) {
                    // 캐릭터와의 교차점 검사
                    const intersects = raycaster.intersectObject(character1, true);
                    
                    if (intersects.length > 0) {
                        console.log('캐릭터 클릭됨!');
                        showClickEffect();
                        
                        // 상담페이지로 이동 (0.5초 후)
                        setTimeout(() => {
                            goToConsultationPage();
                        }, 500);
                    }
                }
            });

            function showClickEffect() {
                // 캐릭터 주변에 파티클 효과
                const particleGeometry = new THREE.SphereGeometry(0.1, 8, 6);
                const particleMaterial = new THREE.MeshBasicMaterial({ 
                    color: 0xffff00,
                    transparent: true,
                    opacity: 0.8
                });

                for (let i = 0; i < 10; i++) {
                    const particle = new THREE.Mesh(particleGeometry, particleMaterial);
                    particle.position.copy(aiChatbot.position);
                    particle.position.x += (Math.random() - 0.5) * 3;
                    particle.position.y += (Math.random() - 0.5) * 3;
                    particle.position.z += Math.random() * 2;
                    scene.add(particle);

                    // 파티클 애니메이션 (사라지기)
                    let opacity = 0.8;
                    const fadeOut = setInterval(() => {
                        opacity -= 0.05;
                        particle.material.opacity = opacity;
                        particle.position.y += 0.1;
                        
                        if (opacity <= 0) {
                            scene.remove(particle);
                            particle.geometry.dispose();
                            particle.material.dispose();
                            clearInterval(fadeOut);
                        }
                    }, 50);
                }
            }

            function goToConsultationPage() {
                window.location.href = '/usr/home/chatBot';
                console.log('감정페이지로 이동합니다!');
            }

            // jQuery로 윈도우 리사이즈 처리
            $(window).on('resize', function() {
                updateRendererSize();
                updateMapSize(); // 맵 크기도 함께 업데이트
            });

            function animate() {
                requestAnimationFrame(animate);

                if (character2) {
                    if (keys['ArrowUp']) {
                        character2.position.y += speed;
                    }
                    if (keys['ArrowDown']) {
                        character2.position.y -= speed;
                    }
                    if (keys['ArrowLeft']) {
                        character2.position.x -= speed;
                    }
                    if (keys['ArrowRight']) {
                        character2.position.x += speed;
                    }

                    // 카메라는 character2를 따라다니되 45도 시점은 고정 유지
                    const distance = 30;
                    const angle45 = Math.PI / 4;
                    
                 // 카메라는 character2를 따라다니되 평면 위에서 수직으로 내려다보기
                    camera.position.set(
                        character2.position.x,     // X축으로 따라다니기
                        character2.position.y,     // Y축으로 따라다니기  
                        character2.position.z + 30 // Z축은 30만큼 위에서 내려다보기
                    );
                    camera.lookAt(character2.position.x, character2.position.y, character2.position.z);
                }

                renderer.render(scene, camera);
            }
            
            animate();
            
            console.log('jQuery 쿼터뷰 게임 초기화 완료!');
        });
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>