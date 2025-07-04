<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:set var="pageTitle" value="testMap" />

<%@ include file="/WEB-INF/jsp/common/header.jsp"%>

<script
	src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script
	src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
<div class="container">
        <h1>WebSocket 테스트</h1>
        
        <div id="status" class="status disconnected">연결 안됨</div>
        
        <div class="controls">
            <button onclick="connect()">연결</button>
            <button onclick="disconnect()">연결 해제</button>
            <button onclick="joinMap()">맵 입장</button>
        </div>
        
        <div class="controls">
            <h3>이동 (WASD)</h3>
            <div style="text-align: center;">
                <div><button onclick="move(0, -10)">W</button></div>
                <div>
                    <button onclick="move(-10, 0)">A</button>
                    <button onclick="move(0, 10)">S</button>
                    <button onclick="move(10, 0)">D</button>
                </div>
            </div>
        </div>
        
        <div class="players">
            <h3>플레이어 정보</h3>
            <div id="playerInfo">아직 입장하지 않음</div>
        </div>
        
        <div class="players">
            <h3>다른 플레이어들</h3>
            <div id="otherPlayers">없음</div>
        </div>
        
        <div class="players">
            <h3>메시지 로그</h3>
            <div id="messageLog" style="height: 200px; overflow-y: scroll; background: white; padding: 10px;"></div>
        </div>
    </div>

    <script>
        let socket = null;
        let isConnected = false;
        let myPlayer = null;
        let otherPlayers = new Map();

        function connect() {
            socket = new WebSocket('ws://localhost:8081/game');
            
            socket.onopen = function() {
                isConnected = true;
                updateStatus('connected');
                log('웹소켓 연결됨');
            };
            
            socket.onmessage = function(event) {
                const message = JSON.parse(event.data);
                handleMessage(message);
            };
            
            socket.onclose = function() {
                isConnected = false;
                updateStatus('disconnected');
                log('웹소켓 연결 해제됨');
            };
        }

        function disconnect() {
            if (socket) {
                socket.close();
            }
        }

        function joinMap() {
            if (!isConnected) {
                alert('먼저 웹소켓에 연결하세요');
                return;
            }
            
            const userData = {
                type: 'join-map',
                username: 'TestPlayer_' + Math.floor(Math.random() * 1000),
                character: {
                    appearance: {
                        hairColor: '#8B4513',
                        skinColor: '#FFDBAC'
                    }
                }
            };
            
            myPlayer = { ...userData, position: { x: 0, y: 0, z: 0 } };
            socket.send(JSON.stringify(userData));
            updatePlayerInfo();
        }

        function move(deltaX, deltaY) {
            if (!myPlayer) {
                alert('먼저 맵에 입장하세요');
                return;
            }
            
            myPlayer.position.x += deltaX;
            myPlayer.position.y += deltaY;
            
            const moveMessage = {
                type: 'player-move',
                position: myPlayer.position
            };
            
            socket.send(JSON.stringify(moveMessage));
            updatePlayerInfo();
        }

        function handleMessage(message) {
            log('받은 메시지: ' + JSON.stringify(message));
            
            switch (message.type) {
                case 'player-joined':
                    otherPlayers.set(message.player.id, message.player);
                    updateOtherPlayers();
                    break;
                case 'existing-players':
                    message.players.forEach(player => {
                        otherPlayers.set(player.id, player);
                    });
                    updateOtherPlayers();
                    break;
                case 'player-moved':
                    const player = otherPlayers.get(message.memberId);
                    if (player) {
                        player.position = message.position;
                        updateOtherPlayers();
                    }
                    break;
                case 'player-left':
                    otherPlayers.delete(message.memberId);
                    updateOtherPlayers();
                    break;
            }
        }

        function updateStatus(status) {
            const statusDiv = document.getElementById('status');
            if (status === 'connected') {
                statusDiv.textContent = '연결됨';
                statusDiv.className = 'status connected';
            } else {
                statusDiv.textContent = '연결 안됨';
                statusDiv.className = 'status disconnected';
            }
        }

        function updatePlayerInfo() {
            const playerInfoDiv = document.getElementById('playerInfo');
            if (myPlayer) {
                playerInfoDiv.innerHTML = `
                    <strong>내 플레이어:</strong><br>
                    이름: ${myPlayer.username}<br>
                    위치: (${myPlayer.position.x}, ${myPlayer.position.y})
                `;
            }
        }

        function updateOtherPlayers() {
            const otherPlayersDiv = document.getElementById('otherPlayers');
            if (otherPlayers.size === 0) {
                otherPlayersDiv.textContent = '없음';
            } else {
                let html = '';
                otherPlayers.forEach(player => {
                    html += `
                        <div style="margin: 5px 0; padding: 5px; background: white; border-radius: 3px;">
                            <strong>${player.username}</strong><br>
                            위치: (${player.position.x}, ${player.position.y})
                        </div>
                    `;
                });
                otherPlayersDiv.innerHTML = html;
            }
        }

        function log(message) {
            const logDiv = document.getElementById('messageLog');
            const time = new Date().toLocaleTimeString();
            logDiv.innerHTML += `<div>[${time}] ${message}</div>`;
            logDiv.scrollTop = logDiv.scrollHeight;
        }
    </script>
<%@ include file="/WEB-INF/jsp/common/footer.jsp"%>