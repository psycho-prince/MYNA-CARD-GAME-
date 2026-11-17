# MYNA Card Game

This repository contains a **cross‑platform** implementation of the MYNA card game:

- **Flutter client** – builds an Android APK that runs on low‑end devices. The same code can also be compiled for desktop/web if desired.
- **Node.js server** – a lightweight LAN‑only WebSocket server that handles matchmaking, dealing cards, turn order, and scoring.

## Project Structure

```
MYNA-CARD-GAME/
├─ README.md                 # This file
├─ server/                    # Node.js multiplayer server
│   ├─ package.json
│   ├─ index.js               # Server entry point
│   └─ game.js                # Core game logic
└─ client/                    # Flutter mobile client
    ├─ pubspec.yaml
    └─ lib/
        ├─ main.dart          # App entry point
        ├─ game_page.dart     # UI for playing a game
        └─ models.dart        # Card, deck, and game state definitions
```

## Getting Started

### 1. Run the Server (LAN host)
```bash
cd MYNA-CARD-GAME/server
npm install   # install dependencies
node index.js  # starts the server on port 3000
```
The server listens on `ws://<host-ip>:3000` and accepts connections from any client on the same LAN.

### 2. Build & Run the Android Client
```bash
cd MYNA-CARD-GAME/client
flutter pub get
flutter build apk --release   # produces an APK in build/app/outputs/apk/release
```
Transfer the generated APK to any Android device (e.g., via USB or ADB) and install it.

When the app starts, enter the IP address of the server (e.g., `192.168.1.10`) and tap **Connect**. You will be placed in a lobby where you can create or join a game for 4, 6, or 8 players.

## Game Rules (implemented)
- Each game uses three standard 52‑card decks (156 cards).
- Players are dealt **13 cards** each.
- Teams of two ("Myna") compete; the last two players remaining form a Myna.
- Scoring follows the description you provided (rummy, sets, jokers, etc.).

The implementation focuses on a **minimal playable prototype**; you can extend UI and rules later.

## License
MIT – feel free to modify and redistribute.
