<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>AI Chatbot</title>
 <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
  <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: #f0f2f5;
            padding: 20px;
        }

        .chat-container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .chat-header {
            background: black;
            color: white;
            padding: 20px;
            text-align: center;
        }

        .chat-header h1 {
            font-size: 20px;
            margin-bottom: 15px;
        }

        .bot-tabs {
            display: flex;
            gap: 5px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .bot-tab {
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            padding: 8px 15px;
            border-radius: 20px;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.2s;
        }

        .bot-tab:hover,
        .bot-tab.active {
            background: rgba(255,255,255,0.3);
            transform: scale(1.05);
        }

        .chat-messages {
            height: 400px;
            padding: 20px;
            overflow-y: auto;
            background: #f8f9fa;
        }

        .message {
            margin-bottom: 15px;
            display: flex;
            gap: 10px;
        }

        .message.user {
            flex-direction: row-reverse;
        }

        .message-bubble {
            max-width: 70%;
            padding: 12px 16px;
            border-radius: 18px;
            word-wrap: break-word;
            line-height: 1.4;
        }

        .user .message-bubble {
            background: #4285f4;
            color: white;
        }

        .bot .message-bubble {
            background: white;
            color: #333;
            border: 1px solid #e0e0e0;
        }

        .avatar {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
        }

        .user .avatar {
            background: #4285f4;
            color: white;
        }

        .bot .avatar {
            background: #e0e0e0;
            color: #666;
        }

        .chat-input {
            padding: 20px;
            background: white;
            border-top: 1px solid #e0e0e0;
            display: flex;
            gap: 10px;
        }

        #messageInput {
            flex: 1;
            padding: 12px 16px;
            border: 1px solid #e0e0e0;
            border-radius: 25px;
            outline: none;
            font-size: 14px;
            resize: none;
        }

        #messageInput:focus {
            border-color: #4285f4;
            box-shadow: 0 0 0 2px rgba(66, 133, 244, 0.2);
        }

        #sendBtn {
            padding: 12px 20px;
            background: #4285f4;
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.2s;
        }

        #sendBtn:hover {
            background: #3367d6;
        }

        #sendBtn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }

        .typing {
            display: none;
            color: #666;
            font-style: italic;
            padding: 10px 16px;
        }

        .typing::after {
            content: '...';
            animation: dots 1.5s infinite;
        }

        @keyframes dots {
            0%, 20% { content: '.'; }
            40% { content: '..'; }
            60%, 100% { content: '...'; }
        }

        .current-mode {
            background: #e3f2fd;
            padding: 10px;
            text-align: center;
            font-size: 14px;
            color: #1976d2;
            border-bottom: 1px solid #e0e0e0;
        }

        /* 스크롤바 스타일 */
        .chat-messages::-webkit-scrollbar {
            width: 6px;
        }

        .chat-messages::-webkit-scrollbar-track {
            background: #f1f1f1;
        }

        .chat-messages::-webkit-scrollbar-thumb {
            background: #c1c1c1;
            border-radius: 3px;
        }
    </style>
</head>
<body>
  <div class="chat-container">
        <!-- 헤더 -->
        <div class="chat-header">
            <h1>🤖 AI 챗봇</h1>
            <div class="bot-tabs">
                <button class="bot-tab active" data-type="general">일반</button>
                <button class="bot-tab" data-type="productivity">생산성</button>
                <button class="bot-tab" data-type="health">건강</button>
                <button class="bot-tab" data-type="language">언어</button>
                <button class="bot-tab" data-type="finance">금융</button>
                <button class="bot-tab" data-type="counseling">상담</button>
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
                    안녕하세요! 저는 당신의 AI 어시스턴트입니다. 무엇을 도와드릴까요?
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
                            error: error);
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
</body>
</html>