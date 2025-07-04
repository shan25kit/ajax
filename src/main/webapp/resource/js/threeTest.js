//// ✅ 외부 CDN에서 three.js, GLTFLoader를 불러옴
//import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.150.1/build/three.module.js';
//import { GLTFLoader } from 'https://cdn.jsdelivr.net/npm/three@0.150.1/examples/jsm/loaders/GLTFLoader.js';
//
//
//const scene = new THREE.Scene();
//const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
//const renderer = new THREE.WebGLRenderer({ antialias: true });
//renderer.setSize(window.innerWidth, window.innerHeight);
//document.getElementById('three-container').appendChild(renderer.domElement);
//
//
//const light = new THREE.DirectionalLight(0xffffff, 1);
//light.position.set(1, 1, 1);
//scene.add(light);
//
//const loader = new GLTFLoader();
//loader.load('/resource/model/hair3.glb', function (gltf) {
//  scene.add(gltf.scene);
//  gltf.scene.position.set(0, 0, 0);
//  animate();
//});
//
//camera.position.z = 3;
//
//function animate() {
//  requestAnimationFrame(animate);
//  renderer.render(scene, camera);
//}
//
//window.addEventListener('resize', () => {
//  camera.aspect = window.innerWidth / window.innerHeight;
//  camera.updateProjectionMatrix();
//  renderer.setSize(window.innerWidth, window.innerHeight);
//});
