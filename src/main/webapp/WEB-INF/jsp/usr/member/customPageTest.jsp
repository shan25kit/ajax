<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="캐릭터" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>



<script
	src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script
	src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
<script
	src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>



<script>
let scene, camera, renderer, controls, directionalLight;
let character = null;
let currentParts = {}; // ✅ 각 파트 그룹(hair, top 등)별로 현재 모델 저장
const loader = new THREE.GLTFLoader();

// ✅ 피부색 변경 함수
window.setSkinColor = function (hexColor) {
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
  const partGroupKey = partStyleKey.replace(/[0-9]/g, '');
  console.log('🚀 loadModel 실행됨:', path, partStyleKey);

  // 기존 파트 제거
  if (currentParts[partGroupKey]) {
    scene.remove(currentParts[partGroupKey]);
  }

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
    'top1': { scale: [46.5, 45, 45], position: [0, -19.5, 0.5], rotation: [0, 0, 0] },
    'top2': { scale: [45, 45, 45], position: [0, -28, 0], rotation: [0, 0.1, 0] },
    'top3': { scale: [42, 42, 45], position: [0, -27, 0.5], rotation: [0, 0, 0] },
    'top4': { scale: [40, 42, 45], position: [0, -28, 0.7], rotation: [0, 0, 0] },
    'top5': { scale: [38, 42, 45], position: [0, -27, 0.7], rotation: [0, 0, 0] },
    'top6': { scale: [40, 42, 45], position: [0, -28, 0.7], rotation: [0, 0, 0] },
    'top7': { scale: [45, 42, 45], position: [0, -28, 0.7], rotation: [0, 0, 0] },
    'top8': { scale: [46.5, 40, 46], position: [0, -26.5, 0.5], rotation: [0, 0, 0] },

    // 👖 하의
    'bottom1': { scale: [47, 40, 36], position: [0.1, -18, 0], rotation: [0, 0, 0] },
    'bottom2': { scale: [40, 40, 40], position: [0, -7.5, 0], rotation: [0, 0, 0] },
    'bottom3': { scale: [38, 35, 34], position: [0, -22, 0.2], rotation: [0, 0, 0] },
    'bottom4': { scale: [39, 35, 34], position: [0, -23, 0.1], rotation: [0, 0, 0] },
    'bottom5': { scale: [40, 29, 34], position: [0, -21, 0.2], rotation: [0, 0, 0] },
    'bottom6': { scale: [41, 35, 34], position: [0, -23.5, 0.15], rotation: [0, 0, 0] },
    'bottom7': { scale: [40, 40, 33], position: [0, -24, 0.3], rotation: [0, 0, 0] },
    'bottom8': { scale: [40, 40, 34], position: [0, -25, 0], rotation: [0, 0, 0] },
    
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
    'shoes6': { scale: [35, 45, 43], position: [0, -21.7, -0.22], rotation: [0, 0, 0] },

    // 🧢 액세서리
    'accessory1': { scale: [50, 50, 50], position: [7.5, -33, -3], rotation: [0.2, -0.15, 0.1] },
    'accessory2': { scale: [6, 6, 6], position: [0, -15, 0], rotation: [0, 0, 0] },
    'accessory3': { scale: [63, 60, 60], position: [0, -41, 0], rotation: [0, 0, 0] },
    'accessory4': { scale: [75, 80, 75], position: [0, -58.5, 0], rotation: [0, 0, 0] },
    'accessory5': { scale: [40, 45, 45], position: [0, -30, 0.5], rotation: [0, 0, 0] },
    'accessory6': { scale: [40, 45, 45], position: [0, -29.9, 0.5], rotation: [0, 0, 0] },
    'accessory7': { scale: [67, 60, 50], position: [0, -41, 1], rotation: [0, 0, 0] },
    'accessory8': { scale: [6.3, 6.3, 6.3], position: [0, -16.3, 0], rotation: [0, 0, 0] }
  };

  const setting = partSettings[partStyleKey] || {
	    scale: [4, 4, 4],
	    position: [0, 0, 0],
	    rotation: [0, 0, 0]
	  };

	  loader.load(path, (gltf) => {
	    const model = gltf.scene;

	    if (partStyleKey === 'face1') {
	      let meshFound = false;

	      model.traverse((child) => {
	        if (child.isMesh) {
	          meshFound = true;

	          // ✅ 설정값 적용
	          child.scale.set(...setting.scale);
	          child.position.set(...setting.position);
	          child.rotation.set(...setting.rotation);
	          child.visible = true;

	          // 💡 디버깅용
	          child.material.needsUpdate = true;

	          console.log('✅ face1 메쉬 찾음:', child.name);
	          console.log('🧪 위치:', child.position);
	          console.log('🧪 크기:', child.scale);

	          scene.add(child);
	          currentParts[partGroupKey] = child;
	        }
	      });

	      if (!meshFound) {
	        console.warn('⚠️ face1에서 메쉬를 찾을 수 없습니다!');
	      }

	    } else {
	      // 일반 파츠
	      model.scale.set(...setting.scale);
	      model.position.set(...setting.position);
	      model.rotation.set(...setting.rotation);
	      
	   // ✅ 여기서 투명도/렌더링 속성 보정
	      model.traverse((child) => {
	        if (child.isMesh && child.material) {
	        	child.material.transparent = false;
	            child.material.opacity = 1;
	            child.material.depthWrite = true;
	            child.material.depthTest = true;
	            child.material.side = THREE.FrontSide;

	            // ✅ 원색 보존 + 밝기 살짝 보정
	            child.material.emissive = child.material.color.clone();
	            child.material.emissiveIntensity = 0.1;

	            // ✅ 메탈/러프 세팅 (재질을 부드럽게 + 반사광X)
	            child.material.metalness = 0;
	            child.material.roughness = 1;

	            child.material.needsUpdate = true;
	        }
	      });

	      console.log('✅ 모델 추가됨:', partStyleKey);
	      scene.add(model);
	      currentParts[partGroupKey] = model;
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
  setSkinColor('#FFE0BD');
});
	
function updateSelectBox(option) {
    const selectBox = document.getElementById('select-box');
    let html = '';

    if (option === 'skin-face') {
      html = `
        <h3>Color</h3>
        <div class="color-picker">
	        <button class="color1" style="background-color: #FFE0BD;" onclick="setSkinColor('#FFE0BD')"></button>
	        <button class="color2" style="background-color: #FFCD94;" onclick="setSkinColor('#FFCD94')" ></button>
	        <button class="color3" style="background-color: #EAC086;" onclick="setSkinColor('#EAC086')" ></button>
	        <button class="color4" style="background-color: #C68642;" onclick="setSkinColor('#C68642')" ></button>
	        <button class="color5" style="background-color: #8D5524;" onclick="setSkinColor('#8D5524')" ></button>
	        <button class="color6" style="background-color: #30E3CA;" onclick="setSkinColor('#30E3CA')" ></button>
      	</div>
        
        <div class="line"></div>
        <div class="style-select">
        	<div class="style-Wrap">
        		<button class="style1" onclick="loadModel('/resource/model/face1.glb', 'face1')">
        			<img src="/resource/img/face1.png" alt="face1" />
        		</button>
        		<button class="style2" onclick="loadModel('/resource/model/face2.glb', 'face2')">
        			<img src="/resource/img/face2.png" alt="face2" />
        		</button>
        		<button class="style3" onclick="loadModel('/resource/model/face3.glb', 'face3')">
        			<img src="/resource/img/face3.png" alt="face3" />
        		</button>
        		<button class="style4" onclick="loadModel('/resource/model/face4.glb', 'face4')">
        			<img src="/resource/img/face4.png" alt="face4" />
        		</button>
          	</div>
          	<div class="style-Wrap">
          		<button class="style5" onclick="loadModel('/resource/model/face5.glb', 'face5')">
          			<img src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style6" onclick="loadModel('/resource/model/face6.glb', 'face6')">
          			<img src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style7" onclick="loadModel('/resource/model/face7.glb', 'face7')">
          			<img src="/resource/img/face4.png" alt="face4" />
          		</button>
          		<button class="style8" onclick="loadModel('/resource/model/face8.glb', 'face8')">
          			<img src="/resource/img/face4.png" alt="face4" />
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
        	<h3>Color</h3>
        	<div class="color-picker">
	        	<button class="color1"></button>
	        	<button class="color2"></button>
	        	<button class="color3"></button>
	        	<button class="color4"></button>
	        	<button class="color5"></button>
	        	<button class="color6"></button>
          	</div>
          
	      	<div class="line"></div>
          	<div class="style-select">
          		<div class="style-Wrap">
		        	<button class="style1" onclick="loadModel('/resource/model/top1.glb', 'top1')">
		          		<img src="/resource/img/top1.png" alt="top1" />
		        	</button>
		        	<button class="style2" onclick="loadModel('/resource/model/top2.glb', 'top2')">
		          		<img src="/resource/img/top2.png" alt="top2" />
		          	</button>
		          	<button class="style3" onclick="loadModel('/resource/model/top3.glb', 'top3')">
		          		<img src="/resource/img/top3.png" alt="top3" />
		        	</button>
		        	<button class="style3" onclick="loadModel('/resource/model/top4.glb', 'top4')">
		          		<img src="/resource/img/top4.png" alt="top4" />
		        	</button>
	        	</div>
	        	<div class="style-Wrap">
		        	<button class="style4" onclick="loadModel('/resource/model/top5.glb', 'top5')">
		          		<img src="/resource/img/top5.png" alt="top5" />
		        	</button>
		        	<button class="style5" onclick="loadModel('/resource/model/top6.glb', 'top6')">
		          		<img src="/resource/img/top6.png" alt="top6" />
		        	</button>
		        	<button class="style6" onclick="loadModel('/resource/model/top7.glb', 'top7')">
		          		<img src="/resource/img/top7.png" alt="top7" />
		        	</button>
		        	<button class="style6" onclick="loadModel('/resource/model/top8.glb', 'top8')">
		          		<img src="/resource/img/top8.png" alt="top8" />
		        	</button>
		        </div>
          </div>`;
          
      } else if (option === 'bottom') {
    	  
          html = `
            <h3>Color</h3>
            	<div class="color-picker">
	              	<button class="color1"></button>
	                <button class="color2"></button>
	                <button class="color3"></button>
	                <button class="color4"></button>
	                <button class="color5"></button>
	                <button class="color6"></button>
            	</div>
              
	            <div class="line"></div>
            	<div class="style-select">
            		<div class="style-Wrap">
		            	<button class="style1" onclick="loadModel('/resource/model/bottom1.glb', 'bottom1')">
			          		<img src="/resource/img/bottom1.png" alt="bottom1" />
			        	</button>
			        	<button class="style2" onclick="loadModel('/resource/model/bottom2.glb', 'bottom2')">
			          		<img src="/resource/img/bottom2.png" alt="bottom2" />
			        	</button>
			        	<button class="style3" onclick="loadModel('/resource/model/bottom3.glb', 'bottom3')">
			          		<img src="/resource/img/bottom3.png" alt="bottom3" />
			        	</button>
			        	<button class="style3" onclick="loadModel('/resource/model/bottom4.glb', 'bottom4')">
			          		<img src="/resource/img/bottom4.png" alt="bottom4" />
			        	</button>
		        	</div>
		        	<div class="style-Wrap">
			        	<button class="style4" onclick="loadModel('/resource/model/bottom5.glb', 'bottom5')">
			          		<img src="/resource/img/bottom5.png" alt="bottom5" />
			        	</button>
			        	<button class="style5" onclick="loadModel('/resource/model/bottom6.glb', 'bottom6')">
			          		<img src="/resource/img/bottom6.png" alt="bottom6" />
			        	</button>
			          	<button class="style6" onclick="loadModel('/resource/model/bottom7.glb', 'bottom7')">
			          		<img src="/resource/img/bottom7.png" alt="bottom7" />
			          	</button>
			          	<button class="style6" onclick="loadModel('/resource/model/bottom8.glb', 'bottom8')">
			          		<img src="/resource/img/bottom8.png" alt="bottom8" />
			          	</button>
		          	</div>
              </div>`;
              
      } else if (option === 'dress') {
    	  
	          html = `
	              <h3>Color</h3>
	              <div class="color-picker">
		              <button class="color1"></button>
		              <button class="color2"></button>
		              <button class="color3"></button>
		              <button class="color4"></button>
		              <button class="color5"></button>
		              <button class="color6"></button>
	              </div>
	              
		          <div class="line"></div>
	              <div class="style-select">
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
					<h3>Color</h3>
					<div class="color-picker">
		                <button class="color1"></button>
		                <button class="color2"></button>
		                <button class="color3"></button>
		                <button class="color4"></button>
		                <button class="color5"></button>
		                <button class="color6"></button>
	              	</div>
	              
		          	<div class="line"></div>
	              	<div class="style-select">
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
					<h3>Color</h3>
						<div class="color-picker">
	                    <button class="color1"></button>
	                    <button class="color2"></button>
	                    <button class="color3"></button>
	                    <button class="color4"></button>
	                    <button class="color5"></button>
	                    <button class="color6"></button>
					</div>
                  
					<div class="line"></div>
					<div class="style-select">
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
				          	<button class="style3" onclick="loadModel('/resource/model/accessory4.glb', 'accessory4')">
				          		<img src="/resource/img/accessory4.png" alt="accessory4" />
				          	</button>
						</div>
						<div class="style-Wrap">
				          	<button class="style4" onclick="loadModel('/resource/model/accessory5.glb', 'accessory5')">
				          		<img src="/resource/img/accessory5.png" alt="accessory5" />
				          	</button>
				          	<button class="style5" onclick="loadModel('/resource/model/accessory6.glb', 'accessory6')">
				          		<img src="/resource/img/accessory6.png" alt="accessory6" />
				          	</button>
				          	<button class="style6" onclick="loadModel('/resource/model/accessory7.glb', 'accessory7')">
				          		<img src="/resource/img/accessory7.png" alt="accessory7" />
				          	</button>
				          	<button class="style6" onclick="loadModel('/resource/model/accessory8.glb', 'accessory8')">
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
  setSkinColor('#FFE0BD');
  });

function resetAvatar() {
  for (let key in currentParts) {
    if (currentParts[key]) {
      scene.remove(currentParts[key]);
      currentParts[key] = null;
    }
  }
  setSkinColor('#FFE0BD');
  updateSelectBox('skin-face');

//hidden input 초기화
  const inputs = ['skin_face', 'hair', 'top', 'bottom', 'dress', 'shoes', 'accessory'];
  inputs.forEach(id => {
    const input = document.getElementById(`input-${id}`);
    if (input) input.value = "";
  });

  console.log('🔄 아바타 초기화 완료!');
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

			<form action="/usr/custom/save" method="post" id="customForm">
				<input type="hidden" name="skin_face" id="input-skin_face"/>
				<input type="hidden" name="hair" id="input-hair"/>
				<input type="hidden" name="top" id="input-top"/>
				<input type="hidden" name="bottom" id="input-bottom"/>
				<input type="hidden" name="dress" id="input-dress"/>
				<input type="hidden" name="shoes" id="input-shoes"/>
				<input type="hidden" name="accessory" id="input-accessory"/>
				
				<div class="btn_box">
					<button type="button" onclick="resetAvatar()">RESET</button>
					<button type="submit">SAVE</button>
				</div>
			</form>
			
			<!-- ✅ script는 form 아래에 위치시켜야 함 -->
			<script>
			  function loadModel(path, partStyleKey) {
			    console.log('✅ loadModel 실행됨: ', path, partStyleKey);
			
			    // 숫자 제거
			    let partGroupKey = partStyleKey.replace(/[0-9]/g, '');
			
			    // face는 예외 처리
			    if (partGroupKey === 'face') {
			      partGroupKey = 'skin_face';
			    }
			
			    const inputId = 'input-' + partGroupKey;
			    const hiddenInput = document.getElementById(inputId);
			
			    console.log('🔍 hidden input: ', hiddenInput);
			
			    if (hiddenInput) {
			      hiddenInput.value = path;
			      console.log('✅ 저장됨! →', path);
			    } else {
			      console.warn('❌ hidden input 못 찾음: ', inputId);
			    }
			
			    // glb 파일 로딩 (예시)
			    const loader = new THREE.GLTFLoader();
			    loader.load(
			      path,
			      function (gltf) {
			        console.log('GLTF 로드 완료:', gltf);
			        // ...모델 처리 로직...
			      },
			      undefined,
			      function (error) {
			        console.error('GLTF 로드 실패:', error);
			      }
			    );
			  }
			</script>

		</div>
	</div>
</div>



<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>