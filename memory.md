# 🧠 MEMORY.md — PIXEL GALAXY WORLD
> **Dokumen Memori Proyek** — Baca file ini dulu sebelum melanjutkan pengembangan!
> Terakhir diperbarui: **Sesi 4 — v1.0 SELESAI** · game.json dibangun & tervalidasi · audio dibuat · docs lengkap

---

## 📍 IDENTITAS PROYEK

| Item | Detail |
|------|--------|
| **Nama Game** | Pixel Galaxy World |
| **Genre** | Colony Simulation / Survival (inspirasi RimWorld) |
| **Inspirasi** | RimWorld (PC, oleh Ludeon Studios) — *hanya inspirasi, bukan tiruan* |
| **Engine** | GDevelop 5.0.280 (APK / Android mobile app) |
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
├── memory.md               ← FILE INI — sumber kebenaran proyek ✅ FINAL v1.0
├── README.md               ← ✅ Cara buka proyek di GDevelop APK (Opsi A/B), kontrol, lore, rebuild
├── docs/
│   ├── GDD.md              ← ✅ Game Design Document lengkap
│   ├── ASSETS_INDEX.md     ← ✅ Katalog 156 asset (79 dipakai v1.0, 77 cadangan v1.1+)
│   └── ROADMAP.md          ← ✅ Roadmap v1.0→v1.5 + technical backlog
├── project/
│   ├── game.json           ← ✅✅ FILE PROYEK UTAMA — 2.94MB, 3 layouts, 59 objects,
│   │                          156 resources, 214 events, 5.887 instance — VALIDASI OK
│   └── resources/          ← ✅ Asset yang dipakai game (156 file: 152 PNG + 4 WAV)
│       ├── audio/          ← ✅ menu.wav (423KB) · ambient.wav (529KB) · alert.wav · build.wav
│       ├── characters/     ← ✅ rex/luna/bolt 0-5 (32x48)
│       ├── monsters/       ← ✅ 5 monster 0-5 (64x64)
│       ├── tiles/          ← ✅ 17 tile terrain 32x32 + night-overlay
│       ├── buildings/      ← ✅ 21 sprite bangunan
│       ├── items/          ← ✅ 21 sprite item/resource
│       ├── ui/             ← ✅ 17 sprite panel/tombol/ikon
│       ├── effects/        ← ✅ 25 sprite FX
│       └── menu/           ← ✅ title-art, menu-background, logo-icon
├── tools/                  ← ✅ Pipeline & builder (Python) — SEMUA SELESAI
│   ├── process_sprites.py  ← ✅ Chroma-key + slice + resize pipeline
│   ├── gd_lib.py           ← ✅ Helper builder JSON GDevelop
│   ├── gd_objects.py       ← ✅ 59 definisi objek + scan_resources() (152 PNG + 4 WAV)
│   ├── gd_scenes.py        ← ✅ Logika 3 scene + 9 patch audio + fix bug ternary/NightOverlay/global var
│   ├── gen_audio.py        ← ✅ Sintesis WAV stdlib Python (wave+math+struct, mono 16-bit 22050Hz)
│   └── build_game.py       ← ✅✅ Assembler → project/game.json + validator 8-check
└── assets-source/          ← ✅ Sheet master resolusi tinggi (JANGAN DIHAPUS)
```

**ATURAN PENTING:**
- Nama file resource: **huruf kecil, tanpa spasi** (pakai `-` atau `_`).
- Ukuran tile = **32x32 px**, sprite karakter = **32x48 px**, monster = **64x64 px**.
- Jangan pernah menghapus file di `assets-source/` — itu cadangan master.
- Jangan pernah mengedit `game.json` manual — selalu via `cd tools && python3 build_game.py`.
- **Rebuild**: `cd tools && python3 build_game.py` (butuh gd_lib/gd_objects/gd_scenes + folder resources/).

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

## ✅ STATUS: v1.0 SELESAI (SEMUA PHASE DONE)

### ✅ Phase 1 — Setup & Fondasi (SELESAI 100%)
- [x] Repo GitHub `KenopsiaHUB-101/Pixel-Galaxy-World` aktif, branch `main`
- [x] Struktur folder proyek lengkap (docs/project/tools/assets-source)
- [x] `memory.md` dibuat & di-update tiap sesi
- [x] `docs/GDD.md` lengkap (Bahasa Indonesia)

### ✅ Phase 2 — Produksi Asset (SELESAI 100%)
- [x] 3 karakter kolonis × 6 frame @32x48 · 5 monster × 6 frame @64x64 · 17 tile 32x32
- [x] 21 bangunan · 21 item · 17 UI · 25 FX · 3 menu art · night-overlay
- [x] Pipeline `process_sprites.py` (chroma-key magenta → slice → resize → quantize)
- [x] **4 audio WAV** via `gen_audio.py` (menu/ambient/alert/build) — ffmpeg tidak ada → sintesis stdlib
- [x] **Total: 156 resource (152 PNG 6.3MB + 4 WAV ~1MB)** — dipakai game v1.0: 79 (75 PNG + 4 WAV)

### ✅ Phase 3 — Build Proyek GDevelop (SELESAI 100%)
- [x] `gd_lib.py` — helper builder JSON (instance, animation, text_object, dll)
- [x] `gd_objects.py` — 59 objek (kolonis, monster, node, 12 bangunan, UI 7 tombol, 12 text HUD, tile, FX, dll) + scan_resources() 156 resource (audio kind=audio, preloadAsMusic)
- [x] `gd_scenes.py` — 3 scene, **214 event top-level GameScene**, instance: MainMenu 7 / GameScene 5.878 / GameOver 4:
  - MainMenu (menu.wav loop ch1) · GameScene (ambient.wav loop ch2) · GameOver (statistik + retry)
  - Kamera drag-pan · siklus day/night 8 menit/hari · seleksi kolonis tap · perintah kerja panen · needs decay · auto-makan · tidur malam · death/win check (30 hari) · HUD · pause/speed · build mode WallWood · spawn monster malam + raid berkala · AI kejar & serang
  - **3 BUG CRITICAL DIPERBAIKI (Sesi 3-4):** (1) ternary `? :` invalid → global var `G_Title`/`G_Stat` di-set di _death_check/_win_check, GameOver baca `GlobalVariableString()`; (2) NightOverlay tanpa instance → instance W×H z=90 ditambah + Hide saat Setup; (3) cross-scene var → global var
  - **9 PATCH AUDIO (Sesi 4):** PlaySoundOnChannel menu ch1 vol60 loop + ambient ch2 vol40 loop + alert ch3 + build ch4; StopSoundChannel ch1 di BtnStart/BtnQuit, ch2 di BtnRetry/_death_check/_win_check (sound manager persist antar scene!)
- [x] `gen_audio.py` — sintesis WAV: menu.wav (arpeggio triangle A-minor pentatonic + bass sine, 9.6s), ambient.wav (drone E2/B2 + wind noise, 12s fade-loop), alert.wav (square 660→880Hz ×2, 0.61s), build.wav (thud+hit+click, 0.2s)
- [x] `build_game.py` — assembler: properties exact 5.0.280 (dari rts.json: platformSpecificAssets 27 key, loadingScreen full, watermark, maxFPS 60/minFPS 20), global vars G_Title/G_Stat, 3 layouts (b/r/v=255, behaviorsSharedData, stopSoundsOnStartup False), firstLayout MainMenu, gdVersion 5.6.0.280, window 909x513 landscape, packageName com.kenopsia.pixelgalaxyworld, pixelsRounding True
- [x] **`project/game.json` DIBANGUN: 2.938.505 bytes — VALIDASI OK (8 check lolos + negative test pass)**
  - Validasi: JSON serializable · instance↔object · param0 object refs · resource↔file disk · image↔resource (animations→directions→sprites, field `image`) · firstLayout valid · PlaySound 5/PlaySoundOnChannel 6 param · StopSoundChannel 2 param · audio file refs
  - Audit final: 34 kombinasi (instruction, param-count) unik — SEMUA cocok dengan source C++ engine / contoh resmi

### ✅ Phase 4 — Dokumentasi & Delivery (SELESAI)
- [x] `README.md` — badges, gameplay, cara buka di GDevelop Android (Opsi A: app Play Store → Open Project → project/game.json; Opsi B: web/desktop), kontrol, struktur repo, rebuild, lore, MIT license
- [x] `docs/ASSETS_INDEX.md` — katalog 156 asset per-folder + mapping objek↔image (building-10→WallWood/BuildGhost, ui-0→BtnStart/BtnQuit/BtnRetry/UIPanel, item-0..4→Tree/Rock/MetalOre/CrystalVein/BerryBush, dll)
- [x] `docs/ROADMAP.md` — v1.1 Base Building · v1.2 Biome (77 asset cadangan) · v1.3 Combat depth · v1.4 Colony meta · v1.5 Polish/PC + technical backlog (Pathfinding, objectsGroups, optimasi 5.878 instance tile)
- [x] Update memory.md final (file ini)
- [x] Git: feature branch → commit → push → PR → merge ke `main`

### 🎯 VERSI v1.0 SIAP DIMAINKAN
Game lengkap bisa dibuka: clone repo → buka GDevelop app (Android) → Open Project → `Pixel-Galaxy-World/project/game.json` → Preview/Export.

---

## 🔧 SPESIFIKASI TEKNIS (KUNCI GDEVELOP)

- **Resolution:** 909x513 landscape → GDevelop auto-scale fullscreen mobile
- **World size:** 3200x1800 (100x56 tile @32px), kamera pan via drag
- **Renderer:** WebGL (default GDevelop)
- **Kontrol touch:** tap = pilih/kerja, drag = pan kamera (gerak <6px = tap)
- **Kolom waktu:** TimeOfDay 0..1 (0.7-0.98 = malam), 1 hari = 480 detik / GameSpeed
- **GameSpeed:** 1 (normal) / 2 (fast) / 0 (pause) — tombol HUD
- **Audio channel:** ch1 menu (loop vol60) · ch2 ambient (loop vol40) · ch3 alert one-shot · ch4 build one-shot — **StopSoundChannel wajib di tiap transisi scene** (sound manager GDevelop persist antar scene!)

---

## 🧪 FORMAT INSTRUKSI GDEVELOP TERVERIFIKASI (WAJIB BACA!)

Dari analisis source C++ GDevelop (4ian/GDevelop — repo path sekarang `Core/GDCore/...`) + contoh resmi (asteroids, camera, rts). **JANGAN pakai format lain** — sudah banyak bug tertangkap karena format salah:

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
| `GlobalVariable(nama)` / `GlobalVariableString(nama)` | ekspresi | — | baca global var (dipakai example resmi) |
| `Variable(nama)` | ekspresi | — | baca scene var |
| `AnimatableCapability::AnimatableBehavior::SetName` | act | `[obj, "Animation", "=", "\"nama\""]` | set animasi by name — behavior default AUTO-ATTACH (lihat catatan di bawah!) |
| `AddForceTowardPosition` | act | `[obj, X, Y, kecepatan, multiplier]` | multiplier 1 = gaya konstan |
| `AddForceTowardObject` | act | `[obj, objTarget, kecepatan, multiplier]` | 4 param, kejar objek |
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
| `Scene` | act | `["", "\"NamaScene\"", "true"]` | ganti scene (ganti layer sblm Scene utk stop audio) |
| `SceneBackground` | act | `["", "\"R;G;B\""]` | warna bg |
| `SetCameraCenterX` / `Y` | act | `["", "+/-", ekspresi, "\"\"", "\"\""]` | kamera (5 param — cocok camera.json resmi) |
| `PlaySound` | act | `["", file, loop, vol, pitch]` | **5 param** — file = nama resource bare (AudioExtension.cpp) |
| `PlaySoundOnChannel` | act | `["", file, channel, loop, vol, pitch]` | **6 param** — loop `yes`/`no` bare tanpa quote (contoh resmi asteroids) |
| `StopSoundChannel` | act | `["", channel]` | **2 param** |
| `MouseX("",0)` / `MouseY("",0)` | ekspresi | — | posisi kursor |
| `CameraCenterX("")` / `Y("")` | ekspresi | — | posisi kamera |

**TEMUAN KRITIS TERVERIFIKASI (Sesi 4, dari source C++):**
1. **Default capability behavior AUTO-ATTACH**: objek Sprite dengan `behaviors: []` tetap dapat behavior default saat project di-load. Rantai: `Project::CreateObject` → `EnsureObjectDefaultBehaviors` (SpriteExtension.cpp deklarasikan `.AddDefaultBehavior("AnimatableCapability::AnimatableBehavior")`) → `BehaviorsContainer::UnserializeFrom` hanya MENAMBAH dari JSON (tidak pernah menghapus default). Jadi `SetName` valid meski `behaviors: []`. Pola sama dengan contoh resmi rts.json (`EffectCapability::EffectBehavior::EnableEffect` → behavior short-name).
2. **Struktur sprite animation**: `animations → directions → sprites` (BUKAN `animations → frames`); field frame = `image` (BUKAN `texture`).
3. **Objek global (top-level `objects`)** valid — memungkinkan reuse cross-layout tanpa duplikasi.
4. **String di parameter double-escaped**: `\"teks\"`; tapi nilai loop/yes-no di audio = bare tanpa quote.
5. **Instance layout `b/r/v` = 255** (match contoh resmi).
6. **Sound manager persist antar scene** → musik loop harus di-StopSoundChannel manual di tiap transisi.

**Format JSON GDevelop:**
- Event standar: `{"type":"BuiltinCommonInstructions::Standard","conditions":[...],"actions":[...]}` + optional `"events":[...]` (sub-event)
- Item kondisi/aksi: `{"type":{"value":"Nama"},"parameters":[...]}`
- `behaviorsSharedData` per scene: Animation/Effect/Flippable/Opacity/Resizable/Scale/Text (capability types)
- gdVersion: `{"build":280,"major":5,"minor":6,"revision":0}` (match rts.json 5.0.280)
- properties: bentuk exact 5.0.280 dari rts.json (author, categories, currentPlatform, platforms, loadingScreen full, watermark, platformSpecificAssets 27 key, maxFPS 60, minFPS 20, verticalSync false)
- Repo GDevelop: path source sekarang `Core/GDCore/...` (contoh game.json resmi sudah dihapus dari repo; fixture emptyGame.json v4.0 tidak bisa jadi acuan — pakai rts.json dari versi lama yang masih kompatibel field-wise)

---

## ⚠️ HAL YANG TELAH DIPUTUSKAN (JANGAN DITANYA LAGI KE USER)

1. ✅ Engine = **GDevelop APK** (bukan Godot/Unity) — versi target 5.0.280
2. ✅ Target = **Mobile dulu**, PC belakangan
3. ✅ Penyimpanan = **Repo GitHub ini** (branch `main`, push via `x-access-token:$GITHUB_TOKEN`)
4. ✅ Semua asset harus **lengkap** (karakter, monster, tileset, audio, dll)
5. ✅ Gaya seni = **pixel art 32x32** tema "galaxy/outer space planet"
6. ✅ Bahasa dokumentasi = Indonesia; nama file/object = English
7. ✅ Membuat game via generator Python (tools/) — bukan edit manual game.json
8. ✅ Audio = **WAV** (bukan MP3) — ffmpeg tidak tersedia di sandbox, sintesis via stdlib Python
9. ✅ Workflow git = feature branch → commit → push → PR → merge ke `main`

---

## 📝 CATATAN SESI (LOG)

### Sesi 4 — FINAL SPRINT: v1.0 SELESAI END-TO-END
- **AUDIO**: `gen_audio.py` dibuat (sintesis WAV stdlib: wave+math+struct, mono 16-bit 22050Hz) → 4 file: menu.wav 423KB (arpeggio triangle A-minor pentatonic + bass sine 9.6s), ambient.wav 529KB (drone E2/B2 + wind noise 12s fade-loop), alert.wav (square 660→880Hz ×2 0.61s), build.wav (thud+hit+click 0.2s)
- **9 PATCH AUDIO di gd_scenes.py** (patch session lalu silent-fail karena search string pakai escaped `\"yes\"` padahal file bare `"yes"` — fix dengan exact-match): menu ch1 + ambient ch2 + NightOverlay Hide di Setup, alert ch3 di raid, build ch4 di build mode, StopSoundChannel ch1 di BtnStart/BtnQuit, ch2 di BtnRetry/_death_check/_win_check
- **scan_resources()** ditambah `.wav` → kind audio, preloadAsMusic true, preloadInCache true → 156 resource total
- **`build_game.py` DIBUAT & VALIDASI**: 8 check + negative test (bad image ref & ghost instance tertangkap — validator sempat 2x rusak: field `texture` seharusnya `image`, struktur `frames` seharusnya `directions→sprites`)
- **`project/game.json` FINAL: 2.938.505 bytes, VALIDATION OK** — 3 layouts, 59 objects, 156 resources, 214 events, instance 7/5878/4; audit 34 kombinasi instruction unik semuanya cocok engine source
- **VERIFIKASI ENGINE SOURCE (fetch dari GitHub raw)**: PlaySound 5 param / PlaySoundOnChannel 6 param / StopSoundChannel 2 param (AudioExtension.cpp); rantai default-behavior auto-attach (SpriteExtension.cpp → Project.cpp → Object.cpp → BehaviorsContainer.cpp → AnimatableBehavior.ts → spriteruntimeobject.ts); path repo GDevelop pindah ke `Core/GDCore/...`
- **Properties exact 5.0.280** dari rts.json (initial guess salah: ada `displayMode`/`logo3DScene` palsu, kurang `platformSpecificAssets` — fix total)
- **Instance b/r/v 0 → 255** (match contoh resmi)
- **Phase 4 docs**: README.md + docs/ASSETS_INDEX.md (156 asset + mapping objek↔image) + docs/ROADMAP.md (v1.1-v1.5)
- **Git delivery**: feature branch → push → PR → merge ke `main`
- **v1.0 DONE**: game bisa dibuka di GDevelop Android → Open Project → `project/game.json`

### Sesi 3 — Commit pertama + memory.md status
- **COMMIT `727a7c0` → PUSH ke `main` BERHASIL** (174 file: asset 152 PNG + tools + GDD + memory)
- gd_objects.py: +jobNode var, +attack/work anim kolonis, +7 objek tombol, NightOverlay → night-overlay.png, fix path scan_resources() → 59 objek tervalidasi
- Verifikasi format var global: `ModVarGlobal`/`GlobalVariable()` hidden tapi functional
- **TEMUAN KRITIS**: WinFlag/Day GameScene → GameOver tidak persist (scene var) → harus global var `G_Title`/`G_Stat`

### Sesi 2 — Perbaikan besar gd_scenes.py
- Rewrite penuh gd_scenes.py (sebelumnya broken line 366 + missing _assign_job)
- Fix: Distance (bukan DistanceBetweenTwoObjects, 4 param), VarObjetTxt/ModVarObjetTxt utk string var, AnimatableCapability::AnimatableBehavior::SetName (bukan SetAnimationName)

### Sesi 1 — Setup & asset
- Repo dikloning (kosong) → struktur folder dibuat
- memory.md, GDD dibuat
- Generate semua asset: karakter, monster, tile, building, item, UI, FX, menu
- Pipeline process_sprites.py: chroma-key magenta, slice frame, resize, quantize

---

## 🚀 NEXT STEPS (UNTUK SESI BERIKUTNYA — v1.1+)

Lihat `docs/ROADMAP.md` untuk detail. Prioritas v1.1 Base Building:
1. Build menu lengkap (12 bangunan — v1.0 hanya WallWood)
2. Blueprint system (kolonis membangun secara fisik)
3. Bed/FarmPlot/Campfire/Turret/Solar logic
4. Pinch-zoom kamera
5. Sound effect tambahan (harvest, hurt, death, win jingle)
6. Save/Load game (gunakan storage API GDevelop)
7. Pathfinding (ganti AddForce langsung)
