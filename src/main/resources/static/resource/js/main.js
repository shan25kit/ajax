// ===== src/main.js =====
// 메인 진입점 - 게임 시작

import { GameClient } from './core/GameClient.js';

// ===== 테스트용 플레이어 데이터 =====
const testPlayer = {
    memberId: 1,
    nickName: "TestPlayer",
    avatarInfo: {
        skinColor: 0xffe0bd,
        parts: {
            hair: { style: 1, color: 0x8B4513 },
            top: { style: 1, color: 0x4169E1 },
            bottom: { style: 1, color: 0x228B22 },
            shoes: { style: 1, color: 0x8B4513 }
        }
    }
};

// ===== 게임 초기화 =====
async function startGame() {
    try {
        console.log('🎮 게임 시작');

        // 게임 클라이언트 생성 및 초기화
        const gameClient = new GameClient();
        await gameClient.initialize(testPlayer);
        
        // 서버 연결
        await gameClient.connect();
        
        // 게임 시작
        gameClient.startGame();
        
       // 디버그 활성화
        gameClient.enableDebugMode(); 

        // 전역 등록
        window.gameClient = gameClient;
        window.gameDebug = gameClient;

        console.log('✅ 게임 시작 완료');
        console.log('💡 window.gameDebug 사용 가능');

    } catch (error) {
        console.error('❌ 게임 시작 실패:', error);
        alert(`게임 시작 실패: ${error.message}`);
    }
}

// ===== 정리 =====
window.addEventListener('beforeunload', () => {
    window.gameClient?.destroy();
});

// ===== 시작 =====
document.addEventListener('DOMContentLoaded', startGame);