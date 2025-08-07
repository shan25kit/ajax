
import { ThreeInit } from '../core/ThreeInit.js';
export class CharacterRenderModule {
	constructor(gameClient) {
		this.gameClient = gameClient;
		this.loader = null;
		this.playerCharacters = new Map();
		this.playerRenderInstances = new Map();
		this.myCharacter = null;
		// 애니메이션 관련 
		this.mixer = null;
		this.clock = new THREE.Clock();
		this.walkAction = null;
		// 모델 경로 설정
		this.ASSET_CONFIG = {
			MODEL: { base: '/resource/model/', ext: '.glb' },
			FACE: { base: '/resource/face/', ext: '.glb' }
		};

		console.log('📦 CharacterRenderModule 생성됨');
	}

	// ===== 모듈 초기화 =====
	async initialize() {
		try {
			console.log('🎨 캐릭터 렌더링 모듈 초기화');
			// THREE 객체 확인
			console.log('THREE 객체:', typeof THREE);

			// GLTFLoader 초기화
			if (typeof THREE.GLTFLoader !== 'undefined') {
				this.loader = new THREE.GLTFLoader();
				console.log('✓ GLTFLoader 초기화 완료');
			} else {
				throw new Error('GLTFLoader가 로드되지 않았습니다.');
			}

		} catch (error) {
			console.error('❌ 캐릭터 렌더링 모듈 초기화 실패:', error);
			throw error;
		}
	}

	// ===== 모델 경로 생성 =====
	getModelPath(partType, styleNumber) {
		let path;
		if (!styleNumber) return null;

		if (partType === 'face') {
			path = this.ASSET_CONFIG.FACE.base + String(partType) + String(styleNumber) + this.ASSET_CONFIG.FACE.ext;
		} else {
			path = this.ASSET_CONFIG.MODEL.base + String(partType) + String(styleNumber) + this.ASSET_CONFIG.MODEL.ext;
		}

		console.log('🔗 생성된 경로:', path);
		return path;
	}

	// ===== 캐릭터 로딩 =====
	async loadCharacter(avatarInfo, memberId, sessionId, nickName, mapName = null) {

		let threeInstance;

		const character3D = document.getElementById('character3D');
		if (!character3D) {
			console.error('❌ character3D 컨테이너를 찾을 수 없습니다.');
			return null;
		}
		const canvas = document.createElement('canvas');
		canvas.id = `canvas-${sessionId}`;

		character3D.appendChild(canvas);

		threeInstance = new ThreeInit(canvas);

		const canvasElement = threeInstance.getCanvas();
		if (canvasElement) {
			canvasElement.setAttribute('data-player-id', sessionId);
			canvasElement.setAttribute('data-player-nickname', nickName);
			canvasElement.setAttribute('data-is-my-character',
				memberId === this.gameClient.player.memberId ? 'true' : 'false');
			console.log(`🏷️ 캔버스 태그 설정 완료: ${nickName} (${sessionId})`);
		}
		return new Promise((resolve, reject) => {

			this.loader.load(
				'/resource/model/body_anim.glb',
				(gltf) => {
					const character = gltf.scene;

					// 베이스 캐릭터 설정
					this.setupBaseCharacter(character, avatarInfo, memberId, sessionId, mapName);

					// 씬에 추가
					const scene = threeInstance.getScene();
					scene.add(character);

					// 캐릭터 맵에 저장
					this.playerCharacters.set(sessionId, character);

					// 내 캐릭터인 경우 별도 저장
					if (memberId === this.gameClient.player.memberId) {
						this.myCharacter = character;
					}
					this.setupCharacterAnimations(character, gltf, sessionId, memberId === this.gameClient.player.memberId);
					this.addPlayerToRenderData(sessionId, threeInstance, memberId === this.gameClient.player.memberId);
					// 파츠 로딩
					if (avatarInfo.parts) {
						setTimeout(() => {
							this.loadCharacterParts(character, avatarInfo.parts, nickName);
						}, 50);
					}
					resolve(character);
				}, undefined, reject);

		});
	}

	// ===== 베이스 캐릭터 설정 =====
	setupBaseCharacter(character, avatarInfo, memberId, sessionId,mapName = null ) {
		console.log('=== 베이스 캐릭터 구조 분석 ===');
		console.log('Character scene:', character);
		// 스킨 색상 및 재질 설정
		character.traverse((child) => {
			if (child.isMesh && child.material && child.material.color) {
				console.log('🎨 기존 재질에 색상 적용:', avatarInfo.skinColor);
				child.material.color = new THREE.Color(avatarInfo.skinColor || 0xffe0bd);
				child.material.needsUpdate = true;
			}

		});
		const finalPosition = this.gameClient.getInitialSpawnPosition(mapName);
		console.log(`📍 ${sessionId} ${mapName || 'current'} 맵 초기 위치 사용:`, finalPosition);

		character.position.set(finalPosition.x, finalPosition.y, finalPosition.z);
		// 스케일 설정
		const characterConfig = this.gameClient.getCharacterConfig();
		const characterScale = characterConfig.SCALE;
		character.scale.set(characterScale, characterScale, characterScale);

		// 회전 설정
		character.rotation.y = Math.PI / 6;
		character.rotation.x = Math.PI / 8;

		// 사용자 데이터 저장
		character.userData = {
			memberId: memberId,
			sessionId: sessionId,
			avatarInfo: avatarInfo
		};
	}

	setupCharacterAnimations(character, gltf, sessionId, isMyCharacter) {
		console.log(`🎬 캐릭터 애니메이션 설정: ${sessionId} (내 캐릭터: ${isMyCharacter})`);

		// 렌더 인스턴스 데이터 초기화
		if (!this.playerRenderInstances.has(sessionId)) {
			this.playerRenderInstances.set(sessionId, {
				threeInstance: null,
				canvas: null,
				isMyCharacter,
				mixer: null,
				clock: new THREE.Clock(),
				walkAction: null
			});
		}

		const instance = this.playerRenderInstances.get(sessionId);

		// Mixer 설정
		instance.mixer = new THREE.AnimationMixer(character);

		if (gltf.animations && gltf.animations.length > 0) {
			console.log('📋 애니메이션 클립들:', gltf.animations.map(c => c.name));

			const walkClip = gltf.animations.find(clip =>
				clip.name === "Armature|mixamo.com|Layer0"
			);

			if (walkClip) {
				instance.walkAction = instance.mixer.clipAction(walkClip);
				instance.walkAction.loop = THREE.LoopRepeat;
				instance.walkAction.enabled = true;
				instance.walkAction.paused = true;

				console.log(`✅ ${sessionId} 애니메이션 설정 완료`);
			}
		}

		// ✅ 내 캐릭터인 경우 추가 처리 (호환성 유지)
		if (isMyCharacter) {
			// 기존 방식 호환성을 위해 클래스 변수에도 저장
			this.mixer = instance.mixer;
			this.walkAction = instance.walkAction;

			// MovementModule에 애니메이션 액션 전달
			const movementModule = this.gameClient.getCharacterMovementModule();
			if (movementModule) {
				movementModule.setMyCharacter(character);
				movementModule.setAnimationActions(instance.walkAction);
			}

			console.log('✅ 내 캐릭터 추가 설정 완료');
		}
	}

	addPlayerToRenderData(sessionId, threeInstance, isMyCharacter) {
		const instance = this.playerRenderInstances.get(sessionId);
		if (instance) {
			instance.threeInstance = threeInstance;
			instance.canvas = threeInstance.getCanvas();
		}

		console.log(`➕ 플레이어 렌더 데이터에 추가: ${sessionId} (내 캐릭터: ${isMyCharacter})`);

	}

	updateAllPlayersAnimation(delta) {
		// 모든 플레이어 순회 처리
		this.playerRenderInstances.forEach((data, sessionId) => {
			// 🎬 애니메이션 업데이트
			if (data.mixer) {
				data.mixer.update(delta);
			}
			const character = this.playerCharacters.get(sessionId);
			if (character) {
				// 파츠 애니메이션 업데이트
				character.traverse(child => child.userData?.mixer?.update(delta));

				// 🆕 본 위치 동기화 (1줄)
				character.traverse(child => {
					if (child.isSkinnedMesh) {
						child.skeleton?.bones.forEach(bone => {
							if (bone.userData.baseBone) {
								bone.matrix.copy(bone.userData.baseBone.matrix);
							}
						});
					}
				});
			}
			// 🖼️ 렌더링
			if (data.threeInstance) {
				data.threeInstance.render();
			}
		});
	}

	startPlayerWalkAnimation(sessionId) {
		const instance = this.playerRenderInstances.get(sessionId);
		const character = this.playerCharacters.get(sessionId);
		if (instance?.walkAction && !instance.walkAction.isRunning()) {
			instance.walkAction.reset().play();
			console.log(`🚶‍♀️ ${sessionId} 걷기 애니메이션 시작`);
		}
		if (character) {
			character.traverse(child => {
				if (child.userData?.walkAction) {
					/*	console.log(`🎭 파츠 애니메이션 확인: ${child.name}`);
						console.log('  - walkAction 있음:', !!child.userData.walkAction);
						console.log('  - 현재 실행중:', child.userData.walkAction.isRunning());
	*/
					if (!child.userData.walkAction.isRunning()) {
						child.userData.walkAction.reset().play();
						/*	console.log(`  ✅ ${child.name} 애니메이션 시작됨`);*/
					}
				} else {
					/*	console.log(`❌ ${child.name} - walkAction 없음`);*/
				}
			});
		}
	}

	stopPlayerWalkAnimation(sessionId) {
		const instance = this.playerRenderInstances.get(sessionId);
		const character = this.playerCharacters.get(sessionId);
		if (instance?.walkAction && instance.walkAction.isRunning()) {
			instance.walkAction.stop();
			/*	console.log(`⏹️ ${sessionId} 걷기 애니메이션 정지`);*/
		}
		// 🆕 파츠 애니메이션도 정지
		if (character) {
			character.traverse(child => {
				if (child.userData?.walkAction && child.userData.walkAction.isRunning()) {
					child.userData.walkAction.stop();
				}
			});
		}
	}
	// ===== 캐릭터 파츠 로딩 =====
	loadCharacterParts(character, parts, nickName) {
		console.log('캐릭터 파츠 로딩 시작:', nickName, parts);
		console.log('📊 파츠 키들:', Object.keys(parts));

		// 모든 파츠를 순회하면서 로딩
		for (const [partType, partData] of Object.entries(parts)) {
			if (partType === 'accessory') {
				// accessory는 main 배열과 detail 단일로 구성
				partData.main?.forEach((item, i) => {
					if (item?.style) {
						this.loadPart(character, 'accessory', item, 'main');
					}
				});

				// detail 단일
				if (partData.detail?.style) {
					this.loadPart(character, 'accessory', partData.detail, 'detail');
				}
			} else if (partData?.style) {
				// 일반 파츠
				this.loadPart(character, partType, partData);
			}
		}
	}

	// ===== 개별 파츠 로딩 =====
	loadPart(character, partType, partData, subType = null) {
		const modelPath = this.getModelPath(partType, partData.style);
		const name = subType ? `${partType}.${subType}` : partType;

		this.loader.load(modelPath, (gltf) => {
			const model = gltf.scene;

			// 🆕 베이스 캐릭터의 본 찾기
			let baseBones = null;
			character.traverse(child => {
				if (child.isSkinnedMesh && child.skeleton) {
					baseBones = child.skeleton.bones;
				}
			});

			let hasSkinnedMesh = false;

			model.traverse((child) => {

				if (child.isMesh) {
					console.log(`    Mesh: ${child.name}`, child.geometry, child.material);
				}

				if (child.isSkinnedMesh) {
					hasSkinnedMesh = true;


					// 🆕 파츠 애니메이션 설정
					if (gltf.animations && gltf.animations.length > 0) {
						console.log('  - 애니메이션 개수:', gltf.animations.length);
						console.log('  - 애니메이션 이름들:', gltf.animations.map(a => a.name));
						const mixer = new THREE.AnimationMixer(child);
						const walkClip = gltf.animations.find(clip =>
							clip.name === "Armature|mixamo.com|Layer0"
						);
						if (walkClip) {
							const action = mixer.clipAction(walkClip);
							action.loop = THREE.LoopRepeat;
							action.enabled = true;
							action.paused = true;
							child.userData.mixer = mixer;
							child.userData.walkAction = action;
						}
					}

					// 🆕 파츠 본을 베이스와 연결
					if (baseBones && child.skeleton) {
						child.skeleton.bones.forEach((partBone, i) => {
							if (baseBones[i]) {
								partBone.userData.baseBone = baseBones[i];
							}
						});
						/*console.log(`🔗 ${name} 본 연결 완료`);*/
					}
				}

				if (child.isBone) {
				}
			});

			// 색상 적용 (있는 경우)
			if (partData.color) {
				model.traverse((child) => {
					if (child.isMesh && child.material && child.material.color) {
						if (child.material.map) child.material.map = null;
						child.material.color.set(partData.color);
						child.material.needsUpdate = true;
					}
				});
			}

			/*	// SkinnedMesh가 없는 경우에만 기존 위치 설정 적용
				if (!hasSkinnedMesh) {
					this.applyPartSettings(model, partType, character, subType);
				}*/
			console.log(`🔍 ${name} 최종 상태:`, {
				position: model.position,
				scale: model.scale,
				visible: model.visible,
				children: model.children.length
			});
			model.traverse(child => {
				if (child.isMesh) {
					console.log(`  - 메시: ${child.name}`, {
						visible: child.visible,
						geometry: child.geometry,
						material: child.material
					});
				}
			});
			// 캐릭터에 추가
			character.add(model);
			console.log(`${name} 로딩 완료`);

		}, undefined, (error) => {
			console.error(`${name} 로딩 실패:`, error);
		});
	}
	analyzePartStructure(gltf, partName) {
		console.log(`\n🔬 ===== ${partName} 상세 구조 분석 =====`);

		// 1. 전체 씬 정보
		console.log('📊 전체 정보:');
		console.log('  - 씬 이름:', gltf.scene.name);
		console.log('  - 애니메이션 개수:', gltf.animations?.length || 0);
		console.log('  - 직접 자식 개수:', gltf.scene.children.length);

		// 2. 애니메이션 정보
		if (gltf.animations && gltf.animations.length > 0) {
			console.log('\n🎬 애니메이션 정보:');
			gltf.animations.forEach((anim, i) => {
				console.log(`  ${i}: ${anim.name} (${anim.duration}초, ${anim.tracks.length}개 트랙)`);
			});
		}

		// 3. 전체 계층 구조
		console.log('\n🌳 전체 계층 구조:');
		this.printHierarchy(gltf.scene, 0);

		// 4. 메시 상세 정보
		console.log('\n🎭 메시 상세 정보:');
		const meshes = [];
		gltf.scene.traverse(child => {
			if (child.isMesh) {
				meshes.push(child);
			}
		});

		meshes.forEach((mesh, i) => {
			console.log(`  ${i}: ${mesh.name}`);
			console.log(`     - 타입: ${mesh.type}`);
			console.log(`     - SkinnedMesh: ${mesh.isSkinnedMesh}`);
			console.log(`     - 지오메트리: ${mesh.geometry?.type}`);
			console.log(`     - 버텍스 수: ${mesh.geometry?.attributes?.position?.count || 0}`);
			console.log(`     - 머티리얼: ${mesh.material?.type || 'null'}`);
			console.log(`     - 위치: (${mesh.position.x.toFixed(2)}, ${mesh.position.y.toFixed(2)}, ${mesh.position.z.toFixed(2)})`);
			console.log(`     - 스케일: (${mesh.scale.x.toFixed(2)}, ${mesh.scale.y.toFixed(2)}, ${mesh.scale.z.toFixed(2)})`);
			console.log(`     - 보이기: ${mesh.visible}`);

			if (mesh.isSkinnedMesh) {
				console.log(`     - 스켈레톤: ${!!mesh.skeleton}`);
				console.log(`     - 본 개수: ${mesh.skeleton?.bones?.length || 0}`);
			}
		});

		// 5. 본 상세 정보
		console.log('\n🦴 본(Bone) 상세 정보:');
		const bones = [];
		gltf.scene.traverse(child => {
			if (child.isBone) {
				bones.push(child);
			}
		});

		if (bones.length > 0) {
			bones.forEach((bone, i) => {
				console.log(`  ${i}: ${bone.name}`);
				console.log(`     - 위치: (${bone.position.x.toFixed(2)}, ${bone.position.y.toFixed(2)}, ${bone.position.z.toFixed(2)})`);
				console.log(`     - 회전: (${bone.rotation.x.toFixed(2)}, ${bone.rotation.y.toFixed(2)}, ${bone.rotation.z.toFixed(2)})`);
				console.log(`     - 자식 본: ${bone.children.filter(c => c.isBone).length}개`);
			});
		} else {
			console.log('  본이 없습니다.');
		}

		// 6. 스켈레톤 정보
		const skinnedMeshes = meshes.filter(m => m.isSkinnedMesh);
		if (skinnedMeshes.length > 0) {
			console.log('\n🩻 스켈레톤 정보:');
			skinnedMeshes.forEach((mesh, i) => {
				if (mesh.skeleton) {
					console.log(`  SkinnedMesh ${i} (${mesh.name}) 스켈레톤:`);
					console.log(`     - 본 개수: ${mesh.skeleton.bones.length}`);
					console.log(`     - 본 목록:`);
					mesh.skeleton.bones.forEach((bone, bi) => {
						console.log(`       ${bi}: ${bone.name}`);
					});
				}
			});
		}

		console.log(`===== ${partName} 분석 완료 =====\n`);
	}

	// 계층 구조 출력 헬퍼
	printHierarchy(object, depth = 0) {
		const indent = '  '.repeat(depth);
		const type = object.isSkinnedMesh ? 'SkinnedMesh' :
			object.isMesh ? 'Mesh' :
				object.isBone ? 'Bone' :
					object.type;

		console.log(`${indent}├─ ${object.name || 'unnamed'} (${type})`);

		if (object.isMesh) {
			console.log(`${indent}│  └─ visible: ${object.visible}, material: ${!!object.material}`);
		}

		object.children.forEach((child, i) => {
			this.printHierarchy(child, depth + 1);
		});
	}
	// ===== 파츠별 위치/스케일 설정 =====
	applyPartSettings(model, partType, character, subType) {
		const baseScale = character.scale.x * 75;

		switch (partType) {
			case 'hair':
				model.scale.set(baseScale * 1.6, baseScale * 1.6, baseScale * 1.6);
				model.position.set(0, -13, 0);
				break;

			case 'accessory':
				if (subType === 'main') {
					model.scale.set(baseScale * 1.5, baseScale * 1.5, baseScale * 1.5);
					model.position.set(0, -9, 0);
				} else if (subType === 'detail') {
					model.scale.set(baseScale * 0.3, baseScale * 0.3, baseScale * 0.3);
					model.position.set(0, -10, 0);
				} else {
					model.scale.set(baseScale, baseScale, baseScale);
					model.position.set(0, -4, 0);
				}
				break;

			case 'dress':
			case 'top':
				model.scale.set(baseScale * 1.6, baseScale * 1.6, baseScale * 1.6);
				model.position.set(0, 5, 0);
				break;

			case 'bottom':
			case 'shoes':
			default:
				model.scale.set(baseScale * 0.3, baseScale * 0.2, baseScale * 0.2);
				model.position.set(0, -4, 0);
				break;
		}

		console.log(`⚙️ ${partType}${subType ? '.' + subType : ''} 설정 적용:`, {
			scale: model.scale,
			position: model.position
		});
	}

	// ===== 플레이어 위치 업데이트 =====
	updatePlayerPosition(sessionId, position) {
		console.log('=== 위치 업데이트 시도 ===');
		console.log('새 위치:', position);
		console.log('찾는 sessionId:', sessionId);

		const character = this.playerCharacters.get(sessionId);
		if (character) {
			character.position.set(position.x, position.y, position.z);
			console.log('위치 업데이트 완료');
		} else {
			console.log('캐릭터를 찾을 수 없음!');
			console.log('playerCharacters 목록:', this.playerCharacters);
		}
	}
	updatePlayerRotation(sessionId, rotation) {
		console.log(`🧭 ${sessionId} 회전 업데이트:`, rotation);

		const character = this.playerCharacters.get(sessionId);
		if (character) {
			character.rotation.set(rotation.x, rotation.y, rotation.z);

			// 디버깅용 각도 출력
			const degrees = (rotation.y * 180 / Math.PI).toFixed(1);
			console.log(`✅ ${sessionId} 회전 적용: ${degrees}도`);
		} else {
			console.log(`❌ ${sessionId} 캐릭터를 찾을 수 없음`);
			console.log('현재 캐릭터 목록:', Array.from(this.playerCharacters.keys()));
		}
	}


	clearAllRenderInstances() {
		console.log('🧹 모든 렌더 인스턴스 정리 (맵 변경)');

		this.playerRenderInstances.forEach((instance, sessionId) => {
			if (instance.threeInstance) {
				instance.threeInstance.dispose();
			}
			if (instance.canvas && instance.canvas.parentNode) {
				instance.canvas.parentNode.removeChild(instance.canvas);
			}
		});

		// 캐릭터 데이터만 정리 (loader는 유지)
		this.playerRenderInstances.clear();
		this.playerCharacters.clear();
		this.myCharacter = null;
		this.mixer = null;
		this.walkAction = null;

		console.log('✅ 렌더 인스턴스 정리 완료 (맵 변경)');
	}
	// ===== 플레이어 제거 =====
	removePlayer(sessionId) {
		const character = this.playerCharacters.get(sessionId);
		if (character) {
			this.playerCharacters.delete(sessionId);

			if (this.myCharacter === character) {
				this.myCharacter = null;
			}
		}

		// 🆕 렌더 인스턴스 제거
		const instance = this.playerRenderInstances.get(sessionId);
		if (instance) {
			if (instance.canvas && instance.canvas.parentNode) {
				instance.canvas.parentNode.removeChild(instance.canvas);
			}
			if (instance.threeInstance) {
				instance.threeInstance.dispose();
			}
			this.playerRenderInstances.delete(sessionId);
		}
	}

	// ===== 내 캐릭터 반환 =====
	getMyCharacter() {
		return this.myCharacter;
	}

	// ===== 특정 캐릭터 반환 =====
	getCharacter(sessionId) {
		return this.playerCharacters.get(sessionId);
	}

	// ===== 모든 캐릭터 반환 =====
	getAllCharacters() {
		return this.playerCharacters;
	}

	// ===== 리소스 정리 =====
	dispose() {
		console.log('🧹 캐릭터 렌더링 모듈 정리');

		// 🆕 모든 렌더 인스턴스 정리
		this.playerRenderInstances.forEach((instance, sessionId) => {
			if (instance.threeInstance) {
				instance.threeInstance.dispose();
			}
			if (instance.canvas && instance.canvas.parentNode) {
				instance.canvas.parentNode.removeChild(instance.canvas);
			}
		});

		// 맵 정리
		this.playerCharacters.clear();
		this.playerRenderInstances.clear(); // 🆕 추가
		this.myCharacter = null;
		this.mixer = null;        // 🆕 추가
		this.walkAction = null;   // 🆕 추가
		this.loader = null;

		console.log('✅ 캐릭터 렌더링 모듈 정리 완료');
	}
}
