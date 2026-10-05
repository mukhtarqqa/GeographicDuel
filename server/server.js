const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8088;

// In-memory state
const matchmakingQueue = []; // [{ ws, player }]
const rooms = new Map(); // roomCode -> { p1: { ws, player }, p2: null, match: null }
const matches = new Map(); // matchId -> MatchState

// Predefined catalog locations with true coordinates
const LOCATIONS = [
  { id: 'puy_de_sancy', lat: 45.52824, lon: 2.81401, title: 'Пюи-де-Санси', country: 'Франция' },
  { id: 'almaty_medeu', lat: 43.1574, lon: 77.0588, title: 'Медеу', country: 'Казахстан' },
  { id: 'rome_historic', lat: 41.8902, lon: 12.4922, title: 'Рим', country: 'Италия' },
  { id: 'tokyo_metropolis', lat: 35.6762, lon: 139.6503, title: 'Токио', country: 'Япония' },
  { id: 'tromso_fjords', lat: 69.6492, lon: 18.9553, title: 'Тромсё', country: 'Норвегия' },
  { id: 'rio_guanabara', lat: -22.9068, lon: -43.1729, title: 'Рио-де-Жанейро', country: 'Бразилия' },
  { id: 'sydney_harbour', lat: -33.8568, lon: 151.2153, title: 'Сидней', country: 'Австралия' },
  { id: 'cairo_giza', lat: 29.9792, lon: 31.1342, title: 'Каир · Гиза', country: 'Египет' },
  { id: 'new_york_manhattan', lat: 40.7829, lon: -73.9654, title: 'Нью-Йорк', country: 'США' },
  { id: 'london_westminster', lat: 51.5007, lon: -0.1246, title: 'Лондон', country: 'Великобритания' },
];

// Distance calculation using Haversine formula (km)
function calculateHaversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c);
}

function getMultiplierForRound(round) {
  if (round <= 2) return 1.0;
  if (round === 3) return 1.5;
  if (round === 4) return 2.0;
  return 2.5;
}

// HTTP Server
const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/health' || req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      onlinePlayers: wss.clients.size,
      queueLength: matchmakingQueue.length,
      activeMatches: matches.size,
      timestamp: new Date().toISOString()
    }));
    return;
  }

  if (req.url === '/api/leaderboard') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify([
      { name: 'Александр Г.', rating: 1680, rank: 1, wins: 42 },
      { name: 'Елена В.', rating: 1540, rank: 2, wins: 35 },
      { name: 'Марко Поло', rating: 1490, rank: 3, wins: 29 },
      { name: 'Магеллан', rating: 1420, rank: 4, wins: 26 },
      { name: 'Исследователь', rating: 1240, rank: 5, wins: 14 },
    ]));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Geographic Duel Realtime Multiplayer Server is running on port ' + PORT);
});

// WebSocket Server
const wss = new WebSocketServer({ server });

function send(ws, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function createMatch(p1, p2) {
  const matchId = 'm_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
  const locationSeed = Math.floor(Math.random() * 10000);

  const matchState = {
    id: matchId,
    p1: { ws: p1.ws, player: p1.player, health: 6000 },
    p2: { ws: p2.ws, player: p2.player, health: 6000 },
    round: 1,
    locationSeed: locationSeed,
    guesses: {}, // roundNumber -> { p1: {lat, lon}, p2: {lat, lon} }
  };

  matches.set(matchId, matchState);
  p1.ws.currentMatchId = matchId;
  p2.ws.currentMatchId = matchId;

  // Notify Player 1
  send(p1.ws, {
    type: 'match_found',
    matchId: matchId,
    isPlayer1: true,
    opponent: {
      id: p2.player.id,
      name: p2.player.name,
      rating: p2.player.rating,
      health: 6000,
    },
    locationSeed: locationSeed,
  });

  // Notify Player 2
  send(p2.ws, {
    type: 'match_found',
    matchId: matchId,
    isPlayer1: false,
    opponent: {
      id: p1.player.id,
      name: p1.player.name,
      rating: p1.player.rating,
      health: 6000,
    },
    locationSeed: locationSeed,
  });

  console.log(`[Match Created] ${p1.player.name} vs ${p2.player.name} (MatchId: ${matchId})`);
}

function handleGuessSubmission(ws, data) {
  const matchId = data.matchId || ws.currentMatchId;
  const match = matches.get(matchId);
  if (!match) return;

  const isP1 = ws === match.p1.ws;
  const round = data.roundNumber || match.round;
  match.guesses[round] = match.guesses[round] || {};

  const currentGuesses = match.guesses[round];
  if (isP1) {
    currentGuesses.p1 = data.guess;
    // Tell P2 that P1 has guessed
    send(match.p2.ws, { type: 'opponent_guessed', roundNumber: round });
  } else {
    currentGuesses.p2 = data.guess;
    // Tell P1 that P2 has guessed
    send(match.p1.ws, { type: 'opponent_guessed', roundNumber: round });
  }

  // If both submitted
  if (currentGuesses.p1 && currentGuesses.p2) {
    resolveRound(match, round);
  }
}

function resolveRound(match, round) {
  const guesses = match.guesses[round];
  if (!guesses) return;

  // Determine actual location for this round
  const locIndex = (match.locationSeed + round - 1) % LOCATIONS.length;
  const actualLoc = LOCATIONS[locIndex];

  const p1Guess = guesses.p1;
  const p2Guess = guesses.p2;

  let d1 = 20000;
  let d2 = 20000;

  if (p1Guess && typeof p1Guess.latitude === 'number' && typeof p1Guess.longitude === 'number') {
    d1 = calculateHaversineKm(actualLoc.lat, actualLoc.lon, p1Guess.latitude, p1Guess.longitude);
  }
  if (p2Guess && typeof p2Guess.latitude === 'number' && typeof p2Guess.longitude === 'number') {
    d2 = calculateHaversineKm(actualLoc.lat, actualLoc.lon, p2Guess.latitude, p2Guess.longitude);
  }

  const multiplier = getMultiplierForRound(round);
  const distanceDiff = Math.abs(d1 - d2);
  const baseDamage = Math.round(distanceDiff / 20.0);
  const totalDamage = Math.round(baseDamage * multiplier);

  let p1Won = false;
  let p2Won = false;

  if (d1 < d2) {
    p1Won = true;
    match.p2.health = Math.max(0, match.p2.health - totalDamage);
  } else if (d2 < d1) {
    p2Won = true;
    match.p1.health = Math.max(0, match.p1.health - totalDamage);
  }

  const isGameOver = match.p1.health <= 0 || match.p2.health <= 0;

  // Send to P1
  send(match.p1.ws, {
    type: 'round_result',
    roundNumber: round,
    playerWon: p1Won,
    opponentWon: p2Won,
    damage: totalDamage,
    playerDistance: d1,
    opponentDistance: d2,
    playerGuess: p1Guess,
    opponentGuess: p2Guess,
    playerHealth: match.p1.health,
    opponentHealth: match.p2.health,
    isGameOver: isGameOver,
  });

  // Send to P2
  send(match.p2.ws, {
    type: 'round_result',
    roundNumber: round,
    playerWon: p2Won,
    opponentWon: p1Won,
    damage: totalDamage,
    playerDistance: d2,
    opponentDistance: d1,
    playerGuess: p2Guess,
    opponentGuess: p1Guess,
    playerHealth: match.p2.health,
    opponentHealth: match.p1.health,
    isGameOver: isGameOver,
  });

  console.log(`[Round ${round} Resolved] ${match.id} - P1: ${d1}km, P2: ${d2}km. Damage: ${totalDamage}`);
}

wss.on('connection', (ws) => {
  console.log('[Client connected]');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);

      switch (data.type) {
        case 'join_queue': {
          const player = data.player || { id: 'usr_' + Date.now(), name: 'Игрок', rating: 1200 };
          ws.player = player;

          // Remove if already in queue
          const existingIndex = matchmakingQueue.findIndex(q => q.ws === ws);
          if (existingIndex !== -1) matchmakingQueue.splice(existingIndex, 1);

          // Check if queue has another player
          if (matchmakingQueue.length > 0) {
            const opponentEntry = matchmakingQueue.shift();
            createMatch(opponentEntry, { ws, player });
          } else {
            matchmakingQueue.push({ ws, player });
            send(ws, { type: 'queue_joined', status: 'waiting' });
            console.log(`[Queue] Player ${player.name} is waiting...`);
          }
          break;
        }

        case 'cancel_queue': {
          const idx = matchmakingQueue.findIndex(q => q.ws === ws);
          if (idx !== -1) matchmakingQueue.splice(idx, 1);
          send(ws, { type: 'queue_cancelled' });
          break;
        }

        case 'create_room': {
          const roomCode = ('' + Math.floor(1000 + Math.random() * 9000));
          const player = data.player || { id: 'usr_' + Date.now(), name: 'Игрок', rating: 1200 };
          rooms.set(roomCode, { p1: { ws, player }, p2: null });
          ws.roomCode = roomCode;
          send(ws, { type: 'room_created', roomCode: roomCode });
          console.log(`[Room Created] Code: ${roomCode} by ${player.name}`);
          break;
        }

        case 'join_room': {
          const roomCode = String(data.roomCode).trim();
          const room = rooms.get(roomCode);
          if (!room) {
            send(ws, { type: 'room_error', message: 'Комната с таким кодом не найдена.' });
            return;
          }
          if (room.p2) {
            send(ws, { type: 'room_error', message: 'Комната уже заполнена.' });
            return;
          }
          const player = data.player || { id: 'usr_' + Date.now(), name: 'Гость', rating: 1200 };
          room.p2 = { ws, player };
          rooms.delete(roomCode);
          createMatch(room.p1, room.p2);
          break;
        }

        case 'submit_guess': {
          handleGuessSubmission(ws, data);
          break;
        }

        case 'next_round': {
          const matchId = data.matchId || ws.currentMatchId;
          const match = matches.get(matchId);
          if (match) {
            match.round = (data.roundNumber || match.round + 1);
            send(match.p1.ws, { type: 'round_started', roundNumber: match.round });
            send(match.p2.ws, { type: 'round_started', roundNumber: match.round });
          }
          break;
        }

        case 'forfeit': {
          const matchId = data.matchId || ws.currentMatchId;
          const match = matches.get(matchId);
          if (match) {
            const isP1 = ws === match.p1.ws;
            const winnerWs = isP1 ? match.p2.ws : match.p1.ws;
            send(winnerWs, { type: 'opponent_forfeited' });
            matches.delete(matchId);
          }
          break;
        }
      }
    } catch (err) {
      console.error('[WS Message Error]', err);
    }
  });

  ws.on('close', () => {
    // Remove from queue
    const qIndex = matchmakingQueue.findIndex(q => q.ws === ws);
    if (qIndex !== -1) matchmakingQueue.splice(qIndex, 1);

    // Remove from rooms
    if (ws.roomCode) rooms.delete(ws.roomCode);

    // Handle ongoing match disconnect
    if (ws.currentMatchId) {
      const match = matches.get(ws.currentMatchId);
      if (match) {
        const isP1 = ws === match.p1.ws;
        const otherWs = isP1 ? match.p2.ws : match.p1.ws;
        send(otherWs, { type: 'opponent_disconnected', message: 'Соперник отключился от дуэли.' });
        matches.delete(ws.currentMatchId);
      }
    }
  });
});

server.listen(PORT, () => {
  console.log(`===============================================`);
  console.log(`🌍 GEOGRAPHIC DUEL REALTIME MULTIPLAYER SERVER`);
  console.log(`🚀 HTTP API running on: http://localhost:${PORT}/health`);
  console.log(`🔌 WebSocket running on: ws://localhost:${PORT}`);
  console.log(`===============================================`);
});
