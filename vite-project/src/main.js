import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

// 씬, 카메라, 렌더러
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000);

const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 100);
// 카메라는 정면으로 고정
camera.position.set(0, 0, 30);
camera.lookAt(0, 0, 0);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
// 최신 Three.js 버전에 맞는 설정
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.NoToneMapping;
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

// 맵 (Plane에 이미지 텍스처 입힘)
const mapTexture = new THREE.TextureLoader().load('./assets/map.png');
// 최신 Three.js 버전에 맞는 설정
mapTexture.colorSpace = THREE.SRGBColorSpace;
mapTexture.minFilter = THREE.LinearFilter;  // 더 선명하게
mapTexture.magFilter = THREE.LinearFilter;  // 더 선명하게
mapTexture.wrapS = THREE.ClampToEdgeWrapping;
mapTexture.wrapT = THREE.ClampToEdgeWrapping;

const mapGeometry = new THREE.PlaneGeometry(30, 30);
const mapMaterial = new THREE.MeshBasicMaterial({
  map: mapTexture,
  transparent: false,
  side: THREE.FrontSide
});

// 맵은 그대로 정면에 두기 (이미 쿼터뷰로 그려진 이미지)
const mapPlane = new THREE.Mesh(mapGeometry, mapMaterial);
scene.add(mapPlane);

// 캐릭터 불러오기
let character;
const loader = new GLTFLoader();
loader.load('./assets/default.glb', (gltf) => {
  character = gltf.scene;
  character.scale.set(2, 2, 2);
  character.position.set(0, 0, 1);
  
  // 모든 메시의 재질 속성을 조정하여 더 밝게
  character.traverse((child) => {
    if (child.isMesh && child.material) {
      // 재질을 복사해서 수정 (원본 보존)
      child.material = child.material.clone();
      
      // 재질의 색상을 밝게 조정
      if (child.material.color) {
        child.material.color.multiplyScalar(1.5); // 1.5배 밝게
      }
      
      // 금속성과 거칠기 조정으로 더 밝게 보이게
      if (child.material.metalness !== undefined) {
        child.material.metalness = 0.1; // 금속성 낮춤
      }
      if (child.material.roughness !== undefined) {
        child.material.roughness = 0.8; // 거칠기 높임
      }
    }
  });
  
  // 캐릭터를 쿼터뷰 각도로 회전 (위에서 내려다보는 각도)
  character.rotation.y = Math.PI / 4; // 45도 회전
  character.rotation.x = Math.PI / 6; // +30도 회전 (위에서 내려다보는 각도)
  
  scene.add(character);
});

// 키보드 이동
const keys = {};
document.addEventListener('keydown', (e) => keys[e.key] = true);
document.addEventListener('keyup', (e) => keys[e.key] = false);

const speed = 0.2;

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
      character.position.x,      // 캐릭터의 x 위치와 동일
      character.position.y,      // 캐릭터의 y 위치와 동일
      character.position.z + 30  // 캐릭터 뒤쪽으로 30만큼 떨어진 위치
    );
    camera.lookAt(character.position); // 항상 캐릭터를 바라보도록
  }

  renderer.render(scene, camera);
}
animate();