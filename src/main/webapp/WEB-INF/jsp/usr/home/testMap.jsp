<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Insert title here</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
            background: #000;
            font-family: Arial, sans-serif;
        }
        
    </style>
</head>
<body>



<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>

<script>
    // 씬, 카메라, 렌더러
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x000000);

    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
    // 카메라는 정면으로 고정
    camera.position.set(0, 0, 30);
    camera.lookAt(0, 0, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    
    // Three.js r128에서 사용 가능한 설정
    if (renderer.outputEncoding !== undefined) {
        renderer.outputEncoding = THREE.sRGBEncoding;
    }
    if (renderer.toneMapping !== undefined) {
        renderer.toneMapping = THREE.NoToneMapping;
    }
    
    document.body.appendChild(renderer.domElement);

    // 빛 - 더 강하게 설정
    const ambient = new THREE.AmbientLight(0xffffff, 2.0); // 환경광 더 증가
    scene.add(ambient);

    const light = new THREE.DirectionalLight(0xffffff, 2.5); // 방향광 더 증가
    light.position.set(5, 10, 5);
    scene.add(light);

    // 추가 조명 - 캐릭터를 더 밝게 비추기 위해
    const light2 = new THREE.DirectionalLight(0xffffff, 2.0);
    light2.position.set(-5, 5, 10);
    scene.add(light2);

    // 포인트 라이트 추가 - 캐릭터 주변을 밝게
    const pointLight = new THREE.PointLight(0xffffff, 2.0, 50);
    pointLight.position.set(0, 5, 5);
    scene.add(pointLight);

     // 맵 생성 (실제 이미지가 없을 때를 위한 대체)
    function createMap() {
        // 텍스처가 없을 경우 패턴으로 대체
        const canvas = document.createElement('canvas');
        canvas.width = 512;
        canvas.height = 512;
        const ctx = canvas.getContext('2d');
        
        // 체크무늬 패턴 생성
        const tileSize = 32;
        for (let x = 0; x < canvas.width; x += tileSize) {
            for (let y = 0; y < canvas.height; y += tileSize) {
                const isEven = (Math.floor(x / tileSize) + Math.floor(y / tileSize)) % 2;
                ctx.fillStyle = isEven ? '#2a2a2a' : '#404040';
                ctx.fillRect(x, y, tileSize, tileSize);
            }
        }
         
        const mapTexture = new THREE.CanvasTexture(canvas);
        mapTexture.minFilter = THREE.LinearFilter;
        mapTexture.magFilter = THREE.LinearFilter;
        mapTexture.wrapS = THREE.ClampToEdgeWrapping;
        mapTexture.wrapT = THREE.ClampToEdgeWrapping;

        const mapGeometry = new THREE.PlaneGeometry(30, 30);
        const mapMaterial = new THREE.MeshBasicMaterial({
            map: mapTexture,
            transparent: false,
            side: THREE.FrontSide
        });

        const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
        scene.add(mapPlane);
    }

    // 실제 맵 이미지 로드 시도, 실패시 패턴 사용
    function loadMap() {
        const mapTexture = new THREE.TextureLoader().load(
            '/resource/images/map.png',
            // 성공 콜백
            function(texture) {
                console.log('맵 이미지 로드 성공');
                texture.minFilter = THREE.LinearFilter;
                texture.magFilter = THREE.LinearFilter;
                texture.wrapS = THREE.RepeatWrapping;
                texture.wrapT = THREE.RepeatWrapping;
                
                texture.repeat.set(30, 30);
                
                const mapGeometry = new THREE.PlaneGeometry(1000, 1000);
                const mapMaterial = new THREE.MeshBasicMaterial({
                    map: texture,
                    transparent: false,
                    side: THREE.FrontSide
                });
                
                const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
                mapPlane.position.z = -0.1;
                scene.add(mapPlane);
            },
            // 진행 콜백
            undefined,
            // 에러 콜백
            function(error) {
                console.log('맵 이미지 로드 실패, 기본 패턴 사용');
                createMap();
            }
        );
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

    // 캐릭터 불러오기
    let character;
    
    // GLTFLoader 사용 가능 여부 확인
    if (typeof THREE.GLTFLoader !== 'undefined') {
        const loader = new THREE.GLTFLoader();
        loader.load(
            '/resource/images/default.glb',
            // 성공 콜백
            (gltf) => {
                console.log('GLTF 모델 로드 성공');
                character = gltf.scene;
                character.scale.set(2, 2, 2);
                character.position.set(0, 0, 1);

                // 모든 메시의 재질 속성을 조정하여 더 밝게
                character.traverse((child) => {
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

                character.rotation.y = Math.PI / 4;
                character.rotation.x = Math.PI / 6;

                scene.add(character);
                hideLoading();
            },
            // 진행 콜백
            undefined,
            // 에러 콜백
            (error) => {
                console.log('GLTF 모델 로드 실패, 기본 캐릭터 사용');
                character = createDefaultCharacter();
                hideLoading();
            }
        );
    } else {
        console.log('GLTFLoader 사용 불가, 기본 캐릭터 사용');
        character = createDefaultCharacter();
        hideLoading();
    }

    function hideLoading() {
        const loading = document.getElementById('loading');
        if (loading) {
            loading.style.display = 'none';
        }
    }

    // 맵 로드
    loadMap();

    // 키보드 이동
    const keys = {};
    document.addEventListener('keydown', (e) => keys[e.key] = true);
    document.addEventListener('keyup', (e) => keys[e.key] = false);

    const speed = 0.2;
    
    
    const mouse = new THREE.Vector2();
    const raycaster = new THREE.Raycaster();
    function onMouseClick(event) {
        // 마우스 좌표를 정규화된 장치 좌표로 변환
        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

        // 레이캐스터 업데이트
        raycaster.setFromCamera(mouse, camera);

        if (character) {
            // 캐릭터와의 교차점 검사
            const intersects = raycaster.intersectObject(character, true);
            
            if (intersects.length > 0) {
                console.log('캐릭터 클릭됨!');
                
                // 클릭 효과 (옵션)
                showClickEffect();
                
                // 상담페이지로 이동 (1초 후)
                setTimeout(() => {
                    goToConsultationPage();
                }, 500);
            }
        }
    }
    
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
            particle.position.copy(character.position);
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
    renderer.domElement.addEventListener('click', onMouseClick, false);
    // 윈도우 리사이즈 처리
    
      function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
            
            // 맵 평면도 새로운 화면 비율에 맞게 조정
            updateMapSize();
        }
        
        function updateMapSize() {
            const mapPlane = scene.children.find(child => 
                child.geometry && child.geometry.type === 'PlaneGeometry' && 
                child.position.z <= 0
            );
            
            if (mapPlane) {
                const aspectRatio = window.innerWidth / window.innerHeight;
                mapPlane.geometry.dispose();
                mapPlane.geometry = new THREE.PlaneGeometry(100 * aspectRatio, 100);
            }
        }
        
        window.addEventListener('resize', onWindowResize);

    function animate() {
        requestAnimationFrame(animate);

        if (character) {
            if (keys['ArrowUp']) {
                character.position.y += speed;
            }
            if (keys['ArrowDown']) {
                character.position.y -= speed;
            }
            if (keys['ArrowLeft']) {
                character.position.x -= speed;
            }
            if (keys['ArrowRight']) {
                character.position.x += speed;
            }

            // 카메라가 캐릭터를 따라다니도록 설정
            camera.position.set(
                character.position.x,
                character.position.y,
                character.position.z + 30
            );
            camera.lookAt(character.position);
        }

        renderer.render(scene, camera);
    }
    
    animate();
    
    console.log('쿼터뷰 게임 초기화 완료!');
</script>

</body>
</html>