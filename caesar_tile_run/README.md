# Caesar's Gambit: Via Caesaris (Tile Runner)
**Fest Event**: Caesar's Gambit!  
**Work Allotment**: Kavya's Task (Fall Guys based tile game with Roman characters for hints - 2-player cooperative checkpoint)  
**Engine**: Godot 4.7.1 (GDScript, 3D Forward+)  
**Deadline**: 30 September  

---

## 🏛️ Game Concept & Fest Context
At this checkpoint, 2 players (out of the 4 overall festival participants) arrive at the **Via Caesaris**. 
To unlock the gateway to the final 4-player chamber:
1. They face a treacherous chasm with a grid of floating ancient Roman stone tiles carved with Latin letters.
2. An imposing **Caesar Inscription Tablet (Tabula Caesaris)** at the start gives them an encrypted message and a Caesar Shift key (e.g., `CIPHER: URPD`, `SHIFT: -3` ➔ `ROMA`).
3. Stepping on the correct tiles lights them up in **golden laurel glow** and keeps them solid for both players.
4. Stepping on a fake tile triggers a violent shake and crumble, dropping the player into the misty abyss to respawn at the start terrace!
5. Both players must work together to find and cross the safe path to the **Roman Triumphal Finish Arch**.

---

## 🎮 Controls
| Action | Key / Input |
|---|---|
| **Move** | `W`, `A`, `S`, `D` or Arrow Keys |
| **Jump** | `Spacebar` |
| **Fall Guys Dive** | `E` or `Shift` |
| **Look / Orbit Camera** | Mouse Movement |
| **Release / Lock Mouse** | `Escape` |
| **Toggle Caesar Clue / Hint** | `H` |

---

## 🌐 2-Player LAN Multiplayer Setup
This game uses Godot 4's built-in **ENet High-Level Multiplayer**:

### Option A: Two Laptops on the same College Wi-Fi / Phone Hotspot
1. Connect both laptops to the same Wi-Fi network (or turn on mobile hotspot on one phone and connect both).
2. **Player 1 (Laptop 1)**:
   - Double-click `run_game.bat` (or open in Godot).
   - In the lobby menu, click **"HOST LAN GAME (PLAYER 1 - CAESAR)"**.
   - Note the LAN IP displayed (e.g., `192.168.1.42`).
3. **Player 2 (Laptop 2)**:
   - Double-click `run_game.bat`.
   - In the IP box, type Laptop 1's LAN IP.
   - Click **"JOIN GAME"**.
   - Player 2 will spawn in Azure & Silver armor beside Player 1!

### Option B: Solo Test / Instant Play
- Click **"SOLO PRACTICE / TEST MODE"** on the main menu to immediately play through the course alone.

### Option C: Dual Instance Test on a Single PC
- Double-click `run_lan_test.bat`. It will automatically launch two game windows side-by-side on your screen so you can test LAN multiplayer right on your computer.

---

## 🎨 Asset Integration Guide (Team Coordination)

### 1. Sketchfab 3D Models (`assets/models/`)
The game is built with modular procedural Roman architecture (PBR marble, gold laurels, Colosseum columns, Triumphal Arch, Centurion crest). 
- If you download `.glb` / `.gltf` models from [Sketchfab](http://sketchfab.com/) (e.g. Colosseum statues, Roman helmets, stone ruins), drag them into `assets/models/` in the Godot project. Godot 4 imports them automatically!

### 2. Audio & Sounds for Karen (`assets/audio/`)
The game has built-in synthesized chimes, crumbling rock sounds, and victory brass fanfares so it works out-of-the-box.
When Karen prepares audio files:
- Place them in `assets/audio/`:
  - `safe_chime.wav` (when stepping on a safe tile)
  - `crumble.wav` (when stepping on a fake tile)
  - `victory.wav` (fanfare when reaching the finish arch)
The game will automatically detect and play them!

### 3. Roman Characters & Symbols for Camron
Roman Latin letters (`A`-`Z`, `ROMA`, `VENI`, `VICI`, `AUREUS`, `GLADIO`) are dynamically projected on the tiles with Caesar shifts. Camron's symbols can be dropped directly into the `CaesarCipher.ROMAN_WORDS` dictionary in `scripts/caesar_cipher.gd`.
