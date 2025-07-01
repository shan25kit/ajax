<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>
<link rel="stylesheet" href="/resource/css/chatBot.css" />

  <div class="chat-container">
        <!-- 헤더 -->
        <div class="chat-header">
            <h1> 감정별 전문 상담 🤖 AI 챗봇</h1>
            
        </div>

        <!-- 현재 모드 표시 -->
        <div class="current-mode">
            <span id="currentMode">일반 채팅 모드</span>
        </div>

        <!-- 메시지 영역 -->
        <div class="chat-messages" id="chatMessages">
            <div class="message bot">
                <div class="avatar">🤖</div>
                <div class="message-bubble">
                    안녕하세요! 저는 당신의 AI 감정입니다. 오늘 기분이 어때요?
                </div>
            </div>
            <div class="bot-selection" id="botSelection">
    <div class="bot-card" data-type="Anger">
        <div class="bot-emoji">😤</div>
        <div class="bot-name">버럭이</div>
        <div class="bot-desc">화가 날 때</div>
    </div>
    <div class="bot-card" data-type="Hope">
        <div class="bot-emoji">😢</div>
        <div class="bot-name">슬픔이</div>
        <div class="bot-desc">슬플 때</div>
    </div>
    <div class="bot-card" data-type="Calm">
        <div class="bot-emoji">😰</div>
        <div class="bot-name">소심이</div>
        <div class="bot-desc">불안할 때</div>
    </div>
    <div class="bot-card" data-type="Joy">
        <div class="bot-emoji">😊</div>
        <div class="bot-name">기쁨이</div>
        <div class="bot-desc">기쁠 때</div>
    </div>
    <div class="bot-card" data-type="Zen">
        <div class="bot-emoji">😌</div>
        <div class="bot-name">평온이</div>
        <div class="bot-desc">평온하고 싶을 때</div>
    </div>
</div>
            
            
            
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
        $(document).ready(function() {
        	let currentBotType = null;
        	// 초기 상태에서 입력창 비활성화
            $('#messageInput').prop('disabled', true).attr('placeholder', '상담사를 먼저 선택해주세요...');
            $('#sendBtn').prop('disabled', true);
            
            // 현재 모드 초기 메시지
            $('#currentMode').text('상담사를 선택해주세요');
           
            $('.bot-card').click(function() {
                // 기존 선택 해제
                $('.bot-card').removeClass('selected');
                
                // 현재 카드 선택
                $(this).addClass('selected');
                
                currentBotType = $(this).data('type');
                currentBotEmoji = botEmojis[currentBotType];
                const botName = $(this).find('.bot-name').text();
                
                // 모드 표시 업데이트
                $('#currentMode').text(botName + ' 채팅 모드');
                
                // 봇 선택 완료 메시지 추가
                addMessage('bot', `\${botName} 모드로 설정되었습니다. 이제 대화를 시작해보세요!`);
                
                // 봇 선택 영역 숨김 (선택 후)
                $('#botSelection').fadeOut(300);
                
                // 입력창 활성화 및 포커스
                $('#messageInput').prop('disabled', false).focus();
                $('#sendBtn').prop('disabled', false);
            });
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
        });
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>