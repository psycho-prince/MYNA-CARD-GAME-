const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const SERVER_URL = 'ws://127.0.0.1:3000';
const PLAYER_COUNT = 4; // test size 4

class TestClient {
  constructor(name) {
    this.name = name;
    this.ws = new WebSocket(SERVER_URL);
    this.playerId = null;
    this.roomId = null;
    this.gameId = null;
    this.hand = [];
    this.isHost = false;
    this.ws.on('open', () => {});
    this.ws.on('message', (msg) => this.handle(msg));
    this.ws.on('close', () => {});
  }
  send(type, payload) {
    this.ws.send(JSON.stringify({ type, payload }));
  }
  handle(msg) {
    let data;
    try { data = JSON.parse(msg); } catch (_) { return; }
    const { type, payload } = data;
    switch (type) {
      case 'welcome':
        this.playerId = payload.playerId;
        break;
      case 'roomCreated':
        this.roomId = payload.roomId;
        this.isHost = true;
        break;
      case 'roomJoined':
        this.roomId = payload.roomId;
        break;
      case 'gameStart':
        this.gameId = payload.gameId;
        this.hand = payload.hand;
        break;
      case 'gameUpdate':
        if (payload.hands && payload.hands[this.playerId]) {
          const h = payload.hands[this.playerId];
          if (Array.isArray(h)) this.hand = h;
        }
        if (payload.currentTurn === this.playerId && this.hand.length) {
          const card = this.hand[Math.floor(Math.random() * this.hand.length)];
          this.send('playCard', { roomId: this.roomId, card: card.code });
        }
        if (payload.gameOver) {
          console.log(`Game over detected by ${this.name}`);
          process.exit(0);
        }
        break;
      case 'error':
        console.error(`${this.name} error:`, payload.message);
        break;
      default:
        break;
    }
  }
}

function sleep(ms) {return new Promise(r=>setTimeout(r,ms));}

(async () => {
  const clients = [];
  for (let i = 0; i < PLAYER_COUNT; i++) {
    clients.push(new TestClient(`P${i+1}`));
    await sleep(100);
  }
  await sleep(500);
  const host = clients[0];
  host.send('createRoom', { desiredSize: PLAYER_COUNT });
  await sleep(500);
  for (let i = 1; i < clients.length; i++) {
    clients[i].send('joinRoom', { roomId: host.roomId });
    await sleep(100);
  }
  await sleep(1000);
  host.send('startGame', { roomId: host.roomId });
  // timeout guard
  setTimeout(() => { console.error('Stress test timed out'); process.exit(1); }, 30000);
})();
