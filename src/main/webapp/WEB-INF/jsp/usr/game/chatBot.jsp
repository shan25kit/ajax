<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="chatBot" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>
<link rel="stylesheet" href="/resource/css/chatBot.css" />

<div class="chatBot-container">
	<!-- 헤더 -->
	<div class="chatBot-header">
		<h1>감정별 전문 상담 AI 챗봇</h1>
		<button id="backToMapBtn" class="map-icon-btn">
			🗺️ <span class="tooltip">맵으로 돌아가기</span>
		</button>
	</div>

	<!-- 현재 모드 표시 -->
	<div class="current-mode">
		<span id="currentMode">일반 채팅 모드</span>
	</div>

	<!-- 메시지 영역 -->
	<div class="chat-messages" id="chatMessages">
		<div class="typing" id="typing">AI가 답변을 생각하고 있습니다</div>
	</div>

	<!-- 입력 영역 -->
	<div class="chat-input">
		<textarea id="messageInput" placeholder="메시지를 입력하세요..." rows="1"></textarea>
		<button id="sendBtn">전송</button>
	</div>
</div>

<script>
    const botEmojis = {
    	    'Anger': '😤',
    	    'Hope': '😢', 
    	    'Calm': '😰',
    	    'Joy': '😊',
    	    'Zen': '😌'
    	};
    let currentBotEmoji = '🤖'; 
    // ===== 서버에서 전달받은 맵 정보 =====
    const currentMapFromServer = '${currentMap}' || 'startMap';
    
    // ===== 맵별 챗봇 타입 매핑 =====
    const mapToBotType = {
        'startMap': null,
        'angerMap': 'Anger',
        'happyMap': 'Joy',
        'sadMap': 'Hope',
        'anxietyMap': 'Calm',
        'zenMap': 'Zen'
    };
    function getBotDisplayName(botType) {
        const names = {
            'Anger': '버럭이',
            'Hope': '슬픔이', 
            'Calm': '소심이',
            'Joy': '기쁨이',
            'Zen': '평온이'
        };
        return names[botType] || '상담사';
    }
    // ===== 맵별 환영 메시지 =====
    const mapWelcomeMessages = {
        'angerMap': '분노의 세계에서 오셨군요. 버럭이가 당신의 화를 이해하고 도와드릴게요. 무엇이 화나게 했나요?',
        'happyMap': '행복의 공간에서 오셨네요! 기쁨이와 함께 더 많은 기쁨을 나누어봐요. 오늘 좋은 일이 있으셨나요?',
        'sadMap': '슬픔의 공간에서 오셨군요. 슬픔이가 당신의 마음을 이해하고 위로해드릴게요. 무엇이 슬프게 했나요?',
        'anxietyMap': '불안의 공간에서 오셨네요. 소심이가 당신의 불안감을 달래드릴게요. 어떤 것이 불안하신가요?',
        'zenMap': '평온의 호수에서 오셨군요. 평온이와 함께 마음의 평화를 찾아봐요. 어떻게 도와드릴까요?'
    };
        $(document).ready(function() {
        	let currentBotType = null;
            const autoBotType = mapToBotType[currentMapFromServer];
            
            if (autoBotType) {
                // 자동 봇 선택
                currentBotType = autoBotType;
                currentBotEmoji = botEmojis[autoBotType];
                
                const botName = Object.keys(botEmojis).find(key => key === autoBotType);
                $('#currentMode').text(getBotDisplayName(botName) + ' 모드');
              
                const welcomeMessage = mapWelcomeMessages[currentMapFromServer];
                if (welcomeMessage) {
                    addMessage('bot', welcomeMessage);
                }
                
                // 입력창 즉시 활성화
                $('#messageInput').prop('disabled', false).attr('placeholder', '메시지를 입력하세요...').focus();
                $('#sendBtn').prop('disabled', false);
            } else {
                // 시작 맵이거나 매핑되지 않은 맵
                $('#messageInput').prop('disabled', true).attr('placeholder', '상담사를 먼저 선택해주세요...');
                $('#sendBtn').prop('disabled', true);
                $('#currentMode').text('상담사를 선택해주세요');
            }
            // 메시지 전송 (엔터키)
            $('#messageInput').keypress(function(e) {
                if (e.which === 13 && !e.shiftKey) {
                    e.preventDefault();
                    sendMessage();
                }
            });
            // 메시지 전송 (버튼)
            $('#sendBtn').click(sendMessage);

            // 입력창 자동 높이 조절
            $('#messageInput').on('input', function() {
                this.style.height = 'auto';
                this.style.height = Math.min(this.scrollHeight, 100) + 'px';
            });

            // 메시지 전송 함수
            function sendMessage() {
                const message = $('#messageInput').val().trim();
                if (!message) return;
             // 봇이 선택되지 않은 경우 처리
                if (!currentBotType) {
                    addMessage('bot', '먼저 상담사를 선택해주세요!');
                    return;
                }
            	
                // 사용자 메시지 추가
                addMessage('user', message);
                $('#messageInput').val('').css('height', 'auto');
                $('#sendBtn').prop('disabled', true);

                // 타이핑 표시
                showTyping();

                // API 호출
                const apiUrl = currentBotType === 'general' 
                    ? '/api/chat/message' 
                    : `/api/chat/message/\${currentBotType}`;
				
                $.ajax({
                    url: apiUrl,
                    method: 'POST',
                    contentType: 'application/json',
                    data: JSON.stringify({ 
                        message: message, 
                        botType: currentBotType 
                    }),
                    beforeSend: function(xhr, settings) {
                        console.log('요청 데이터:', settings.data); // 실제 전송 데이터 확인
                    },
                    success: function(data) {
                        hideTyping();
                        addMessage('bot', data.response);
                        if (data.response && (
                                data.response.includes('상담이 일시 중단됩니다')
                            )) {
                                // 입력창 및 버튼 비활성화
                                $('#messageInput').prop('disabled', true)
                                                  .attr('placeholder', '상담이 종료되었습니다.')
                                                  .css('background-color', '#f5f5f5');
                                $('#sendBtn').prop('disabled', true)
                                             .text('종료됨')
                                             .css('background-color', '#ccc');
                                
                                // 현재 모드 표시 변경
                                $('#currentMode').text('상담 종료')
                                                 .css('color', '#ff4444');
                                
                                return; // 더 이상 처리하지 않음
                            }
                        $('#sendBtn').prop('disabled', false);
                    },
                    error: function(xhr, status, error) {
                        console.error('오류 상세:', {
                            status: xhr.status,
                            statusText: xhr.statusText,
                            responseText: xhr.responseText,
                            error: error})
                        hideTyping();
                        addMessage('bot', '죄송합니다. 오류가 발생했습니다.');
                        $('#sendBtn').prop('disabled', false);
                    }
                });
               
            }

            // 메시지 추가 함수
            function addMessage(sender, content) {
            	let avatar;
                if (sender === 'user') {
                    avatar = '👤';
                } else {
                    // 봇의 경우 현재 선택된 봇의 이모지 사용
                    avatar = currentBotEmoji || '🤖';
                }
                const messageHtml = `
                    <div class="message \${sender}">
                        <div class="avatar">\${avatar}</div>
                        <div class="message-bubble">\${content}</div>
                    </div>
                `;
                
                $('#typing').before(messageHtml);
                scrollToBottom();
            }

            // 타이핑 표시/숨김
            function showTyping() {
                $('#typing').show();
                scrollToBottom();
            }

            function hideTyping() {
                $('#typing').hide();
            }

            // 스크롤을 맨 아래로
            function scrollToBottom() {
                $('#chatMessages').scrollTop($('#chatMessages')[0].scrollHeight);
            }

            // 페이지 로드 시 입력창에 포커스
            $('#messageInput').focus();
            
            $('#backToMapBtn').click(function() {
                const currentMap = currentMapFromServer || 'startMap';
                
                console.log('🚪 현재 맵으로 돌아가기:', currentMap);
                
                // 확인 다이얼로그 (선택사항)
                if (confirm('상담을 종료하고 맵으로 돌아가시겠습니까?')) {
                    // 맵 페이지로 이동
                    const mapUrl = '/usr/game/' + currentMap;
                    console.log('🎯 이동할 URL:', mapUrl);
                    window.location.href = mapUrl;
                }
            });
        });
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>