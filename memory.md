# 🧠 MEMORY.md — PIXEL GALAXY WORLD
> **Dokumen Memori Proyek** — Baca file ini dulu sebelum melanjutkan pengembangan!
> Terakhir diperbarui: Sesi 3 — setelah commit pertama ke GitHub `main`

---

## 📌 IDENTITAS PROYEK

| Item | Detail |
|------|--------|
| **Nama Game** | Pixel Galaxy World |
| **Genre** | Colony Simulation / Survival (inspirasi RimWorld) |
| **Inspirasi** | RimWorld (PC, oleh Ludeon Studios) — *hanya inspirasi, bukan tiruan* |
| **Engine** | GDevelop (APK / Android mobile app) |
| **Platform Target** | 📱 Mobile (Android) dulu → 💻 PC (desktop) nanti |
| **Bahasa UI** | Indonesia (default) |
| **Repo GitHub** | `KenopsiaHUB-101/Pixel-Galaxy-World` (branch: `main`) |
| **Pemilik** | KenopsiaHUB-101 |

---

## 🎮 KONSEP GAME (SATU PARAGRAF)

**Pixel Galaxy World** adalah game simulasi koloni pixel-art di planet asing. Pemain memimpin 3 kolonis yang terdampar di planet **Kepler-Pixel 7** setelah kapal mereka jatuh. Pemain harus membangun rumah, mencari makanan, bertahan dari serangan monster alien, dan menjaga mood kolonis agar koloni bertahan hidup. Setiap kolonis punya needs (hunger, sleep, mood) seperti RimWorld, dan game berjalan dengan kontrol sentuh (touch) untuk mobile. **Target menang: bertahan 30 hari. Kalah: semua kolonis tumbang.**

---

## 🗺️ STRUKTUR REPO

```
Pixel-Galaxy-World/
├── memory.md               ← FILE INI — sumber kebenaran proyek
├── README.md               ← (BELUM ADA) Cara buka proyek di GDevelop APK
├── docs/
│   ├── GDD.md              ← ✅ Game Design Document lengkap
│   ├── ASSETS_INDEX.md     ← (BELUM ADA) Katalog semua asset
│   └── ROADMAP.md          ← (BELUM ADA) Roadmap pengembangan
├── project/
│   ├── game.json           ← (BELUM ADA!) File proyek GDevelop utama
│   └── resources/          ← ✅ Asset yang dipakai game (152 PNG, 6.3MB)
│       ├── characters/     ← ✅ rex/luna/bolt 0-5 (32x48)
│       ├── monsters/       ← ✅ 5 monster 0-5 (64x64)
│       ├── tiles/          ← ✅ 17 tile terrain 32x32 + night-overlay
│       ├── buildings/      ← ✅ 21 sprite bangunan
│       ├── items/          ← ✅ 21 sprite item/resource
│       ├── ui/             ← ✅ 17 sprite panel/tombol/ikon
│       ├── effects/        ← ✅ 25 sprite FX
│       └── menu/           ← ✅ title-art, menu-background, logo-icon
├── tools/                  ← ✅ Pipeline & builder (Python)
│   ├── process_sprites.py  ← ✅ Chroma-key + slice + resize pipeline
│   ├── gd_lib.py           ← ✅ Helper builder JSON GDevelop
│   ├── gd_objects.py       ← ✅ 59 definisi objek (tervalidasi)
│   ├── gd_scenes.py        ← ✅ Logika 3 scene (MainMenu/GameScene/GameOver)
│   └── build_game.py       ← (BELUM ADA!) Assembler → project/game.json
└── assets-source/          ← ✅ Sheet master resolusi tinggi (JANGAN DIHAPUS)
```

**ATURAN PENTING:**
- Nama file resource: **huruf kecil, tanpa spasi** (pakai `-` atau `_`).
- Ukuran tile = **32x32 px**, sprite karakter = **32x48 px**, monster = **64x64 px**.
- Jangan pernah menghapus file di `assets-source/` — itu cadangan master.
- Jangan pernah menulis `game.json` manual — selalu via `tools/build_game.py` (nanti dibuat).

---

## 🧑‍🚀 KARAKTER & ENTITAS (KANON GAME)

### Kolonis (pemain memimpin)
| Kolonis | Peran | Ciri | HP | Kecepatan |
|---------|-------|------|----|-----------|
| **Rex** | Builder/Miner | Rambut pirang, kuat | 100 | 120 |
| **Luna** | Farmer/Doctor | Rambut pink, pintar | 100 | 120 |
| **Bolt** | Chef/Hunter | Botak + bandana, cepat | 100 | 120 |

Animasi kolonis: `walk` (frame 0-3) · `idle` (frame 4) · `attack` (frame 5) · `work` (frame 4)

### Monster Alien (musuh)
| Monster | HP | Damage | Speed | Perilaku |
|---------|----|--------|-------|----------|
| **Slime** | 40 | 5 | 60 | Lemah, spawn malam |
| **Zapper** | 30 | 8 | 90 | Cepat, serang listrik |
| **Golem** | 150 | 15 | 40 | Lambat, HP besar |
| **Stalker** | 80 | 20 | 100 | Muncul saat raid/invasi |
| **Bat** | 25 | 6 | 110 | Cepat, spawn raid |

### Sumber Daya (Resources)
`Kayu (Wood)` · `Batu (Stone)` · `Logam (Metal)` · `Kristal (Crystal)` · `Makanan (Food)` · `Energi (Energy)`

### Node sumber daya (bisa dipanen)
Tree(5 wood) · Rock(5 stone) · MetalOre(4 metal) · CrystalVein(3 crystal) · BerryBush(4 food)

---

## ✅❌ STATUS: APA SAJA YANG SUDAH & BELUM TERPENUHI

### ✅ SUDAH SELESAI (DONE)

**Phase 1 — Setup & Fondasi** (SELESAI 100%)
- [x] Repo GitHub `KenopsiaHUB-101/Pixel-Galaxy-World` aktif, branch `main`
- [x] Struktur folder proyek lengkap (docs/project/tools/assets-source)
- [x] `memory.md` v1 dibuat
- [x] `docs/GDD.md` lengkap (Bahasa Indonesia): konsep, core loop, kolonis, monster, resources, bangunan, teknis

**Phase 2 — Produksi Asset** (SELESAI 100%)
- [x] 3 karakter kolonis (Rex/Luna/Bolt) × 6 frame animasi @32x48 — `characters/`
- [x] 5 monster (Slime/Zapper/Golem/Stalker/Bat) × 6 frame @64x64 — `monsters/`
- [x] 17 tile terrain 32x32 (grass, dirt, snow, water, dll) — `tiles/`
- [x] 21 sprite bangunan (wall, bed, campfire, turret, dll) — `buildings/`
- [x] 21 sprite item/resource — `items/`
- [x] 17 sprite UI (panel ui-0, tombol ikon ui-5/6/7/15, portrait, dll) — `ui/`
- [x] 25 sprite efek FX (ledakan, hit) — `effects/`
- [x] Title art + menu background + logo — `menu/`
- [x] `night-overlay.png` (overlay malam semi-transparan, RGBA alpha 140)
- [x] Pipeline `process_sprites.py`: chroma-key magenta → slice frame → resize → quantize
- [x] **Total: 152 PNG siap pakai, 6.3MB** (< 30MB target mobile ✅)

**Phase 3 — Build Proyek GDevelop** (± 75% SELESAI)
- [x] `gd_lib.py` — helper builder JSON (instance, animation, text_object, dll) — format tervalidasi dari contoh resmi GDevelop
- [x] `gd_objects.py` — **59 objek tervalidasi**:
  - 3 kolonis (variabel: hp, hunger, sleep, mood, speed, state, jobTargetX/Y, jobType, jobNode, isSelected, isDown, name)
  - 5 monster (variabel: hp, dmg, speed, state; anim move+attack)
  - 5 node resource (variabel: resource, amount, isHarvested)
  - 12 bangunan (variabel: category, cost, costRes, isBuilt, isBlueprint)
  - CrashPod, ItemDrop, Bullet, FXExplosion, FXHit
  - TileGrass, TileDirt (collision off, hemat performa)
  - UI: UIPanel, UIPortrait, UIIcon, + **7 tombol**: BtnStart/BtnQuit/BtnRetry (panel 96x46) + BtnPause/BtnPlay/BtnFast/BtnBuild (ikon 96x89-ish)
  - 12 text object HUD, MenuBackground, TitleArt, NightOverlay, BuildGhost
- [x] `gd_scenes.py` — logika 3 scene, 624 event GameScene (1144 kondisi / 1916 aksi), 5.877 instance:
  - **MainMenu**: background + tombol Mulai/Keluar
  - **GameScene**: Setup var → kamera drag-pan → siklus day/night (1 hari = 8 menit) → seleksi kolonis tap → perintah kerja (panen node) → eksekusi kerja (AddForceTowardPosition) → needs decay → auto-makan → tidur malam → death check → win check (30 hari) → HUD update → pause/speed → build mode (tap pasang WallWood) → spawn monster malam (timer 8s) → raid berkala (timer RaidTimer, makin cepat) → AI monster kejar kolonis → serangan monster → kolonis serang monster (tap monster)
  - **GameOver**: statistik + tombol Main Lagi

### ❌ BELUM TERPENUHI (TODO)

**Phase 3 — sisa 25%** (KRITIS — game belum bisa dibuka!)
- [ ] **`tools/build_game.py`** — assembler yang menggabungkan gd_lib + gd_objects + gd_scenes → `project/game.json`:
  - properties: orientation landscape, windowWidth 909, windowHeight 513, packageName `com.kenopsia.pixelgalaxyworld`, name, author
  - resources: dari `scan_resources()` (152 entri)
  - global variables: `G_Result`, `G_Stat`, `G_Day` (cross-scene), scene variables GameScene
  - 3 layouts (MainMenu, GameScene, GameOver) + objects + instances + events + layers + behaviorsSharedData
  - `firstLayout: "MainMenu"`, `gdVersion`
- [ ] **FIX BUG di `gd_scenes.py`:**
  1. **Bug ternary GameOver**: `ModVarSceneTxt` pakai ekspresi ternary `? :` — TIDAK VALID di GDevelop! Ganti: variabel global `G_Result`/`G_Stat` di-set saat keluar GameScene (di `_death_check` & `_win_check`), GameOver tinggal baca `GlobalVariableString(G_Stat)`
  2. **NightOverlay tidak punya instance** di `_game_instances()` — event Show/Hide tidak akan ber efek; tambah instance (custom size W×H, z=90, alpha via PNG)
  3. **Cross-scene `WinFlag`/`Day`**: scene variable TIDAK persist antar scene — harus jadi **global variable** (`G_Result`, `G_Stat`, `G_Day`) via `ModVarGlobal`/`GlobalVariable()`
- [ ] **Test**: validasi JSON final + sanity check struktur game.json (semua object/instance ter-definisi, resource ada)
- [ ] Buka game.json di GDevelop → pastikan scene ter-load tanpa error

**Phase 4 — Dokumentasi & Delivery** (BELUM MULAI)
- [ ] `README.md` — cara buka proyek di GDevelop APK/Android step-by-step
- [ ] `docs/ASSETS_INDEX.md` — katalog 152 asset (nama, lokasi, fungsi, ukuran)
- [ ] `docs/ROADMAP.md` — roadmap pengembangan (fitur setelah v1: tutorial, research, dll)
- [ ] Update memory.md final
- [ ] Commit + push ke GitHub (branch feature → PR ke main)
- [ ] (Opsional user) Export APK via GDevelop online services

**Fitur game v1.1+ (nice-to-have, belum dibuat):**
- [ ] Pinch-zoom kamera (v1 hanya drag-pan)
- [ ] Build menu lengkap (12 bangunan — v1 hanya WallWood)
- [ ] Blueprint system (bangunan perlu dibangun kolonis)
- [ ] Item drop fisik saat panen (v1 langsung masuk inventory scene var)
- [ ] Turret menembak otomatis (object Bullet sudah ada, belum dipakai)
- [ ] Sound effect & musik (file audio belum ada sama sekali!)
- [ ] Save/Load game
- [ ] Tutorial scene
- [ ] Pathfinding (v1 pakai AddForce langsung)

---

## 🔧 SPESIFIKASI TEKNIS (KUNCI GDEVELOP)

- **Resolution:** 909x513 landscape → GDevelop auto-scale fullscreen mobile
- **World size:** 3200x1800 (100x56 tile @32px), kamera pan via drag
- **Renderer:** WebGL (default GDevelop)
- **Kontrol touch:** tap = pilih/kerja, drag = pan kamera (gerak <6px = tap)
- **Kolom waktu:** TimeOfDay 0..1 (0.7-0.98 = malam), 1 hari = 480 detik / GameSpeed
- **GameSpeed:** 1 (normal) / 2 (fast) / 0 (pause) — tombol HUD

---

## 🧪 FORMAT INSTRUKSI GDEVELOP TERVERIFIKASI (WAJIB BACA!)

Dari analisis source C++ GDevelop (4ian/GDevelop) + contoh resmi (asteroids, camera, rts). **JANGAN pakai format lain** — sudah banyak bug tertangkap karena format salah:

| Instruksi | Tipe | Parameter | Catatan |
|-----------|------|-----------|---------|
| `Distance` | cond | `[objA, objB, jarak, ""]` | true jika jarak < nilai (4 param!) |
| `VarObjet` / `ModVarObjet` | cond/act | `[obj, var, op, nilai]` | **hanya var angka** |
| `VarObjetTxt` / `ModVarObjetTxt` | cond/act | `[obj, var, op, "\"teks\""]` | var string objek |
| `VarScene` / `ModVarScene` | cond/act | `[var, op, nilai]` | var angka scene (hidden tapi jalan — dipakai camera.json resmi) |
| `VarSceneTxt` / `ModVarSceneTxt` | cond/act | `[var, op, "\"teks\""]` | var string scene |
| `ModVarGlobal` / `VarGlobal` | act/cond | `[var, op, nilai]` | var global (hidden tapi jalan) |
| `SetNumberVariable` / `NumberVariable` | act/cond | `[nama, op, nilai]` | bentuk modern, bare name = scene var |
| `SetStringVariable` / `StringVariable` | act/cond | `[nama, op, "\"teks\""]` | bentuk modern string |
| `GlobalVariable(nama)` / `GlobalVariableString(nama)` | ekspresi | — | baca global var (dipakai example-game.json resmi) |
| `Variable(nama)` | ekspresi | — | baca scene var |
| `AnimatableCapability::AnimatableBehavior::SetName` | act | `[obj, "Animation", "=", "\"nama\""]` | set animasi by name — behavior harus match behaviorsSharedData "Animation" |
| `AddForceTowardPosition` | act | `[obj, X, Y, kecepatan, multiplier]` | multiplier 1 = gaya konstan |
| `AddForceTowardObject` | act | `[obj, objTarget, kecepatan, multiplier]` | kejar objek |
| `Create` | act | `["", namaObj, xExpr, yExpr, "\"\""]` | 5 param, layer quoted kosong |
| `Delete` | act | `[obj, ""]` | 2 param |
| `Hide` / `Show` | act | `[obj]` | |
| `Quit` | act | `[""]` | 1 param code-only |
| `Timer` | cond | `["", detik, "\"nama\""]` | timer bernama |
| `ResetTimer` | act | `["", "\"nama\""]` | |
| `Wait` | act | `[detik]` | |
| `MouseButtonPressed` / `Released` | cond | `["", "Left"]` | |
| `IsCursorOnObject` | cond | `[obj, "", "yes", ""]` | param3 = precise yes |
| `CollisionNP` | cond | `[objA, objB, "", ""]` | 4 param |
| `TextObject::String` | act | `[textObj, "=", "ekspresi"]` | set teks |
| `Scene` | act | `["", "\"NamaScene\"", "true"]` | ganti scene |
| `SceneBackground` | act | `["", "\"R;G;B\""]` | warna bg |
| `SetCameraCenterX` / `Y` | act | `["", "+/-", ekspresi, "\"\"", "\"\""]` | kamera |
| `MouseX("",0)` / `MouseY("",0)` | ekspresi | — | posisi kursor |
| `CameraCenterX("")` / `Y("")` | ekspresi | — | posisi kamera |

**Format JSON GDevelop:**
- Event standar: `{"type":"BuiltinCommonInstructions::Standard","conditions":[...],"actions":[...]}` + optional `"events":[...]` (sub-event)
- Item kondisi/aksi: `{"type":{"value":"Nama"},"parameters":[...]}`
- String di parameter harus **double-escaped**: `\"teks\"`
- `behaviorsSharedData` per scene: Animation/Effect/Flippable/Opacity/Resizable/Scale/Text (capability types)
- gdVersion: `{"build":280,"major":5,"minor":6,"revision":0}` (match rts.json)

---

## ⚠️ HAL YANG TELAH DIPUTUSKAN (JANGAN DITANYA LAGI KE USER)

1. ✅ Engine = **GDevelop APK** (bukan Godot/Unity)
2. ✅ Target = **Mobile dulu**, PC belakangan
3. ✅ Penyimpanan = **Repo GitHub ini** (branch `main`, push via `x-access-token:$GITHUB_TOKEN`)
4. ✅ Semua asset harus **lengkap** (karakter, monster, tileset, dll)
5. ✅ Gaya seni = **pixel art 32x32** tema "galaxy/outer space planet"
6. ✅ Bahasa dokumentasi = Indonesia; nama file/object = English
7. ✅ Membuat game via generator Python (tools/) — bukan edit manual game.json

---

## 📝 CATATAN SESI (LOG)

### Sesi 3 — Commit pertama + memory.md status
- **COMMIT `727a7c0` → PUSH ke `main` BERHASIL** (174 file: asset 152 PNG + tools + GDD + memory)
- gd_objects.py: +jobNode var, +attack/work anim kolonis, +7 objek tombol (BtnStart/Quit/Retry/Pause/Play/Fast/Build), NightOverlay → night-overlay.png, fix path scan_resources() → 59 objek tervalidasi
- Verifikasi format var global: `ModVarGlobal`/`GlobalVariable()` hidden tapi functional (dipakai example resmi)
- **TEMUAN KRITIS**: WinFlag/Day GameScene → GameOver tidak persist (scene var) → harus global var `G_Result`/`G_Stat`/`G_Day`
- memory.md di-rewrite penuh dengan status DONE/TODO detail
- **NEXT**: buat `tools/build_game.py` → fix 3 bug gd_scenes → test → Phase 4 docs → PR

### Sesi 2 — Perbaikan besar gd_scenes.py
- Rewrite penuh gd_scenes.py (sebelumnya broken line 366 + missing _assign_job)
- Fix: Distance (bukan DistanceBetweenTwoObjects, 4 param), VarObjetTxt/ModVarObjetTxt utk string var, AnimatableCapability::AnimatableBehavior::SetName (bukan SetAnimationName)
- Validasi: 209 event top-level, semua dict valid, JSON serializable

### Sesi 1 — Setup & asset
- Repo dikloning (kosong) → struktur folder dibuat
- memory.md, GDD dibuat
- Generate semua asset: karakter, monster, tile, building, item, UI, FX, menu
- Pipeline process_sprites.py: chroma-key magenta, slice frame, resize, quantize
