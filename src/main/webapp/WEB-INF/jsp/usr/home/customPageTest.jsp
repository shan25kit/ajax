<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="testMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>

<script>
  // ✅ 공통 객체 선언 (중복 제거)
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(100, window.innerWidth / window.innerHeight, 0.1, 100);
  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  scene.background = new THREE.Color(0x000000);

  if (renderer.outputEncoding !== undefined) {
    renderer.outputEncoding = THREE.sRGBEncoding;
  }
  if (renderer.toneMapping !== undefined) {
    renderer.toneMapping = THREE.NoToneMapping;
  }

  // ✅ 조명
  const ambient = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambient);

  const light1 = new THREE.DirectionalLight(0xffffff, 0);
  light1.position.set(5, 10, 5);
  scene.add(light1);

  const light2 = new THREE.DirectionalLight(0xffffff,0.3);
  light2.position.set(-5, 5, 10);
  scene.add(light2);

  const pointLight = new THREE.PointLight(0xffffff, 0.5, 0);
  pointLight.position.set(0, 5, 5);
  scene.add(pointLight);

  camera.position.set(0, 0, 30);
  camera.lookAt(0, 0, 0);

  // ✅ 기본 캐릭터
  let character;

  function createDefaultCharacter() {
    const geometry = new THREE.BoxGeometry(1, 2, 0.5);
    const material = new THREE.MeshLambertMaterial({ color: 0x00ff00 });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.scale.set(2, 2, 2);
    mesh.position.set(0, 0, 1);
    mesh.rotation.set(Math.PI / 6, Math.PI / 4, 0);
    scene.add(mesh);
    return mesh;
  }

  // ✅ 기본 캐릭터 로드
  if (typeof THREE.GLTFLoader !== 'undefined') {
    const loader = new THREE.GLTFLoader();
    loader.load('/resource/images/body.glb', (gltf) => {
      character = gltf.scene;
      character.scale.set(4, 4, 4);
      character.position.set(-3, -5, 0);
      character.rotation.set(Math.PI / 15, Math.PI / 30, 0);

      character.traverse((child) => {
        if (child.isMesh && child.material) {
          child.material = child.material.clone();
          if (child.material.color) child.material.color.multiplyScalar(1.5);
          if (child.material.metalness !== undefined) child.material.metalness = 0.1;
          if (child.material.roughness !== undefined) child.material.roughness = 0.8;
        }
      });

      scene.add(character);
    }, undefined, (error) => {
      console.log('body.glb 로드 실패, 박스 캐릭터 사용');
      character = createDefaultCharacter();
    });

    // ✅ hair3.glb도 추가 로드
    loader.load('/resource/model/hair3.glb', (gltf) => {
      const hairCharacter = gltf.scene;
      hairCharacter.scale.set(4, 4, 4);
      hairCharacter.position.set(-2.7, -2.3, 0.8); // 살짝 옆으로 배치
      hairCharacter.rotation.set(Math.PI / 15, Math.PI / 45, 0);
      scene.add(hairCharacter);
    }, undefined, (error) => {
      console.log('hair3.glb 로드 실패');
    });
  }
  
//✅ 기본 캐릭터 로드
  if (typeof THREE.GLTFLoader !== 'undefined') {
    const loader = new THREE.GLTFLoader();
    loader.load('/resource/images/body2.glb', (gltf) => {
      character = gltf.scene;
      character.scale.set(2, 2, 2);
      character.position.set(4, -5, -50);
      character.rotation.set(Math.PI / 15, Math.PI / 45, 0);

      character.traverse((child) => {
        if (child.isMesh && child.material) {
          child.material = child.material.clone();
          if (child.material.color) child.material.color.multiplyScalar(1.5);
          if (child.material.metalness !== undefined) child.material.metalness = 0.1;
          if (child.material.roughness !== undefined) child.material.roughness = 0.8;
        }
      });

      scene.add(character);
    }, undefined, (error) => {
      console.log('body2.glb 로드 실패, 박스 캐릭터 사용');
      character = createDefaultCharacter();
    });

    // ✅ hair4.glb도 추가 로드
    loader.load('/resource/model/hair4.glb', (gltf) => {
      const hairCharacter = gltf.scene;
      hairCharacter.scale.set(2, 2, 2);
      hairCharacter.position.set(-4.5, 1.5, 2.3); // 살짝 옆으로 배치
      hairCharacter.rotation.set(Math.PI / 15, Math.PI / 45, 0);
      scene.add(hairCharacter);
    }, undefined, (error) => {
      console.log('hair4.glb 로드 실패');
    });
  }

  // ✅ 맵 불러오기
  function createMap() {
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    const ctx = canvas.getContext('2d');

    const tileSize = 32;
    for (let x = 0; x < canvas.width; x += tileSize) {
      for (let y = 0; y < canvas.height; y += tileSize) {
        const isEven = (Math.floor(x / tileSize) + Math.floor(y / tileSize)) % 2;
        ctx.fillStyle = isEven ? '#2a2a2a' : '#404040';
        ctx.fillRect(x, y, tileSize, tileSize);
      }
    }

    const mapTexture = new THREE.CanvasTexture(canvas);
    const map = new THREE.Mesh(
      new THREE.PlaneGeometry(1000, 1000),
      new THREE.MeshBasicMaterial({ map: mapTexture, side: THREE.FrontSide })
    );
    map.position.z = -0.1;
    scene.add(map);
  }

  function loadMap() {
    new THREE.TextureLoader().load(
      '/resource/img/background-image.jpg',
      (texture) => {
        texture.minFilter = THREE.LinearFilter;
        texture.magFilter = THREE.LinearFilter;
        texture.wrapS = THREE.ClampToEdgeWrapping;
        texture.wrapT = THREE.ClampToEdgeWrapping;

        const mapPlane = new THREE.Mesh(
          new THREE.PlaneGeometry(100, 100),
          new THREE.MeshBasicMaterial({ map: texture, side: THREE.FrontSide })
        );
        mapPlane.position.z = -0.1;
        scene.add(mapPlane);
      },
      undefined,
      (error) => {
        console.log('맵 이미지 실패 → 기본 맵 생성');
        createMap();
      }
    );
  }

  loadMap();

  // ✅ 애니메이션 루프
  function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
  }

  animate();

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
</script>



<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>