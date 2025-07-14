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
};

//✅ 머리색 변경 함수 (현재 선택된 hair 파트 전체에 적용)
window.setHairColor = function (hexColor) {
  const model = currentParts['hair'];
  console.log('🎨 현재 선택된 헤어:', model);

  if (!model) return;

  model.traverse((child) => {
    if (child.isMesh && child.material && child.material.color) {
      console.log('🎯 색상 적용 대상:', child.name);

      // 텍스처가 있으면 제거
      if (child.material.map) {
        child.material.map = null;
      }

   // ✅ 색상 및 불투명도 적용
      child.material.color.set(hexColor);
      child.material.transparent = false;
      child.material.opacity = 1.0;
   // ✅ 깊이 관련 문제 해결
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
  camera.position.set(0, 0, 30);
  camera.lookAt(0, 0, 0);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(containerWidth, containerHeight);
  renderer.setClearColor(0x000000, 0); // 투명 배경
  container.appendChild(renderer.domElement);

  controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.enableZoom = false;
  controls.enablePan = false;
  controls.minPolarAngle = Math.PI / 2;
  controls.maxPolarAngle = Math.PI / 2;

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
    character.scale.set(7.5, 7.5, 7.5);
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
    // 💇 헤어
    'face1': { scale: [4, 4, 4], position: [0, 9, 6], rotation: [20.4, 0, 0] },
    'hair1': { scale: [75, 75, 75], position: [0, -51.2, 0], rotation: [0, 0, 0] },
    'hair2': { scale: [7, 7, 8], position: [0, -16, -0.29], rotation: [0, 0, 0] },
    'hair3': { scale: [80.3, 75, 69], position: [0, -51.1, 1], rotation: [0, 0, 0] },
    'hair4': { scale: [75, 75, 70], position: [0, -51.1, 1], rotation: [0, 0, 0] },
    'hair5': { scale: [81, 74, 75], position: [0, -50, 0.5], rotation: [0, 0, 0] },
    'hair6': { scale: [81, 74, 73], position: [0, -50, 0], rotation: [0, 0, 0] },
    'hair7': { scale: [81, 74, 75], position: [0, -50, 1], rotation: [0, 0, 0] },
    'hair8': { scale: [81, 74, 75], position: [0, -50, 1], rotation: [0, 0, 0] },

    // 👕 상의
    'top1': { scale: [4, 4, 4], position: [0, -2, 0], rotation: [0, 0, 0] },
    'top2': { scale: [4.2, 4.2, 4.2], position: [0, -1.5, 0], rotation: [0, 0.1, 0] },

    // 👖 하의
    'bottom1': { scale: [4, 4, 4], position: [0, -8, 0], rotation: [0, 0, 0] },
    'bottom2': { scale: [4, 4, 4], position: [0, -7.5, 0], rotation: [0, 0.2, 0] },
    
    // 👗 원피스
    'dress1': { scale: [53, 53, 59], position: [0, -21.9, 0], rotation: [0, 0, 0] },
    'dress2': { scale: [4, 4, 4], position: [0, -7.5, 0], rotation: [0, 0.2, 0] },
    
    // 👟 신발
    'shoes1': { scale: [4, 4, 4], position: [0, -8, 0], rotation: [0, 0, 0] },
    'shoes2': { scale: [4, 4, 4], position: [0, -7.5, 0], rotation: [0, 0.2, 0] },

    // 🧢 액세서리
    'accessory1': { scale: [2.5, 2.5, 2.5], position: [0, 12, 1], rotation: [0, 0, 0] },
    'accessory2': { scale: [3, 3, 3], position: [0, 11, 1], rotation: [0.1, 0, 0] }
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
		        <button class="style2" onclick="loadModel('/resource/model/hair2-1.glb', 'hair2')">
		          	<img src="/resource/img/hair2.png" alt="hair2" />
		        </button>
		        <button class="style3" onclick="loadModel('/resource/model/hair3.glb', 'hair3')">
		          	<img src="/resource/img/hair3.png" alt="hair3" />
		        </button>
		        <button class="style4" onclick="loadModel('/resource/model/hair4.glb', 'hair4')">
		          	<img src="/resource/img/hair4.png" alt="hair4" />
		        </button>
         	</div>
			<div class="style-Wrap">
		        <button class="style5" onclick="loadModel('/resource/model/hair5.glb', 'hair5')">
		          	<img src="/resource/img/hair5.png" alt="hair5" />
		        </button>
		        <button class="style6" onclick="loadModel('/resource/model/hair6.glb', 'hair6')">
		          	<img src="/resource/img/hair6.png" alt="hair6" />
		        </button>
		        <button class="style7" onclick="loadModel('/resource/model/hair7.glb', 'hair7')">
		          	<img src="/resource/img/hair7.png" alt="hair7" />
		        </button>
		        <button class="style8" onclick="loadModel('/resource/model/hair8.glb', 'hair8')">
		          	<img src="/resource/img/hair8.png" alt="hair8" />
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
			        	<button class="style2" onclick="loadModel('/resource/model/dress2.glb', 'dress2')">
			          		<img src="/resource/img/dress2.png" alt="dress2" />
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
  
//✅ 리셋 함수 추가
  function resetAvatar() {
    // 씬에서 각 파츠 제거
    for (let key in currentParts) {
      if (currentParts[key]) {
        scene.remove(currentParts[key]);
        currentParts[key] = null;
      }
    }

    // 피부색 초기화
    setSkinColor('#FFE0BD');

    // 선택 박스도 초기화
    updateSelectBox('skin-face');

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

			<div class=btn_box>

				<button onclick="resetAvatar()">RESET</button>
				<button type="submit" onclick="location.href='/usr/game'">SAVE</button>

			</div>

		</div>
	</div>
</div>



<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>