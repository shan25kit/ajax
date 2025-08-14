
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
		this.NAME_TAG_OFFSET = 23;      // ← 머리 위로 올리는 높이(로컬 단위). 숫자 키우면 더 ↑
		this.NAME_TAG_SCALE  = { x: 9.0, y: 2.8 }; // ← 닉네임 스프라이트 크기. 필요시 더 키워

		console.log('📦 CharacterRenderModule 생성됨');
	}
	// ✅ 닉네임 스프라이트(텍스트만) 생성 - 말풍선 없음
	createNameLabel(text) {
	  const canvas = document.createElement('canvas');
	  const dpr = window.devicePixelRatio || 1;
	  const W = 1400, H = 350;                // 넉넉한 캔버스
	  canvas.width = W * dpr;
	  canvas.height = H * dpr;

	  const ctx = canvas.getContext('2d');
	  ctx.scale(dpr, dpr);

	  // 패딩 & 폰트
	  const PAD_X = 60;
	  const PAD_Y = 90;                        // 상단 여유 ↑
	  const FONT_SIZE = 280;                   // 글씨 크게
	  ctx.font = `bold ${FONT_SIZE}px system-ui, Apple SD Gothic Neo, Segoe UI, Arial`;
	  ctx.textAlign = 'center';
	  ctx.textBaseline = 'alphabetic';

	  const metrics = ctx.measureText(text);
	  const ascent  = metrics.actualBoundingBoxAscent || FONT_SIZE * 0.8;
	  const descent = metrics.actualBoundingBoxDescent || FONT_SIZE * 0.2;
	  const textH   = ascent + descent;
	  const usableH = H - PAD_Y * 2;
	  const baseY   = PAD_Y + (usableH - textH) / 2 + ascent;

	  // 외곽선 + 본문
	  ctx.strokeStyle = 'rgba(0,0,0,1)';
	  ctx.lineWidth = 20;
	  ctx.strokeText(text, W/2, baseY);
	  ctx.fillStyle = '#ffffff';
	  ctx.fillText(text, W/2, baseY);

	  const texture = new THREE.CanvasTexture(canvas);
	  texture.needsUpdate = true;
	  texture.anisotropy = 8;

	  const material = new THREE.SpriteMaterial({
	    map: texture,
	    transparent: true,
	    depthTest: false,
	    depthWrite: false,
	    sizeAttenuation: false,                // ✅ 거리와 상관없이 동일한 화면 크기!
	  });

	  const sprite = new THREE.Sprite(material);
	  sprite.center.set(0.5, 0);            // ✅ 아래(바닥) 기준 → 위로 잘림 방지
	  // ✅ 크기: 상수 사용 (원하면 this.NAME_TAG_SCALE만 바꾸면 됨)
	  sprite.scale.set(this.NAME_TAG_SCALE.x, this.NAME_TAG_SCALE.y, 1);
	
	  sprite.renderOrder = 999;
	  sprite.userData.isNameLabel = true;
	  return sprite;
	}
	
	// 닉네임 스프라이트의 "화면 좌표(뷰포트 기준 px)" 구하기
	getNameLabelScreenPos(sessionId) {
	  const inst = this.playerRenderInstances.get(sessionId);
	  const character = this.playerCharacters.get(sessionId);
	  if (!inst || !character) return null;

	  const tag = character.userData?.nameLabel;
	  const cam = inst.threeInstance?.getCamera?.() || inst.threeInstance?.camera;
	  const canvas = inst.threeInstance?.getCanvas?.() || inst.canvas;
	  if (!tag || !cam || !canvas) return null;

	  // 닉네임 스프라이트의 월드 좌표 → NDC → 화면(px)
	  const p = new THREE.Vector3();
	  tag.getWorldPosition(p);
	  p.project(cam);

	  const rect = canvas.getBoundingClientRect(); // 캔버스의 화면상 위치/크기
	  const x = (p.x * 0.5 + 0.5) * rect.width  + rect.left;
	  const y = (-p.y * 0.5 + 0.5) * rect.height + rect.top;

	  return { x, y }; // 뷰포트 기준 좌표
	}

	
	// 캐릭터의 "로컬" 높이 계산 (회전/카메라 영향 없음)
	computeLocalHeight(character) {
	  character.updateWorldMatrix(true, true);
	  const inv = new THREE.Matrix4().copy(character.matrixWorld).invert();
	  const localBox = new THREE.Box3();

	  character.traverse((child) => {
	    if (!(child.isMesh || child.isSkinnedMesh) || !child.geometry) return;

	    if (!child.geometry.boundingBox) child.geometry.computeBoundingBox();
	    const box = child.geometry.boundingBox.clone();     // child 로컬
	    box.applyMatrix4(child.matrixWorld);                // → 월드
	    box.applyMatrix4(inv);                              // → 캐릭터 로컬로 변환
	    localBox.union(box);
	  });

	  return localBox.max.y - localBox.min.y; // 로컬 높이
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

		console.log("🆔 loadCharacter 호출됨");
		    console.log("  - nickName:", nickName);
		    console.log("  - sessionId:", sessionId);
		    console.log("  - memberId:", memberId);
		    console.log("  - avatarInfo:", avatarInfo);
		
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
					
					console.log("🎯 닉네임 라벨 부착 시작:", nickName);
					
					// ✅ (중요) 로컬 높이 한 번만 계산해서 저장
					const localHeight = this.computeLocalHeight(character);
					character.userData.headHeight = localHeight;

					// ✅ 라벨 생성
					const nameLabel = this.createNameLabel(nickName);

					// 항상 보이게/가려지지 않게 (UI 성격)
					nameLabel.frustumCulled = false;
					if (nameLabel.material) {
					  nameLabel.material.depthTest = false;
					  nameLabel.material.depthWrite = false;
					  if (nameLabel.material.map) nameLabel.material.map.needsUpdate = true;
					}
					nameLabel.renderOrder = 999;

					// 🔧 스프라이트 기준점을 "아래"로 (윗부분 잘림 방지)
					nameLabel.center.set(0.5, 0.0);

					// ✅ 머리 꼭대기 + 오프셋(상수)
					nameLabel.position.set(0, localHeight + this.NAME_TAG_OFFSET, 0);

					// 캐릭터 스케일에 맞춰 라벨도 보정
//					const charScale = this.gameClient?.getCharacterConfig?.().SCALE ?? 1;
//					nameLabel.scale.multiplyScalar(charScale);

					// 캐릭터에 종속
					character.add(nameLabel);
					console.log("✅ 라벨 부착 완료, 캐릭터 children:", character.children);

					// 레퍼런스 저장(선택)
					character.userData.nameLabel = nameLabel;

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
		character.rotation.y = 0;
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

	      // ✅✅✅ 닉네임(라벨) 보정 — 여기 추가! (render() 호출 직전)
	      const cam =
	        (data.threeInstance?.getCamera && data.threeInstance.getCamera()) ||
	        data.threeInstance?.camera ||
	        null;

			// ✅ render() 호출 직전에: 라벨 위치/표시 보정
			if (cam) {
			  const tag = character.userData?.nameLabel;
			  if (tag) {
			    // 1) 로컬 기준 "머리 높이"를 한 번만 확보 (없으면 지금 계산해서 저장)
			    if (!character.userData.headHeight) {
			      if (this.computeLocalHeight) {
			        character.userData.headHeight = this.computeLocalHeight(character);
			      } else {
			        // computeLocalHeight를 아직 안 넣었다면 임시 대안 (스케일 보정 포함)
			        const tmp = new THREE.Box3().setFromObject(character);
			        const s = character.scale?.y || 1;
			        character.userData.headHeight = (tmp.max.y - tmp.min.y) / s;
			      }
			    }

			    const base = character.userData.headHeight;

				// ✅ 머리 꼭대기 + 오프셋(상수) — 숫자만 바꾸면 바로 반영됨
			    tag.position.set(0, base + (this.NAME_TAG_OFFSET ?? 1.2), 0);

			    // 3) 항상 보이게 + 컬링/깊이 문제 방지
			    tag.visible = true;
			    tag.frustumCulled = false;

			    if (!tag.userData._initDepthTuning) {
			      if (tag.material) {
			        tag.material.depthTest = false;
			        tag.material.depthWrite = false;
			        if (tag.material.map) tag.material.map.needsUpdate = true;
			      }
			      tag.renderOrder = 999;
			      tag.userData._initDepthTuning = true;
			    }

			    // ❌ 각도 기반 가시성 토글은 사용하지 않음 (측면에서 사라지는 원인)
			    // const toCam = new THREE.Vector3().subVectors(cam.position, character.position).normalize();
			    // const fwd   = new THREE.Vector3(0, 0, -1).applyQuaternion(cam.quaternion);
			    // tag.visible = toCam.dot(fwd) > 0;
			  }
			}


	      // ✅✅✅ 여기까지
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
					
					// ✅ 불투명하게 설정
					if (child.material) {
						child.material.transparent = false;
						child.material.opacity = 1.0;
						child.material.depthWrite = true;
						child.material.alphaTest = 0.5; // 알파가 있는 경우에 대비
						child.material.needsUpdate = true;
					}
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
