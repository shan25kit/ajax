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

// ✅ 머리색 변경 함수 (현재 선택된 hair만 적용)
window.setHairColor = function (hexColor) {
  const model = currentParts['hair'];
  if (!model) return;

  model.traverse((child) => {
    if (child.isMesh && child.material && child.material.color) {
      child.material.color.set(hexColor);
      child.material.needsUpdate = true;
    }
  });
};

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('three-container');
  const containerWidth = container.clientWidth;
  const containerHeight = container.clientHeight;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(75, containerWidth / containerHeight, 0.1, 950);
  camera.position.set(0, 0, 30);
  camera.lookAt(0, 0, 0);

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(containerWidth, containerHeight);
  renderer.setClearColor(0x000000, 0); // 투명 배경
  container.appendChild(renderer.domElement);

  const controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.enableZoom = false;
  controls.enablePan = false;
  controls.minPolarAngle = Math.PI / 2;
  controls.maxPolarAngle = Math.PI / 2;

  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambientLight);

  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.5);
  directionalLight.position.set(0, 0, 1);
  scene.add(directionalLight);

  function updateLightPosition() {
    directionalLight.position.copy(camera.position);
    directionalLight.target.position.set(0, 0, 0);
    directionalLight.target.updateMatrixWorld();
  }

  // ✅ 캐릭터 본체 로딩
  loader.load('/resource/images/body.glb', (gltf) => {
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
    const partGroupKey = partStyleKey.replace(/[0-9]/g, ''); // 예: hair1 → hair

    // 기존 파트 제거
    if (currentParts[partGroupKey]) {
      scene.remove(currentParts[partGroupKey]);
    }

    loader.load(path, (gltf) => {
      const model = gltf.scene;

      // 🎯 파트별 설정
      const partSettings = {
        // 💇 헤어
        'face1': { scale: [9, 9, 9], position: [0, 0, 40], rotation: [0, 0, 0] },
        'hair1': { scale: [7.6, 7.5, 7.5], position: [-29.2, -22.7, 37.2], rotation: [0, 0, 0] },
        'hair2': { scale: [7.5, 7.5, 7.5], position: [0, 13, 1], rotation: [0, 0, 0] },
        'hair3': { scale: [8, 8, 8], position: [0, 14.5, 0.5], rotation: [0, 0, 0] },

        // 👕 상의
        'top1': { scale: [4, 4, 4], position: [0, -2, 0], rotation: [0, 0, 0] },
        'top2': { scale: [4.2, 4.2, 4.2], position: [0, -1.5, 0], rotation: [0, 0.1, 0] },

        // 👖 하의
        'bottom1': { scale: [4, 4, 4], position: [0, -8, 0], rotation: [0, 0, 0] },
        'bottom2': { scale: [4, 4, 4], position: [0, -7.5, 0], rotation: [0, 0.2, 0] },

        // 🧢 액세서리
        'accessory1': { scale: [2.5, 2.5, 2.5], position: [0, 12, 1], rotation: [0, 0, 0] },
        'accessory2': { scale: [3, 3, 3], position: [0, 11, 1], rotation: [0.1, 0, 0] }
      };

      const setting = partSettings[partStyleKey] || {
        scale: [4, 4, 4],
        position: [0, 0, 0],
        rotation: [0, 0, 0]
      };

      model.scale.set(...setting.scale);
      model.position.set(...setting.position);
      model.rotation.set(...setting.rotation);

      scene.add(model);
      currentParts[partGroupKey] = model;
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
        
        <div class="style-select">
        
          <div class="line"></div>
        
          <button class="style1" onclick="loadModel('/resource/model/face1.glb', 'face1')"></button>
          <button class="style2"></button>
          <button class="style3"></button>
          <br/>
          <button class="style4"></button>
          <button class="style5"></button>
          <button class="style6"></button>
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
          
          <div class="style-select">

	          <div class="line"></div>
	        
	          <button class="style1" onclick="loadModel('/resource/model/hair1.glb', 'hair1')"></button>
	          <button class="style2" onclick="loadModel('/resource/model/hair2.glb', 'hair2')"></button>
	          <button class="style3" onclick="loadModel('/resource/model/hair3.glb', 'hair3')"></button>
	          <br/>
	          <button class="style4"></button>
	          <button class="style5"></button>
	          <button class="style6"></button>
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
          
          <div class="style-select">

	          <div class="line"></div>
	        
	          <button class="style1"></button>
	          <button class="style2"></button>
	          <button class="style3"></button>
	          <br/>
	          <button class="style4"></button>
	          <button class="style5"></button>
	          <button class="style6"></button>
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
              
              <div class="style-select">
	
	              <div class="line"></div>
	            
	              <button class="style1"></button>
	              <button class="style2"></button>
	              <button class="style3"></button>
	              <br/>
	              <button class="style4"></button>
	              <button class="style5"></button>
	              <button class="style6"></button>
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
                  
                  <div class="style-select">
	
	                  <div class="line"></div>
	                
	                  <button class="style1"></button>
	                  <button class="style2"></button>
	                  <button class="style3"></button>
	                  <br/>
	                  <button class="style4"></button>
	                  <button class="style5"></button>
	                  <button class="style6"></button>
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
    document.querySelector('.accessory').addEventListener('click', () => updateSelectBox('accessory'));
    
  updateSelectBox('skin-face');
  setSkinColor('#FFE0BD');
  });
  
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
					onclick="loadModel('/resource/model/face1.glb', 'skin-face')"></button>
				<button class="hair"
					onclick="loadModel('/resource/model/hair1.glb', 'hair1')"></button>
				<button class="top"
					onclick="loadModel('/resource/model/top.glb', 'top')"></button>
				<button class="bottom"
					onclick="loadModel('/resource/model/bottom.glb', 'bottom')"></button>
				<button class="accessory"
					onclick="loadModel('/resource/model/accessory.glb', 'accessory')"></button>
			</div>


			<div class="custom-select-box" id="select-box"></div>

			<div class=btn_box>
				<button type="submit" onclick="location.href='/usr/game'">RESET</button>
				<button type="submit" onclick="location.href='/usr/game'">SAVE</button>
			</div>

		</div>




	</div>
</div>



<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>