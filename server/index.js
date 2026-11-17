// Server entry point – handles connections, matchmaking, and basic gameplay flow
// Added simple room management (create/join/start) for a Mini‑Militia‑style lobby.

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const Game = require('./game');

const PORT = 3000;
const wss = new WebSocket.Server({ port: PORT });

console.log(`MYNA server listening on ws://0.0.0.0:${PORT}`);

// State containers
let rooms = {}; // roomId -> {desiredSize, players: [{ws, playerId}], status:'waiting'|'started', game:Game|null}
let playerMap = {}; // playerId -> {ws, roomId|null}

function broadcastRoomList() {
  const list = Object.entries(rooms).map(([id, r]) => ({ roomId: id, desiredSize: r.desiredSize, playerCount: r.players.length, status: r.status }));
  const msg = JSON.stringify({ type: 'roomList', payload: list });
  wss.clients.forEach(c => {
    if (c.readyState === WebSocket.OPEN) c.send(msg);
  });
}

function send(ws, type, payload) {
  ws.send(JSON.stringify({ type, payload }));
}

wss.on('connection', (ws) => {
  const playerId = uuidv4();
  playerMap[playerId] = { ws, roomId: null };
  send(ws, 'welcome', { playerId });

  // Immediately push current room list
  broadcastRoomList();

  ws.on('message', (msg) => {
    let data;
    try { data = JSON.parse(msg); } catch (_) { return; }
    const { type, payload } = data;
    switch (type) {
      case 'createRoom':
        // payload: {desiredSize}
        const roomId = uuidv4();
        rooms[roomId] = { desiredSize: payload.desiredSize, players: [], status: 'waiting', game: null };
        // host joins automatically
        rooms[roomId].players.push({ ws, playerId });
        playerMap[playerId].roomId = roomId;
        send(ws, 'roomCreated', { roomId });
        broadcastRoomList();
        break;
      case 'joinRoom':
        // payload: {roomId}
        const r = rooms[payload.roomId];
        if (r && r.status === 'waiting' && r.players.length < r.desiredSize) {
          r.players.push({ ws, playerId });
          playerMap[playerId].roomId = payload.roomId;
          send(ws, 'roomJoined', { roomId: payload.roomId });
          broadcastRoomList();
        } else {
          send(ws, 'error', { message: 'Cannot join room' });
        }
        break;
      case 'startGame':
        // payload: {roomId}
        const room = rooms[payload.roomId];
        if (room && room.players.length >= 4 && room.status === 'waiting') {
          const game = new Game(roomId, room.players);
          room.game = game;
          room.status = 'started';
          // Notify each player with their hand
          room.players.forEach(p => {
            send(p.ws, 'gameStart', { gameId: roomId, playerId: p.playerId, hand: game.getHand(p.playerId) });
          });
          broadcastRoomList();
        }
        break;
      case 'playCard':
        // payload: {roomId, card}
        const roomPlay = rooms[payload.roomId];
        if (roomPlay && roomPlay.game) {
          const result = roomPlay.game.playCard(playerId, payload.card);
          // broadcast updated state to all players in the room
          const stateMsg = { type: 'gameUpdate', payload: roomPlay.game.getPublicState() };
          const stateStr = JSON.stringify(stateMsg);
          roomPlay.players.forEach(p => {
            if (p.ws.readyState === WebSocket.OPEN) p.ws.send(stateStr);
          });
          if (result.gameOver) {
            // clean up room after game ends
            delete rooms[payload.roomId];
            broadcastRoomList();
          }
        }
        break;
      case 'requestRoomList':
        broadcastRoomList();
        break;
      default:
        // ignore unknown messages
        break;
    }
  });

  ws.on('close', () => {
    const info = playerMap[playerId];
    if (info && info.roomId) {
      const rm = rooms[info.roomId];
      if (rm) {
        rm.players = rm.players.filter(p => p.playerId !== playerId);
        if (rm.players.length === 0) delete rooms[info.roomId];
        else if (rm.status === 'started' && rm.game) rm.game.removePlayer(playerId);
        broadcastRoomList();
      }
    }
    delete playerMap[playerId];
  });
});
