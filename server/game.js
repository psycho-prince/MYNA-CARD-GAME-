const SUITS = ['♠', '♥', '♦', '♣'];
const RANKS = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
const JOKER = 'Joker';

function createDeck() {
  const deck = [];
  for (let d = 0; d < 3; d++) { // three decks
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        deck.push({ rank, suit, code: `${rank}${suit}` });
      }
    }
    // add 2 jokers per deck
    deck.push({ rank: JOKER, suit: null, code: `JK${d+1}a` });
    deck.push({ rank: JOKER, suit: null, code: `JK${d+1}b` });
  }
  return deck;
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

class Game {
  constructor(gameId, players) {
    this.id = gameId;
    this.players = players; // [{ws, playerId}]
    this.deck = shuffle(createDeck());
    this.hands = {};
    this.discardPile = [];
    this.currentTurnIndex = 0;
    this.scores = {};
    this.teams = {};
    this.initHands();
    this.assignTeams();
  }

  initHands() {
    for (const p of this.players) {
      this.hands[p.playerId] = [];
      for (let i = 0; i < 13; i++) {
        this.hands[p.playerId].push(this.deck.pop());
      }
    }
  }

  assignTeams() {
    // Simple pairing: first with third, second with fourth, etc.
    const ids = this.players.map(p => p.playerId);
    for (let i = 0; i < ids.length; i++) {
      const teammate = ids[(i + Math.floor(ids.length / 2)) % ids.length];
      this.teams[ids[i]] = teammate;
    }
  }

  getHand(playerId) {
    // Return a shallow copy for safety
    return this.hands[playerId] ? [...this.hands[playerId]] : [];
  }

  getPublicState(requesterId) {
    const publicHands = {};
    for (const pid of Object.keys(this.hands)) {
      publicHands[pid] = pid === requesterId ? this.hands[pid] : this.hands[pid].length; // hide cards of others
    }
    return {
      gameId: this.id,
      players: this.players.map(p => ({ playerId: p.playerId })),
      hands: publicHands,
      currentTurn: this.players[this.currentTurnIndex].playerId,
      discardTop: this.discardPile.length ? this.discardPile[this.discardPile.length - 1] : null,
      scores: this.scores,
    };
  }

  playCard(playerId, cardCode) {
    // Very simplified: just remove the card from hand if present and place on discard.
    const hand = this.hands[playerId];
    const idx = hand.findIndex(c => c.code === cardCode);
    if (idx === -1) return { error: 'Card not in hand', gameOver: false };
    const [card] = hand.splice(idx, 1);
    this.discardPile.push(card);
    // advance turn
    this.currentTurnIndex = (this.currentTurnIndex + 1) % this.players.length;
    const gameOver = this.checkGameOver();
    return { success: true, cardPlayed: card, gameOver };
  }

  checkGameOver() {
    // Game ends when any player has no cards left.
    return Object.values(this.hands).some(hand => hand.length === 0);
  }

  removePlayer(playerId) {
    // Remove from players array and clean up state.
    this.players = this.players.filter(p => p.playerId !== playerId);
    delete this.hands[playerId];
    delete this.teams[playerId];
    // If less than 2 players remain, end game.
    if (this.players.length < 2) {
      // notify remaining players
      this.players.forEach(p => {
        if (p.ws.readyState === WebSocket.OPEN) {
          p.ws.send(JSON.stringify({ type: 'gameEnded', payload: { reason: 'Not enough players' } }));
        }
      });
      return true;
    }
    return false;
  }
}

module.exports = Game;
