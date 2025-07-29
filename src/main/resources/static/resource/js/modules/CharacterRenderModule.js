

export class CharacterRenderModule {
	constructor(gameClient) {
		this.gameClient = gameClient;
		this.loader = null;
		this.playerCharacters = new Map();
		this.myCharacter = null;
		// 애니메이션 관련 (내 캐릭터만)
		this.mixer = null;
		this.clock = new THREE.Clock();
		this.walkAction = null;
		// 모델 경로 설정
		this.ASSET_CONFIG = {
			MODEL: { base: '/resource/model/', ext: '.glb' }
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
		if (!styleNumber) return null;

		const path = this.ASSET_CONFIG.MODEL.base + String(partType) + String(styleNumber) + this.ASSET_CONFIG.MODEL.ext;
		console.log('🔗 생성된 경로:', path);
		return path;
	}

	// ===== 캐릭터 로딩 =====
	async loadCharacter(avatarInfo, position, memberId, sessionId, nickName) {
		return new Promise((resolve, reject) => {
			console.log('=== 캐릭터 로딩 시작 ===');
			console.log('닉네임:', nickName);
			console.log('멤버ID:', memberId);
			console.log('세션ID:', sessionId);
			console.log('위치:', position);
			console.log('아바타 정보:', avatarInfo);

			this.loader.load(
				'/resource/model/body_anim.glb',
				(gltf) => {
					console.log('✓ 베이스 모델 로드 성공:', nickName);
					const character = gltf.scene;


					// 베이스 캐릭터 설정
					const { bodySkeleton, bodySkinnedMesh } = this.setupBaseCharacter(character, avatarInfo, position, memberId, sessionId);

					// 씬에 추가
					const scene = this.gameClient.getScene();
					scene.add(character);

					// 캐릭터 맵에 저장
					this.playerCharacters.set(sessionId, character);

					// 내 캐릭터인 경우 별도 저장
					if (memberId === this.gameClient.player.memberId) {
						this.myCharacter = character;
						this.setupMyCharacterAnimations(character, gltf);
						console.log('✓ 내 캐릭터 설정 완료');
					}

					if (bodySkeleton && bodySkinnedMesh) {
						this.loadCharacterParts(character, avatarInfo.parts, avatarInfo.nickName, bodySkeleton, bodySkinnedMesh);
					} else {
						console.warn('❗ 스켈레톤 추출 실패! 옷 바인딩 불가');
					}
					resolve(character);
				},
				(progress) => {
					// 로딩 진행률 (필요시 사용)
				},
				(error) => {
					console.error('❌ GLTF 모델 로드 실패:', nickName, error);
					reject(error);
				}
			);
		});
	}

	// ===== 베이스 캐릭터 설정 =====
	setupBaseCharacter(character, avatarInfo, position, memberId, sessionId) {
		let bodySkeleton = null;
		let bodySkinnedMesh = null;
		// 스킨 색상 및 재질 설정
		character.traverse((child) => {
			if (child.isMesh && child.material && child.material.color) {
				console.log('🎨 기존 재질에 색상 적용:', avatarInfo.skinColor);
				child.material.color = new THREE.Color(avatarInfo.skinColor || 0xffe0bd);
				child.material.needsUpdate = true;
			}

			if (child.isSkinnedMesh && child.skeleton) {
				bodySkeleton = child.skeleton;             // ✅ 바디의 스켈레톤 저장
				bodySkinnedMesh = child;                   // ✅ 바디의 스킨드메시도 저장
			}
		});

		// 스케일 설정
		const characterConfig = this.gameClient.getCharacterConfig();
		const characterScale = characterConfig.SCALE;
		character.scale.set(characterScale, characterScale, characterScale);

		// 위치 설정


		// 회전 설정
		character.rotation.y = Math.PI / 4;
		character.rotation.x = -Math.PI / 6;

		// 사용자 데이터 저장
		character.userData = {
			memberId: memberId,
			sessionId: sessionId,
			avatarInfo: avatarInfo
		};
		return { bodySkeleton, bodySkinnedMesh };
	}
	// ✅ 내 캐릭터 애니메이션 설정 (RenderModule 역할)
	setupMyCharacterAnimations(character, gltf) {
		console.log('🎬 내 캐릭터 애니메이션 설정 시작');

		// Mixer 설정
		this.mixer = new THREE.AnimationMixer(character);

		if (gltf.animations && gltf.animations.length > 0) {
			console.log('📋 애니메이션 클립들:', gltf.animations.map(c => c.name));

			// Walk 애니메이션 찾기
			const walkClip = gltf.animations.find(clip =>
				clip.name === "Armature|mixamo.com|Layer0"
			);

			if (walkClip) {
				this.walkAction = this.mixer.clipAction(walkClip);
				this.walkAction.loop = THREE.LoopRepeat;
				this.walkAction.enabled = true;
				// 💥 반드시 추가!
				//                         this.walkAction.play();
				this.walkAction.paused = true;
			}
		}

		// ✅ MovementModule에 애니메이션 전달
		const movementModule = this.gameClient.getCharacterMovementModule();
		if (movementModule) {
			movementModule.setAnimationActions(this.walkAction);
		}

		console.log('✅ 애니메이션 설정 완료');
	}

	// ✅ 애니메이션 업데이트 (RenderModule 역할)
	updateAnimations() {
		if (this.mixer && this.clock) {
			const delta = this.clock.getDelta();
			this.mixer.update(delta);
		}
	}


	// ===== 캐릭터 파츠 로딩 =====
	loadCharacterParts(character, parts, nickName, bodySkeleton, bodySkinnedMesh) {
		console.log('캐릭터 파츠 로딩 시작:', nickName, parts);
		console.log('📊 파츠 키들:', Object.keys(parts));


		// 모든 파츠를 순회하면서 로딩
		for (const [partType, partData] of Object.entries(parts)) {
			if (partType === 'accessory') {
				// accessory는 main 배열과 detail 단일로 구성
				partData.main?.forEach((item, i) => {
					if (item?.style) {
						this.loadPart(character, 'accessory', item, 'main', bodySkeleton, bodySkinnedMesh);
					}
				});

				// detail 단일
				if (partData.detail?.style) {
					this.loadPart(character, 'accessory', partData.detail, 'detail', bodySkeleton, bodySkinnedMesh);
				}
			} else if (partData?.style) {
				// 일반 파츠
				this.loadPart(character, partType, partData, null, bodySkeleton, bodySkinnedMesh);
			}
		}
	}

	// ===== 개별 파츠 로딩 =====
	loadPart(character, partType, partData, subType = null, bodySkeleton, bodySkinnedMesh) {
	  console.log(bodySkeleton);
	  console.log(bodySkinnedMesh);

	  const modelPath = this.getModelPath(partType, partData.style);
	  const name = subType ? `${partType}.${subType}` : partType;

	  this.loader.load(modelPath, (gltf) => {
	    const model = gltf.scene;

	    // 💡 색상 적용
	    if (partData.color) {
	      model.traverse((child) => {
	        if (child.isMesh && child.material?.color) {
	          if (child.material.map) child.material.map = null;
	          child.material.color.set(partData.color);
	          child.material.needsUpdate = true;
	        }
	      });
	    }
		
	    // 💡 본 바인딩
	    if (bodySkeleton && bodySkinnedMesh) {
	      model.traverse((child) => {
	        if (child.isSkinnedMesh) {
	          // 💡 transform 설정은 바인딩보다 먼저
	          child.position.copy(bodySkinnedMesh.position);
	          child.rotation.copy(bodySkinnedMesh.rotation);
	          child.scale.copy(bodySkinnedMesh.scale);

	          // 💡 월드 행렬 갱신
	          bodySkinnedMesh.updateMatrixWorld(true);
	          child.updateMatrixWorld(true);

	          // 💡 bind 수행
	          child.bind(bodySkeleton);

	          // 디버깅 로그
	          console.log("📌 바인딩 직전 child 위치:", child.position);
	          console.log("📌 바인딩 직전 child matrixWorld:", child.matrixWorld.elements);
	          console.log("📌 바인딩 직전 bodySkinnedMesh matrixWorld:", bodySkinnedMesh.matrixWorld.elements);
	          console.log("📌 옷의 bindMatrix:", child.bindMatrix);
	          console.log("📌 옷의 bindMatrixWorld:", child.bindMatrixWorld);
	        }
	      });
	    }

	    // ✅ 캐릭터에 한 번만 추가
		character.add(model);
	    console.log(`${name} 로딩 완료`);

	  }, undefined, (error) => {
	    console.error(`${name} 로딩 실패:`, error);
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
				model.scale.set(baseScale, baseScale, baseScale);
				model.position.set(0, 0, 0);
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

	// ===== 플레이어 제거 =====
	removePlayer(sessionId) {
		const character = this.playerCharacters.get(sessionId);
		if (character) {
			const scene = this.gameClient.getScene();
			scene.remove(character);
			this.playerCharacters.delete(sessionId);

			// 내 캐릭터였다면 null로 설정
			if (this.myCharacter === character) {
				this.myCharacter = null;
			}

			console.log('플레이어 제거 완료:', sessionId);
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

		// 모든 캐릭터 제거
		const scene = this.gameClient.getScene();
		this.playerCharacters.forEach((character) => {
			scene.remove(character);
		});

		// 맵 정리
		this.playerCharacters.clear();
		this.myCharacter = null;
		this.loader = null;

		console.log('✅ 캐릭터 렌더링 모듈 정리 완료');
	}
}
