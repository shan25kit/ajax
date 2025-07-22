export class AssetManager {
    constructor() {
        // ===== 에셋 경로 설정 =====
        this.PATHS = {
            MODEL: '/resource/model/',
            IMAGE: '/resource/img/'
        };
        
        // ===== 파일 확장자 =====
        this.EXTENSIONS = {
            MODEL: '.glb',
            IMAGE: '.png'
        };
        
        // ===== 파츠별 상세 설정값 =====
        this.PART_SETTINGS = {
            // 헤어 스타일별 설정 (scale, position, rotation)
            hair: {
                1: { scale: [66, 66, 65], position: [0, -46, 0], rotation: [0, 0, 0] },
                12: { scale: [65, 64, 63], position: [0, -45, 0.8], rotation: [0, 0, 0] },
                3: { scale: [66.8, 65, 55.75], position: [0, -45.2, 0.4], rotation: [0, 0, 0] },
                14: { scale: [62, 61, 60], position: [0, -66, 1], rotation: [0, 0, 0] },
                10: { scale: [59, 60, 61], position: [0, -64.5, 0.5], rotation: [0, 0, 0] },
                17: { scale: [65, 60, 58], position: [0, -41.2, 0], rotation: [0, 0, 0] },
                18: { scale: [65, 58, 65], position: [0, -40, 0], rotation: [0, 0, 0] },
                19: { scale: [65, 60, 61], position: [0, -41.1, 1], rotation: [0, 0, 0] }
            },
            
            // 상의 스타일별 설정
            top: {
                1: { scale: [46.5, 45, 45], position: [0, -19.5, 0.3], rotation: [0, 0, 0] },
                8: { scale: [46.5, 40, 46], position: [0, -26.5, 0.3], rotation: [0, 0, 0] },
                9: { scale: [43.5, 42, 40], position: [0, -27.5, 0.1], rotation: [0, 0, 0] },
                10: { scale: [42.5, 42, 40], position: [0, -27.5, 0.2], rotation: [0, 0, 0] },
                11: { scale: [42.5, 42, 40], position: [0, -27.8, 0.5], rotation: [0, 0, 0] },
                12: { scale: [40, 38, 39], position: [0, -25, 0.5], rotation: [0, 0, 0] },
                13: { scale: [45, 42, 42], position: [0, -27.8, 0.5], rotation: [0, 0, 0] },
                14: { scale: [40, 38, 35], position: [0, -25, 0.3], rotation: [0, 0, 0] }
            },
            
            // 하의 스타일별 설정
            bottom: {
                1: { scale: [47, 40, 36], position: [0.1, -18, 0], rotation: [0, 0, 0] },
                3: { scale: [38, 35, 34], position: [0, -22, 0.2], rotation: [0, 0, 0] },
                4: { scale: [38, 33, 32], position: [0, -22, 0], rotation: [0, 0, 0] },
                8: { scale: [40, 35, 34], position: [0, -23, 0.15], rotation: [0, 0, 0] },
                9: { scale: [41, 35, 32], position: [0, -22, 0.15], rotation: [0, 0, 0] },
                10: { scale: [40, 29, 32], position: [0, -20, 0.15], rotation: [0, 0, 0] },
                11: { scale: [40, 35, 34], position: [0, -22, 0.2], rotation: [0, 0, 0] },
                12: { scale: [38.8, 34, 31.5], position: [0, -22.5, 0.1], rotation: [0, 0, 0] }
            },
            
            // 드레스 스타일별 설정
            dress: {
                1: { scale: [45.2, 45.2, 45.2], position: [0, -19.8, 0.45], rotation: [0, 0, 0] },
                3: { scale: [40, 37, 36.8], position: [0, -24.2, 0.45], rotation: [0, 0, 0] },
                4: { scale: [40, 37, 40], position: [0, -24.3, 0.45], rotation: [0, 0, 0] },
                5: { scale: [39.5, 37, 36], position: [0, -24.3, 0.45], rotation: [0, 0, 0] },
                6: { scale: [39.5, 37, 36], position: [0, -24.3, 0.41], rotation: [0, 0, 0] },
                7: { scale: [39.5, 37, 36], position: [0, -24.1, 0.42], rotation: [0, 0, 0] },
                8: { scale: [39.5, 37, 36], position: [0, -24.1, 0.42], rotation: [0, 0, 0] },
                9: { scale: [43, 43, 43], position: [0, -28.5, 0.45], rotation: [0, 0, 0] }
            },
            
            // 신발 스타일별 설정
            shoes: {
                1: { scale: [32, 30, 32], position: [0, -22, 0], rotation: [0, 0, 0] },
                2: { scale: [1.7, 2.1, 2], position: [0, -22, 1], rotation: [0, 0, 0] },
                3: { scale: [40, 40, 45], position: [0, -22, 0], rotation: [0, 0, 0] },
                4: { scale: [37, 40, 45], position: [0, -22, -0.2], rotation: [0, 0, 0] },
                5: { scale: [40, 40, 45], position: [0, -22, -0.25], rotation: [0, 0, 0] },
                6: { scale: [40, 45, 43], position: [0, -21.8, -0.22], rotation: [0, 0, 0] },
                7: { scale: [40, 45, 43], position: [0, -21.7, -0.22], rotation: [0, 0, 0] },
                8: { scale: [37, 45, 43], position: [0, -21.7, -0.22], rotation: [0, 0, 0] }
            },
            
            // 액세서리 스타일별 설정
            accessory: {
                1: { scale: [50, 50, 50], position: [7.5, -33, -3], rotation: [0.2, -0.15, 0.1] },
                2: { scale: [67, 60, 50], position: [0, -41, 1], rotation: [0, 0, 0] },
                3: { scale: [67, 60, 50], position: [0, -41, 1], rotation: [0, 0, 0] },
                4: { scale: [75, 80, 75], position: [0, -58.5, 0], rotation: [0, 0, 0] },
                5: { scale: [40, 45, 45], position: [0, -30, 0.5], rotation: [0, 0, 0] },
                6: { scale: [40, 45, 45], position: [0, -29.9, 0.5], rotation: [0, 0, 0] },
                7: { scale: [6, 6, 6], position: [0, -15, 0], rotation: [0, 0, 0] },
                8: { scale: [6.3, 6.3, 6.3], position: [0, -16.3, 0], rotation: [0, 0, 0] }
            }
        };
        
        // ===== 기본 색상 팔레트 =====
        this.COLOR_PALETTES = {
            skin: [
                '#FCE9D6', '#F3D7B6', '#D8B89F', 
                '#A47551', '#5C3A2E', '#8FE3CF'
            ],
            hair: [
                '#000000', '#4B3621', '#8B4513', 
                '#D2B48C', '#FFD700', '#FFFFFF'
            ]
        };
        
        // ===== 캐시 시스템 =====
        this.loadedModels = new Map();
        this.loadedTextures = new Map();
        this.loadedAudio = new Map();
        
        // ===== 로딩 상태 관리 =====
        this.isLoading = false;
        this.loadingProgress = 0;
        this.loadingQueue = [];
    }
    
    // ===== 경로 생성 메서드들 =====
    getModelPath(partType, styleNumber) {
        if (!styleNumber) return null;
        return this.PATHS.MODEL + partType + styleNumber + this.EXTENSIONS.MODEL;
    }
    
    getImagePath(imageName) {
        const ext = imageName.includes('.') ? '' : this.EXTENSIONS.IMAGE;
        return this.PATHS.IMAGE + imageName + ext;
    }
    
    getSoundPath(soundName) {
        const ext = soundName.includes('.') ? '' : this.EXTENSIONS.SOUND;
        return this.PATHS.SOUND + soundName + ext;
    }
    
    getTexturePath(textureName) {
        const ext = textureName.includes('.') ? '' : this.EXTENSIONS.TEXTURE;
        return this.PATHS.TEXTURE + textureName + ext;
    }
    
    // ===== 파츠 설정값 관리 =====
    getPartSettings(partType, styleNumber) {
        const partSettings = this.PART_SETTINGS[partType];
        if (!partSettings || !partSettings[styleNumber]) {
            // 기본값 반환
            console.warn(`파츠 설정을 찾을 수 없음: ${partType}${styleNumber}, 기본값 사용`);
            return { 
                scale: [1, 1, 1], 
                position: [0, 0, 0], 
                rotation: [0, 0, 0] 
            };
        }
        return { ...partSettings[styleNumber] }; // 복사본 반환
    }
    
    setPartSettings(partType, styleNumber, settings) {
        if (!this.PART_SETTINGS[partType]) {
            this.PART_SETTINGS[partType] = {};
        }
        this.PART_SETTINGS[partType][styleNumber] = { ...settings };
        console.log(`파츠 설정 업데이트: ${partType}${styleNumber}`);
    }
    
    // 파츠별 기본 설정값 계산
    getPartDefaultSettings(partType, baseScale = 1) {
        const defaults = {
            hair: { scale: [baseScale * 1.6, baseScale * 1.6, baseScale * 1.6], position: [0, -13, 0] },
            top: { scale: [baseScale * 1.6, baseScale * 1.6, baseScale * 1.6], position: [0, 5, 0] },
            bottom: { scale: [baseScale, baseScale, baseScale], position: [0, -4, 0] },
            dress: { scale: [baseScale * 1.6, baseScale * 1.6, baseScale * 1.6], position: [0, 5, 0] },
            shoes: { scale: [baseScale, baseScale, baseScale], position: [0, -4, 0] },
            accessory: { scale: [baseScale, baseScale, baseScale], position: [0, -4, 0] }
        };
        
        return defaults[partType] || { scale: [baseScale, baseScale, baseScale], position: [0, 0, 0], rotation: [0, 0, 0] };
    }
    
    // ===== 색상 팔레트 관리 =====
    getColorPalette(type) {
        return [...(this.COLOR_PALETTES[type] || [])]; // 복사본 반환
    }
    
    addColor(type, color) {
        if (!this.COLOR_PALETTES[type]) {
            this.COLOR_PALETTES[type] = [];
        }
        if (!this.COLOR_PALETTES[type].includes(color)) {
            this.COLOR_PALETTES[type].push(color);
        }
    }
    
    removeColor(type, color) {
        if (this.COLOR_PALETTES[type]) {
            const index = this.COLOR_PALETTES[type].indexOf(color);
            if (index > -1) {
                this.COLOR_PALETTES[type].splice(index, 1);
            }
        }
    }
    
    // ===== 에셋 로딩 (캐시 포함) =====
    async loadModel(partType, styleNumber) {
        const path = this.getModelPath(partType, styleNumber);
        if (!path) {
            throw new Error(`잘못된 모델 경로: ${partType}${styleNumber}`);
        }
        
        // 캐시 확인
        if (this.loadedModels.has(path)) {
            console.log(`모델 캐시 히트: ${path}`);
            return this.loadedModels.get(path).clone();
        }
        
        // 새로 로딩
        console.log(`모델 로딩 시작: ${path}`);
        const loader = new THREE.GLTFLoader();
        
        return new Promise((resolve, reject) => {
            loader.load(
                path,
                (gltf) => {
                    console.log(`모델 로딩 완료: ${path}`);
                    this.loadedModels.set(path, gltf.scene);
                    resolve(gltf.scene.clone());
                },
                (progress) => {
                    console.log(`모델 로딩 진행률: ${path} - ${(progress.loaded / progress.total * 100)}%`);
                },
                (error) => {
                    console.error(`모델 로딩 실패: ${path}`, error);
                    reject(error);
                }
            );
        });
    }
    
   
   
    
    // ===== 배치 로딩 =====
    async loadMultipleModels(partList) {
        const loadPromises = partList.map(({ partType, styleNumber }) => 
            this.loadModel(partType, styleNumber).catch(error => {
                console.error(`모델 로딩 실패: ${partType}${styleNumber}`, error);
                return null;
            })
        );
        
        const results = await Promise.all(loadPromises);
        return results.filter(result => result !== null);
    }
    
    // ===== 에셋 정보 조회 =====
    getAvailableStyles(partType) {
        const partSettings = this.PART_SETTINGS[partType];
        return partSettings ? Object.keys(partSettings).map(Number).sort((a, b) => a - b) : [];
    }
    
    isValidStyle(partType, styleNumber) {
        return this.PART_SETTINGS[partType] && 
               this.PART_SETTINGS[partType][styleNumber] !== undefined;
    }
    
    getPartTypes() {
        return Object.keys(this.PART_SETTINGS);
    }
    
    // ===== 캐시 관리 =====
    getCacheInfo() {
        return {
            models: {
                count: this.loadedModels.size,
                paths: Array.from(this.loadedModels.keys())
            }
        };
    }
    
    clearCache(type = 'all') {
        switch (type) {
            case 'models':
                this.loadedModels.clear();
                console.log('모델 캐시 정리됨');
                break;
           
            case 'all':
            default:
                this.loadedModels.clear();
                this.loadedTextures.clear();
                this.loadedAudio.clear();
                console.log('모든 캐시 정리됨');
                break;
        }
    }
    
    // 특정 에셋 캐시에서 제거
    removeFromCache(path) {
        let removed = false;
        
        if (this.loadedModels.has(path)) {
            this.loadedModels.delete(path);
            removed = true;
        }
        
        
        if (removed) {
            console.log(`캐시에서 제거됨: ${path}`);
        }
        
        return removed;
    }
    
    // ===== 유틸리티 메서드들 =====
    
    // 모든 파츠 스타일 정보 반환
    getAllPartsInfo() {
        const info = {};
        
        for (const [partType, styles] of Object.entries(this.PART_SETTINGS)) {
            info[partType] = {
                availableStyles: Object.keys(styles).map(Number).sort((a, b) => a - b),
                count: Object.keys(styles).length
            };
        }
        
        return info;
    }
    
    
    // 경로 유효성 검사
    validatePath(path) {
        // 간단한 경로 유효성 검사
        return path && typeof path === 'string' && path.startsWith('/resource/');
    }
    
    // 디버그 정보 출력
    logDebugInfo() {
        console.log('=== AssetManager 디버그 정보 ===');
        console.log('파츠 종류:', this.getPartTypes());
        console.log('전체 파츠 정보:', this.getAllPartsInfo());
        console.log('캐시 정보:', this.getCacheInfo());
        console.log('색상 팔레트:', this.COLOR_PALETTES);
    }
}