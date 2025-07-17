<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="캐릭터" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>


<script>
let scene, camera, renderer, controls, directionalLight;
let character = null;

let currentParts = {
		// 일반 파트들
		  hair: null,
		  top: null,
		  bottom: null,
		  dress: null,
		  shoes: null,
		  
		  accessory: {
		        main: [],      // accessory1~4 (배열)
		        detail: null   // accessory5~8 (단일)
		    }
};

let currentSkinColor = '#F3D7B6';

const loader = new THREE.GLTFLoader();

// ✅ 피부색 변경 함수
window.setSkinColor = function (hexColor) {
	 currentSkinColor = hexColor;
	 
  if (!character) return;

  character.traverse((child) => {
    if (child.isMesh && child.material && child.material.color) {
      child.material.color.set(hexColor);
      child.material.needsUpdate = true;
    }
  });
  
//🔸 선택된 피부색 input에 저장
  const skinInput = document.getElementById("input-skin_face");
  if (skinInput) skinInput.value = hexColor;
};

//✅ 머리색 변경 함수 (현재 선택된 hair 파트 전체에 적용)
window.setHairColor = function (hexColor) {
  const model = currentParts['hair'];
  console.log('🎨 현재 선택된 헤어:', model);

  if (!model) return;

  model.traverse((child) => {
	    if (child.isMesh && child.material && child.material.color) {
	      if (child.material.map) child.material.map = null;
	      child.material.color.set(hexColor);
	      child.material.transparent = false;
	      child.material.opacity = 1.0;
	      child.material.depthWrite = true;
	      child.material.depthTest = true;
	      child.material.needsUpdate = true;
	      child.material.side = THREE.FrontSide;
	    }
	  });
  // ✅ userData에 색상 저장
  if (model.userData) {
    model.userData.color = hexColor;
  }
	};

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('three-container');
  const containerWidth = container.clientWidth;
  const containerHeight = container.clientHeight;

  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(75, containerWidth / containerHeight, 0.1, 950);
  camera.position.set(0, 10, 25);
  camera.lookAt(0, 0, 0);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(containerWidth, containerHeight);
  renderer.setClearColor(0x000000, 0); // 투명 배경
  container.appendChild(renderer.domElement);


  /* controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.enableZoom = false;
  controls.enablePan = false;
  controls.minPolarAngle = Math.PI / 2;
  controls.maxPolarAngle = Math.PI / 2;
 */
 
 const controls = new THREE.OrbitControls(camera, renderer.domElement);

 controls.enableRotate = true;
 controls.enablePan = true;
 controls.enableZoom = true;

 controls.minPolarAngle = 0;
 controls.maxPolarAngle = Math.PI;

 controls.autoRotate = false; // 필요 시 true로

  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambientLight);

  directionalLight = new THREE.DirectionalLight(0xffffff, 0.5);
  directionalLight.position.set(0, 0, 1);
  scene.add(directionalLight);

  function updateLightPosition() {
    directionalLight.position.copy(camera.position);
    directionalLight.target.position.set(0, 0, 0);
    directionalLight.target.updateMatrixWorld();
  }

  // ✅ 캐릭터 본체 로딩
  loader.load('/resource/model/body.glb', (gltf) => {
    character = gltf.scene;
    character.scale.set(1.7, 1.7, 1.7);
    character.position.set(0, -18, 0);

    character.traverse((child) => {
      if (child.isMesh) {
        const prev = child.material;
        child.material = new THREE.MeshStandardMaterial({
          color: 0xffe0bd,
          roughness: 0.8,
          metalness: 0
        });
        if (prev.map) {
          child.material.map = prev.map;
        }
        child.material.needsUpdate = true;
      }
    });

    scene.add(character);
  });
  
  // ✅ 파츠 모델 로드 함수
  window.loadModel = function (path, partStyleKey) {
	  let partGroupKey = partStyleKey.replace(/[0-9]/g, '');  // "hair", "top" 등
	  const styleNumber = parseInt(partStyleKey.replace(/[^0-9]/g, ''));  // 1, 2, 3 등
	  
console.log(partGroupKey);
console.log(partGroupKey);  
  // 🎯 파트별 설정
  const partSettings = {
		  
    'face1': { scale: [4, 4, 4], position: [0, 9, 6], rotation: [20.4, 0, 0] },
    // 💇 헤어
    'hair1': { scale: [66, 66, 65], position: [0, -46, 0], rotation: [0, 0, 0] },
    'hair12': { scale: [65, 64, 63], position: [0, -45, 0.8], rotation: [0, 0, 0] },
    'hair3': { scale: [66.8, 65, 55.75], position: [0, -45.2, 0.4], rotation: [0, 0, 0] },
    'hair14': { scale: [62, 61, 60], position: [0, -66, 1], rotation: [0, 0, 0] },
    'hair10': { scale: [59, 60, 61], position: [0, -64.5, 0.5], rotation: [0, 0, 0] },
    'hair17': { scale: [65, 60, 58], position: [0, -41.2, 0], rotation: [0, 0, 0] },
    'hair18': { scale: [65, 58, 65], position: [0, -40, 0], rotation: [0, 0, 0] },
    'hair19': { scale: [65, 60, 61], position: [0, -41.1, 1], rotation: [0, 0, 0] },

    // 👕 상의
    'top10': { scale: [42.5, 42, 40], position: [0, -27.5, 0.2], rotation: [0, 0, 0] },
    'top12': { scale: [40, 38, 39], position: [0, -25, 0.5], rotation: [0, 0, 0] },
    'top13': { scale: [45, 42, 42], position: [0, -27.8, 0.5], rotation: [0, 0, 0] },
    'top14': { scale: [40, 38, 35], position: [0, -25, 0.3], rotation: [0, 0, 0] },
    'top1': { scale: [46.5, 45, 45], position: [0, -19.5, 0.3], rotation: [0, 0, 0] },
    'top8': { scale: [46.5, 40, 46], position: [0, -26.5, 0.3], rotation: [0, 0, 0] },
    'top11': { scale: [42.5, 42, 40], position: [0, -27.8, 0.5], rotation: [0, 0, 0] },
    'top9': { scale: [43.5, 42, 40], position: [0, -27.5, 0.1], rotation: [0, 0, 0] },

    // 👖 하의
    'bottom3': { scale: [38, 35, 34], position: [0, -22, 0.2], rotation: [0, 0, 0] },
    'bottom12': { scale: [38.8, 34, 31.5], position: [0, -22.5, 0.1], rotation: [0, 0, 0] },
    'bottom8': { scale: [40, 35, 34], position: [0, -23, 0.15], rotation: [0, 0, 0] },
    'bottom9': { scale: [41, 35, 32], position: [0, -22, 0.15], rotation: [0, 0, 0] },
    'bottom1': { scale: [47, 40, 36], position: [0.1, -18, 0], rotation: [0, 0, 0] },
    'bottom11': { scale: [40, 35, 34], position: [0, -22, 0.2], rotation: [0, 0, 0] },
    'bottom4': { scale: [38, 33, 32], position: [0, -22, 0], rotation: [0, 0, 0] },
    'bottom10': { scale: [40, 29, 32], position: [0, -20, 0.15], rotation: [0, 0, 0] },
    
    // 👗 원피스
    'dress1': { scale: [45.2, 45.2, 45.2], position: [0, -19.8, 0.45], rotation: [0, 0, 0] },
    'dress9': { scale: [43, 43, 43], position: [0, -28.5, 0.45], rotation: [0, 0, 0] },
    'dress3': { scale: [40, 37, 36.8], position: [0, -24.2, 0.45], rotation: [0, 0, 0] },
    'dress4': { scale: [40, 37, 40], position: [0, -24.3, 0.45], rotation: [0, 0, 0] },
    'dress5': { scale: [39.5, 37, 36], position: [0, -24.3, 0.45], rotation: [0, 0, 0] },
    'dress6': { scale: [39.5, 37, 36], position: [0, -24.3, 0.41], rotation: [0, 0, 0] },
    'dress7': { scale: [39.5, 37, 36], position: [0, -24.1, 0.42], rotation: [0, 0, 0] },
    'dress8': { scale: [39.5, 37, 36], position: [0, -24.1, 0.42], rotation: [0, 0, 0] },
    
    // 👟 신발
    'shoes1': { scale: [32, 30, 32], position: [0, -22, 0], rotation: [0, 0, 0] },
    'shoes2': { scale: [1.7, 2.1, 2], position: [0, -22, 1], rotation: [0, 0, 0] },
    'shoes3': { scale: [40, 40, 45], position: [0, -22, 0], rotation: [0, 0, 0] },
    'shoes4': { scale: [37, 40, 45], position: [0, -22, -0.2], rotation: [0, 0, 0] },
    'shoes5': { scale: [40, 40, 45], position: [0, -22, -0.25], rotation: [0, 0, 0] },
    'shoes6': { scale: [40, 45, 43], position: [0, -21.8, -0.22], rotation: [0, 0, 0] },
    'shoes7': { scale: [40, 45, 43], position: [0, -21.7, -0.22], rotation: [0, 0, 0] },
    'shoes8': { scale: [37, 45, 43], position: [0, -21.7, -0.22], rotation: [0, 0, 0] },

    // 🧢 액세서리
    'accessory1': { scale: [50, 50, 50], position: [7.5, -33, -3], rotation: [0.2, -0.15, 0.1] },
    'accessory2': { scale: [67, 60, 50], position: [0, -41, 1], rotation: [0, 0, 0] },
    'accessory3': { scale: [67, 60, 50], position: [0, -41, 1], rotation: [0, 0, 0] },
    'accessory4': { scale: [75, 80, 75], position: [0, -58.5, 0], rotation: [0, 0, 0] },
    'accessory5': { scale: [40, 45, 45], position: [0, -30, 0.5], rotation: [0, 0, 0] },
    'accessory6': { scale: [40, 45, 45], position: [0, -29.9, 0.5], rotation: [0, 0, 0] },
    'accessory7': { scale: [6, 6, 6], position: [0, -15, 0], rotation: [0, 0, 0] },
    'accessory8': { scale: [6.3, 6.3, 6.3], position: [0, -16.3, 0], rotation: [0, 0, 0] }
  };

  // ✅ 설정값 불러오기 (기본값 fallback)
  const setting = partSettings[partStyleKey] || {
    scale: [4, 4, 4],
    position: [0, 0, 0],
    rotation: [0, 0, 0]
  };


  // 드레스 선택 시 탑/바텀 제거
  if (partGroupKey === 'dress') {
    ['top', 'bottom'].forEach(group => {
      if (currentParts[group]) {
        scene.remove(currentParts[group]);
        currentParts[group] = null;
      }
    });
  }

  // 탑 또는 바텀 선택 시 드레스 제거
  if (partGroupKey === 'top' || partGroupKey === 'bottom') {
    if (currentParts['dress']) {
      scene.remove(currentParts['dress']);
      currentParts['dress'] = null;

 
    }
  }
  
  // 동일 파트 두 번 클릭 시 제거
  if (currentParts[partGroupKey] && currentParts[partGroupKey].userData?.partStyleKey === partStyleKey) {
    scene.remove(currentParts[partGroupKey]);
    currentParts[partGroupKey] = null;




    console.log(`🧹 ${partGroupKey} 파트 해제됨`);
    return;
  }

//✅ 악세사리 해제 로직 보강 (1~8 전부 해제 가능하게)
  if (partGroupKey === 'accessory') {
  const isDetailAccessory = ['accessory5', 'accessory6', 'accessory7', 'accessory8'].includes(partStyleKey);

  // ✅ accessory5~8: 단일 선택 (중복 제거 + 다시 선택 시 해제)
  if (isDetailAccessory) {
    // 이미 선택된 악세사리를 다시 클릭 → 해제
    // ✅ accessory.detail 처리 (단일 선택)
            if (currentParts.accessory.detail && 
                currentParts.accessory.detail.userData?.styleNumber === styleNumber) {
                scene.remove(currentParts.accessory.detail);
                currentParts.accessory.detail = null;
                console.log(`🧹 accessory.detail (${styleNumber}) 해제됨`);
                return;
            }

            // 다른 detail 제거 (중복 방지)
            if (currentParts.accessory.detail) {
                scene.remove(currentParts.accessory.detail);
                currentParts.accessory.detail = null;
            }
    
// 모델 추가

    loader.load(path, (gltf) => {

      const setting = partSettings[partStyleKey] || {
        scale: [4, 4, 4],
        position: [0, 0, 0],
        rotation: [0, 0, 0]
      };

      const model = gltf.scene;
      model.scale.set(...setting.scale);
      model.position.set(...setting.position);
      model.rotation.set(...setting.rotation);
   // ✅ userData 설정
     model.userData = {
                    partGroupKey: 'accessory',
                    partSubGroup: 'detail',
                    styleNumber: styleNumber,
                    color: null
                };
     console.log('🎒 accessory.detail userData:', model.userData);

      model.traverse((child) => {
        if (child.isMesh && child.material) {
          child.material.transparent = false;
          child.material.opacity = 1;
          child.material.depthWrite = true;
          child.material.depthTest = true;
          child.material.side = THREE.FrontSide;
          child.material.emissive = child.material.color.clone();
          child.material.emissiveIntensity = 0.1;
          child.material.metalness = 0;
          child.material.roughness = 1;
          child.material.needsUpdate = true;
        }
      });

      scene.add(model);
      currentParts.accessory.detail = model;
      console.log('✅ accessory.detail 추가됨:', styleNumber);
    });
  } else {
      // ✅ accessory.main 처리 (중복 허용)
      const index = currentParts.accessory.main.findIndex(m => 
          m.userData?.styleNumber === styleNumber
      );
      
      if (index !== -1) {
          scene.remove(currentParts.accessory.main[index]);
          currentParts.accessory.main.splice(index, 1);
          console.log(`🧹 accessory.main (${styleNumber}) 해제됨`);
          console.log('🎒 남은 main 개수:', currentParts.accessory.main.length);
          return;
      }

      // 모델 추가
      loader.load(path, (gltf) => {
          const model = gltf.scene;
          model.scale.set(...setting.scale);
          model.position.set(...setting.position);
          model.rotation.set(...setting.rotation);
          
          model.userData = {
              partGroupKey: 'accessory',
              partSubGroup: 'main',
              partStyleKey: partStyleKey,
              styleNumber: styleNumber,
              color: null
          };
          
          console.log('🎒 accessory.main userData:', model.userData);

          model.traverse((child) => {
              if (child.isMesh && child.material) {
                  child.material.transparent = false;
                  child.material.opacity = 1;
                  child.material.depthWrite = true;
                  child.material.depthTest = true;
                  child.material.side = THREE.FrontSide;
                  child.material.needsUpdate = true;
              }
          });

          scene.add(model);
          currentParts.accessory.main.push(model);
          console.log('✅ accessory.main 추가됨, 총 개수:', currentParts.accessory.main.length);
      });
  }

    return;
  }

  // 일반 파트 동일 선택 해제
  if (currentParts[partGroupKey] && 
      currentParts[partGroupKey].userData?.styleNumber === styleNumber) {
      scene.remove(currentParts[partGroupKey]);
      currentParts[partGroupKey] = null;
      // ❌ 제거: const input = document.getElementById(`input-${partGroupKey}`);
      // ❌ 제거: if (input) input.value = "";
      console.log(`🧹 ${partGroupKey} (${styleNumber}) 해제됨`);
      return;
  }
  
  // ✅ 일반 파트 로딩 처리
  if (currentParts[partGroupKey]) {
    scene.remove(currentParts[partGroupKey]);
  }

  loader.load(path, (gltf) => {
    const model = gltf.scene;
    model.scale.set(...setting.scale);
    model.position.set(...setting.position);
    model.rotation.set(...setting.rotation);
 // ✅ userData 설정
    model.userData = {
      partGroupKey: partGroupKey,    // "hair", "top" 등
      styleNumber: styleNumber,      // 1, 3 등
      color: null
    };
  console.log(model.userData);

    model.traverse((child) => {
      if (child.isMesh && child.material) {
        child.material.transparent = false;
        child.material.opacity = 1;
        child.material.depthWrite = true;
        child.material.depthTest = true;
        child.material.side = THREE.FrontSide;
        child.material.emissive = child.material.color.clone();
        child.material.emissiveIntensity = 0.1;
        child.material.metalness = 0;
        child.material.roughness = 1;
        child.material.needsUpdate = true;
      }
    });

    scene.add(model);
    currentParts[partGroupKey] = model;

    console.log('✅ 모델 추가됨:', partStyleKey);
    
 // ✅ 헤어 기본 색상 블랙 설정
    if (partGroupKey === 'hair') {
      setHairColor('#000000');
    }
  });
};

  // ✅ 렌더링 루프
  function animate() {
    requestAnimationFrame(animate);
    controls.update();
    updateLightPosition();
    renderer.render(scene, camera);
  }
  animate();

  // ✅ 반응형 대응
  window.addEventListener('resize', () => {
    const width = container.clientWidth;
    const height = container.clientHeight;
    renderer.setSize(width, height);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
  });
  
  // ✅ 초기값 세팅
  updateSelectBox('skin-face');
  setSkinColor('#F3D7B6');
  setHairColor('#000000');
});
	
function updateSelectBox(option) {
    const selectBox = document.getElementById('select-box');
    let html = '';

    if (option === 'skin-face') {
      html = `
        <h3>Color</h3>
        <div class="color-picker">
	        <button class="color1" style="background-color: #FCE9D6;" onclick="setSkinColor('#FCE9D6')"></button>
	        <button class="color2" style="background-color: #F3D7B6;" onclick="setSkinColor('#F3D7B6')" ></button>
	        <button class="color3" style="background-color: #D8B89F;" onclick="setSkinColor('#D8B89F')" ></button>
	        <button class="color4" style="background-color: #A47551;" onclick="setSkinColor('#A47551')" ></button>
	        <button class="color5" style="background-color: #5C3A2E;" onclick="setSkinColor('#5C3A2E')" ></button>
	        <button class="color6" style="background-color: #8FE3CF;" onclick="setSkinColor('#8FE3CF')" ></button>
      	</div>
        
        <div class="line"></div>
        <div class="style-select">
        	<div class="style-Wrap">
        		<button class="style1" onclick="loadModel('/resource/model/face1.glb', 'face1')">
        			<img class="face" src="/resource/img/face1.png" alt="face1" />
        		</button>
        		<button class="style2" onclick="loadModel('/resource/model/face2.glb', 'face2')">
        			<img class="face" src="/resource/img/face2.png" alt="face2" />
        		</button>
        		<button class="style3" onclick="loadModel('/resource/model/face3.glb', 'face3')">
        			<img class="face" src="/resource/img/face3.png" alt="face3" />
        		</button>
        		<button class="style4" onclick="loadModel('/resource/model/face4.glb', 'face4')">
        			<img class="face" src="/resource/img/face4.png" alt="face4" />
        		</button>
          	</div>
          	<div class="style-Wrap">
          		<button class="style5" onclick="loadModel('/resource/model/face5.glb', 'face5')">
          			<img class="face" src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style6" onclick="loadModel('/resource/model/face6.glb', 'face6')">
          			<img class="face" src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style7" onclick="loadModel('/resource/model/face7.glb', 'face7')">
          			<img class="face" src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style8" onclick="loadModel('/resource/model/face8.glb', 'face8')">
          			<img class="face" src="/resource/img/face4.png" alt="face4" />
          		</button>
          	</div>
        </div>`;
        
    } else if (option === 'hair') {
    	
        html = `
          <h3>Color</h3>
          <div class="color-picker">
            <button class="color1" style="background-color: #000000;" onclick="setHairColor('#000000')"></button>
            <button class="color2" style="background-color: #4B3621;" onclick="setHairColor('#4B3621')"></button>
            <button class="color3" style="background-color: #8B4513;" onclick="setHairColor('#8B4513')"></button>
            <button class="color4" style="background-color: #D2B48C;" onclick="setHairColor('#D2B48C')"></button>
            <button class="color5" style="background-color: #FFD700;" onclick="setHairColor('#FFD700')"></button>
            <button class="color6" style="background-color: #FFFFFF;" onclick="setHairColor('#FFFFFF')"></button>
          </div>
          
          
        <div class="line"></div>
        <div class="style-select">
         	<div class="style-Wrap">
	        	<button class="style1" onclick="loadModel('/resource/model/hair1.glb', 'hair1')">
	          		<img src="/resource/img/hair1.png" alt="hair1" />
		        </button>
		        <button class="style2" onclick="loadModel('/resource/model/hair12.glb', 'hair12')">
		          	<img src="/resource/img/hair12.png" alt="hair12" />
		        </button>
		        <button class="style3" onclick="loadModel('/resource/model/hair3.glb', 'hair3')">
		          	<img src="/resource/img/hair3.png" alt="hair3" />
		        </button>
		        <button class="style4" onclick="loadModel('/resource/model/hair14.glb', 'hair14')">
		          	<img src="/resource/img/hair14.png" alt="hair14" />
		        </button>
         	</div>
			<div class="style-Wrap">
		        <button class="style5" onclick="loadModel('/resource/model/hair10.glb', 'hair10')">
		          	<img src="/resource/img/hair10.png" alt="hair10" />
		        </button>
		        <button class="style6" onclick="loadModel('/resource/model/hair17.glb', 'hair17')">
		          	<img src="/resource/img/hair17.png" alt="hair17" />
		        </button>
		        <button class="style7" onclick="loadModel('/resource/model/hair18.glb', 'hair18')">
		          	<img src="/resource/img/hair18.png" alt="hair18" />
		        </button>
		        <button class="style8" onclick="loadModel('/resource/model/hair19.glb', 'hair19')">
		          	<img src="/resource/img/hair19.png" alt="hair19" />
		        </button>
	        </div>
        </div>`;
          
    } else if (option === 'top') {
    	
        html = `
          	<div class="style-select-option">
	        	<div class="style-Wrap">
		        	<button class="style1" onclick="loadModel('/resource/model/top10.glb', 'top10')">
		          		<img src="/resource/img/top10.png" alt="top10" />
		        	</button>
		        	<button class="style2" onclick="loadModel('/resource/model/top12.glb', 'top12')">
	          			<img src="/resource/img/top12.png" alt="top12" />
	        		</button>
	        		<button class="style3" onclick="loadModel('/resource/model/top13.glb', 'top13')">
	          			<img src="/resource/img/top13.png" alt="top13" />
	        		</button>
		        	<button class="style4" onclick="loadModel('/resource/model/top14.glb', 'top14')">
		          		<img src="/resource/img/top14.png" alt="top14" />
		        	</button>
		        </div>
          		<div class="style-Wrap">
		        	<button class="style5" onclick="loadModel('/resource/model/top1.glb', 'top1')">
		          		<img src="/resource/img/top1.png" alt="top1" />
		        	</button>
		        	<button class="style6" onclick="loadModel('/resource/model/top8.glb', 'top8')">
		          		<img src="/resource/img/top8.png" alt="top8" />
		          	</button>
		        	<button class="style7" onclick="loadModel('/resource/model/top11.glb', 'top11')">
	          			<img src="/resource/img/top11.png" alt="top11" />
	        		</button>
		        	<button class="style8" onclick="loadModel('/resource/model/top9.glb', 'top9')">
	          			<img src="/resource/img/top9.png" alt="top9" />
	        		</button>
	        	</div>
          </div>`;
          
      } else if (option === 'bottom') {
    	  
          html = `
            	<div class="style-select-option">
            		<div class="style-Wrap">
			        	<button class="style1" onclick="loadModel('/resource/model/bottom3.glb', 'bottom3')">
			          		<img src="/resource/img/bottom3.png" alt="bottom3" />
			        	</button>
			        	<button class="style2" onclick="loadModel('/resource/model/bottom12.glb', 'bottom12')">
			          		<img src="/resource/img/bottom12.png" alt="bottom12" />
			        	</button>
			        	<button class="style3" onclick="loadModel('/resource/model/bottom8.glb', 'bottom8')">
			          		<img src="/resource/img/bottom8.png" alt="bottom8" />
			        	</button>
			          	<button class="style4" onclick="loadModel('/resource/model/bottom9.glb', 'bottom9')">
			          		<img src="/resource/img/bottom9.png" alt="bottom9" />
			          	</button>
		        	</div>
		        	<div class="style-Wrap">
		            	<button class="style5" onclick="loadModel('/resource/model/bottom1.glb', 'bottom1')">
			          		<img src="/resource/img/bottom1.png" alt="bottom1" />
			        	</button>
			        	<button class="style6" onclick="loadModel('/resource/model/bottom11.glb', 'bottom11')">
			          		<img src="/resource/img/bottom11.png" alt="bottom11" />
			        	</button>
			          	<button class="style7" onclick="loadModel('/resource/model/bottom4.glb', 'bottom4')">
			          		<img src="/resource/img/bottom4.png" alt="bottom4" />
			          	</button>
			        	<button class="style8" onclick="loadModel('/resource/model/bottom10.glb', 'bottom10')">
			          		<img src="/resource/img/bottom10.png" alt="bottom10" />
			        	</button>
		          	</div>
              </div>`;
              
      } else if (option === 'dress') {
    	  
	          html = `
	              <div class="style-select-option">
					<div class="style-Wrap">
		            	<button class="style1" onclick="loadModel('/resource/model/dress1.glb', 'dress1')">
			          		<img src="/resource/img/dress1.png" alt="dress1" />
			        	</button>
			        	<button class="style2" onclick="loadModel('/resource/model/dress9.glb', 'dress9')">
			          		<img src="/resource/img/dress9.png" alt="dress2" />
			        	</button>
			        	<button class="style3" onclick="loadModel('/resource/model/dress3.glb', 'dress3')">
			          		<img src="/resource/img/dress3.png" alt="dress3" />
			          	</button>
			          	<button class="style3" onclick="loadModel('/resource/model/dress4.glb', 'dress4')">
			          		<img src="/resource/img/dress4.png" alt="dress4" />
			          	</button>
					</div>
					<div class="style-Wrap">
			          	<button class="style4" onclick="loadModel('/resource/model/dress5.glb', 'dress5')">
			          		<img src="/resource/img/dress5.png" alt="dress5" />
			          	</button>
			          	<button class="style5" onclick="loadModel('/resource/model/dress6.glb', 'dress6')">
			          		<img src="/resource/img/dress6.png" alt="dress6" />
			          	</button>
			          	<button class="style6" onclick="loadModel('/resource/model/dress7.glb', 'dress7')">
			          		<img src="/resource/img/dress7.png" alt="dress7" />
			          	</button>
			          	<button class="style6" onclick="loadModel('/resource/model/dress8.glb', 'dress8')">
			          		<img src="/resource/img/dress8.png" alt="dress8" />
			          	</button>
					</div>
	              </div>`;
              
      } else if (option === 'shoes') {
    	  
				html = `
	              	<div class="style-select-option">
	              		<div class="style-Wrap">
			            	<button class="style1" onclick="loadModel('/resource/model/shoes1.glb', 'shoes1')">
				          		<img src="/resource/img/shoes1.png" alt="shoes1" />
				        	</button>
				        	<button class="style2" onclick="loadModel('/resource/model/shoes2.glb', 'shoes2')">
				          		<img src="/resource/img/shoes2.png" alt="shoes2" />
				        	</button>
				          	<button class="style3" onclick="loadModel('/resource/model/shoes3.glb', 'shoes3')">
				          		<img src="/resource/img/shoes3.png" alt="shoes3" />
				          	</button>
				          	<button class="style3" onclick="loadModel('/resource/model/shoes4.glb', 'shoes4')">
				          		<img src="/resource/img/shoes4.png" alt="shoes4" />
				          	</button>
						</div>
						<div class="style-Wrap">
				          	<button class="style4" onclick="loadModel('/resource/model/shoes5.glb', 'shoes5')">
				          		<img src="/resource/img/shoes5.png" alt="shoes5" />
				          	</button>
				          	<button class="style5" onclick="loadModel('/resource/model/shoes6.glb', 'shoes6')">
				          		<img src="/resource/img/shoes6.png" alt="shoes6" />
				          	</button>
				          	<button class="style6" onclick="loadModel('/resource/model/shoes7.glb', 'shoes7')">
				          		<img src="/resource/img/shoes7.png" alt="shoes7" />
				          	</button>
				          	<button class="style6" onclick="loadModel('/resource/model/shoes8.glb', 'shoes8')">
				          		<img src="/resource/img/shoes8.png" alt="shoes8" />
				          	</button>
						</div>
	              </div>`;
              
      } else if (option === 'accessory') {
    	  
				html = `
					<div class="style-select-option">
						<div class="style-Wrap">
							<button class="style1" onclick="loadModel('/resource/model/accessory1.glb', 'accessory1')">
				          		<img src="/resource/img/accessory1.png" alt="accessory1" />
				          	</button>
				          	<button class="style2" onclick="loadModel('/resource/model/accessory2.glb', 'accessory2')">
				          		<img src="/resource/img/accessory2.png" alt="accessory2" />
				          	</button>
				          	<button class="style3" onclick="loadModel('/resource/model/accessory3.glb', 'accessory3')">
				          		<img src="/resource/img/accessory3.png" alt="accessory3" />
				          	</button>
				          	<button class="style4" onclick="loadModel('/resource/model/accessory4.glb', 'accessory4')">
				          		<img src="/resource/img/accessory4.png" alt="accessory4" />
				          	</button>
						</div>
						<div class="style-Wrap">
				          	<button class="style5" onclick="loadModel('/resource/model/accessory5.glb', 'accessory5')">
				          		<img src="/resource/img/accessory5.png" alt="accessory5" />
				          	</button>
				          	<button class="style6" onclick="loadModel('/resource/model/accessory6.glb', 'accessory6')">
				          		<img src="/resource/img/accessory6.png" alt="accessory6" />
				          	</button>
				          	<button class="style7" onclick="loadModel('/resource/model/accessory7.glb', 'accessory7')">
				          		<img src="/resource/img/accessory7.png" alt="accessory7" />
				          	</button>
				          	<button class="style8" onclick="loadModel('/resource/model/accessory8.glb', 'accessory8')">
				          		<img src="/resource/img/accessory8.png" alt="accessory8" />
				          	</button>
						</div>
                  </div>`;
                  
          } else {
        html = `<p>아직 준비 중이에요 🫣</p>`;
      }

    selectBox.innerHTML = html;
  }

  document.addEventListener('DOMContentLoaded', () => {
    document.querySelector('.skin-face').addEventListener('click', () => updateSelectBox('skin-face'));
    document.querySelector('.hair').addEventListener('click', () => updateSelectBox('hair'));
    document.querySelector('.top').addEventListener('click', () => updateSelectBox('top'));
    document.querySelector('.bottom').addEventListener('click', () => updateSelectBox('bottom'));
    document.querySelector('.dress').addEventListener('click', () => updateSelectBox('dress'));
    document.querySelector('.shoes').addEventListener('click', () => updateSelectBox('shoes'));
    document.querySelector('.accessory').addEventListener('click', () => updateSelectBox('accessory'));
    
  updateSelectBox('skin-face');
  setSkinColor('#F3D7B6');
  });

  function resetAvatar() {
	  for (let key in currentParts) {
	        if (key === 'accessory') {
	            // 액세서리 그룹 처리
	            currentParts.accessory.main.forEach(part => scene.remove(part));
	            currentParts.accessory.main = [];
	            
	            if (currentParts.accessory.detail) {
	                scene.remove(currentParts.accessory.detail);
	                currentParts.accessory.detail = null;
	            }
	        } else {
	            // 기존 파트
	            if (currentParts[key]) {
	                scene.remove(currentParts[key]);
	                currentParts[key] = null;
	            }
	        }
	  }


	  // ✅ 피부색 초기화
	  setSkinColor('#F3D7B6');

	  // ✅ selectBox도 리셋
	  updateSelectBox('skin-face');

  console.log('🔄 아바타 초기화 완료!');
}

async function saveAvatar() {
    try {
        // currentParts에서 데이터 추출
           const avatarInfo = {
            skinColor: currentSkinColor,
            parts: {}
        };
        
        // ✅ 중첩 구조에 맞춰 순회
           for (let partGroup in currentParts) {
               const part = currentParts[partGroup];
               
               if (partGroup === 'accessory') {
                   // ✅ 액세서리 그룹 처리
                   if (part.main.length > 0) {
                       avatarInfo.parts.accessoryMain = part.main.map(model => ({
                           style: model.userData.styleNumber
                       }));
                   }
                   
                   if (part.detail && part.detail.userData) {
                       avatarInfo.parts.accessoryDetail = {
                           style: part.detail.userData.styleNumber
                       };
                   }
               } else if (part && part.userData) {
                   // 일반 파트 처리
                   avatarInfo.parts[partGroup] = {
                       style: part.userData.styleNumber
                   };
                   
                   // 헤어 색상 추가
                   if (partGroup === 'hair' && part.userData.color) {
                       avatarInfo.parts[partGroup].color = part.userData.color;
                   }
               }
           }
        console.log('💾 전송할 데이터:', avatarInfo);

        // AJAX 전송
        const response = await fetch('/usr/custom/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(avatarInfo)
        });

        // ResultData 응답 처리
        const result = await response.json();
        
        if (result.rsCode.startsWith('S-')) {
            // 성공 시 메시지 표시 후 페이지 이동
            alert(result.rsMsg); // "캐릭터 저장 완료"
            window.location.href = '/usr/game/startMap';
        } else {
            // 실패 시 에러 메시지 표시
            alert(result.rsMsg); // 서버에서 온 구체적인 에러 메시지
        }

    } catch (error) {
        console.error('❌ 저장 중 오류:', error);
        alert('저장 중 오류가 발생했습니다.');
    }
}
  
</script>

<div class="background">

	<div class="logo-top">
		<img src="/resource/img/logo-w.png" alt="온기로고" />
	</div>

	<div class="custom-box glossy">

		<h3>${member.getNickName() }</h3>

		<div class="custom-ui">

			<div id="three-container">
				<div class="allow">
					<ul>
						<li>↻</li>
						<li>↺</li>
					</ul>
				</div>

			</div>

			<!-- ✅ 버튼 수정부 -->
			<div class="custom-options">
				<button class="skin-face"
					onclick="loadModel('/resource/model/face1.glb', 'face1')">
					<img src="/resource/img/face1.png" alt="skin-face" />
				</button>
				<button class="hair"
					onclick="loadModel('/resource/model/hair1.glb', 'hair1')">
					<img src="/resource/img/hair1.png" alt="hair" />
				</button>
				<button class="top"
					onclick="loadModel('/resource/model/top1.glb', 'top1')">
					<img src="/resource/img/top1.png" alt="top" />
				</button>
				<button class="bottom"
					onclick="loadModel('/resource/model/bottom1.glb', 'bottom1')">
					<img src="/resource/img/bottom1.png" alt="bottom" />
				</button>
				<button class="dress"
					onclick="loadModel('/resource/model/dress1.glb', 'dress1')">
					<img src="/resource/img/dress1.png" alt="dress" />
				</button>
				<button class="shoes"
					onclick="loadModel('/resource/model/shoes1.glb', 'shoes1')">
					<img src="/resource/img/shoes1.png" alt="shoes" />
				</button>
				<button class="accessory"
					onclick="loadModel('/resource/model/accessory1.glb', 'accessory1')">
					<img src="/resource/img/accessory1.png" alt="accessory" />
				</button>
			</div>


			<div class="custom-select-box" id="select-box"></div>

			<div class="btn_box">
				<button type="button" onclick="resetAvatar()">RESET</button>
				<button type="button" onclick="saveAvatar()">SAVE</button>
				<!-- AJAX 호출 -->
			</div>
		</div>
	</div>
</div>



<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>