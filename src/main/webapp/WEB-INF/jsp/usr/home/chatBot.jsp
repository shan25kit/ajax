<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="Login" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>
<link rel="stylesheet" href="/resource/css/chatBot.css" />

  <div class="chat-container">
        <!-- 헤더 -->
        <div class="chat-header">
            <h1>🤖 감정별 전문 상담 AI 챗봇</h1>
            <div class="bot-tabs">
                <button class="bot-tab active" data-type="Anger">앵거</button>
                <button class="bot-tab" data-type="Hope">호프</button>
                <button class="bot-tab" data-type="Calm">캄</button>
                <button class="bot-tab" data-type="Joy">조이</button>
                <button class="bot-tab" data-type="Zen">젠</button>
            </div>
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
                    안녕하세요! 저는 당신의 AI 감정입니다. 무엇을 도와드릴까요?
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
        $(document).ready(function() {
            let currentBotType = 'general';
            
            // 봇 타입 변경
            $('.bot-tab').click(function() {
                $('.bot-tab').removeClass('active');
                $(this).addClass('active');
                
                currentBotType = $(this).data('type');
                const botName = $(this).text();
                console.log(botName);
                $('#currentMode').text(botName + ' 채팅 모드');
                addMessage('bot', `\${botName} 모드로 변경되었습니다. 어떻게 도와드릴까요?`);
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
                const avatar = sender === 'user' ? '👤' : '🤖';
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