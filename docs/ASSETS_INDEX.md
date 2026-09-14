# 📦 ASSETS_INDEX — Katalog Aset Pixel Galaxy World

Katalog lengkap **156 aset** di `project/resources/` — dipakai game.json v1.0 maupun disiapkan untuk v1.1+.

> Dipakai di v1.0: **79 aset** (75 gambar + 4 audio) • Cadangan: **77 gambar** untuk v1.1+

---

## 🎵 audio/ — 4 file (sintetis, mono 22050 Hz WAV)

| File | Durasi | Dipakai di | Fungsi |
|---|---|---|---|
| `menu.wav` | 9.6s | MainMenu (channel 1, loop) | Musik menu — arpeggio pentatonik A minor (chiptune lembut) |
| `ambient.wav` | 12.0s | GameScene (channel 2, loop) | Drone ambient planet — E2/B2 drift + noise angin |
| `alert.wav` | 0.6s | Raid (channel 3, one-shot) | Alarm raid — dua nada naik square 660→880 Hz |
| `build.wav` | 0.2s | Bangun dinding (channel 4, one-shot) | Thunk konstruksi — sine 140 Hz + noise hit |

Di-generate oleh `tools/gen_audio.py` (stdlib Python — tanpa dependency). Regenerasi: `python3 tools/gen_audio.py`.

---

## 🧑 characters/ — 18 file (32×48 px)

Kolonis — 6 frame per karakter: `0-1` walk, `2-3` idle, `4` work, `5` attack.

| File | Dipakai objek | Animasi v1.0 |
|---|---|---|
| `rex-0..5.png` | Rex | walk (loop), idle (loop), work, attack |
| `luna-0..5.png` | Luna | walk, idle, work, attack |
| `bolt-0..5.png` | Bolt | walk, idle, work, attack |

Statistik canon (memory.md): Rex hp 130 / dmg 15 / speed 110 • Luna hp 100 / dmg 8 / speed 120 • Bolt hp 110 / dmg 10 / speed 100.

---

## 👾 monsters/ — 30 file (32×32 px)

Monster malam — 6 frame per monster: `0-2` walk, `3` idle, `4` attack, `5` hit/death.

| File | Dipakai objek | Stat v1.0 (hp/dmg/speed) |
|---|---|---|
| `slime-0..5.png` | Slime | 40 / 5 / 55 |
| `zapper-0..5.png` | Zapper | 30 / 8 / 130 |
| `golem-0..5.png` | Golem | 150 / 15 / 35 |
| `stalker-0..5.png` | Stalker | 55 / 12 / 95 |
| `bat-0..5.png` | Bat | 20 / 4 / 150 |

---

## 🏗️ buildings/ — 21 file (32×32 px)

| File | Dipakai objek | Status |
|---|---|---|
| `building-10.png` | **WallWood**, BuildGhost | ✅ v1.0 (bangun via tombol palu) |
| `building-0.png` | Campfire | ✅ v1.0 (instance) |
| `building-9.png` | CrashPod | ✅ v1.0 (instance, spawn point) |
| `building-1.png` | WallStone | ✅ objek ada |
| `building-12.png` | Door | ✅ objek ada |
| `building-13.png` | Bed | ✅ objek ada |
| `building-14.png` | Table | ✅ objek ada |
| `building-15.png` | Lamp | ✅ objek ada |
| `building-17.png` | Stove | ✅ objek ada |
| `building-18.png` | ResearchBench | ✅ objek ada |
| `building-20.png` | FarmPlot | ✅ objek ada |
| `building-3.png` | SolarPanel | ✅ objek ada |
| `building-5.png` | Turret | ✅ objek ada |
| `building-2,4,6,7,8,11,16,19.png` | — | 🔒 cadangan v1.1 (varian bangunan) |

> Objek bangunan (Door/Bed/Stove/dst) sudah terdefinisi di game.json namun belum semua dipakai event build — lihat `docs/ROADMAP.md`.

---

## 🌲 items/ — 21 file (32×32 px)

| File | Dipakai objek | Status |
|---|---|---|
| `item-0.png` | **Tree** | ✅ v1.0 panen → +4 Kayu |
| `item-1.png` | **Rock** | ✅ v1.0 panen → +3 Batu |
| `item-2.png` | **MetalOre** | ✅ v1.0 panen → +2 Logam |
| `item-3.png` | **CrystalVein** | ✅ v1.0 panen → +1 Kristal |
| `item-4.png` | **BerryBush** | ✅ v1.0 panen → +3 Makanan |
| `item-9.png` | **ItemDrop** | ✅ v1.0 (drop saat monster mati) |
| `item-5..8, 10..20.png` | — | 🔒 cadangan v1.1 (makanan matang, pakaian, senjata, dll) |

---

## ✨ effects/ — 25 file (32×32 px)

| File | Dipakai objek | Status |
|---|---|---|
| `fx-0.png` | FXHit | ✅ v1.0 (hit flash) |
| `fx-1.png` | FXHit, FXExplosion | ✅ v1.0 |
| `fx-2,3.png` | FXExplosion | ✅ v1.0 (ledakan monster mati) |
| `fx-6.png` | **Bullet** | ✅ v1.0 (proyektil turret & turret raid) |
| `fx-4,5,7..24.png` | — | 🔒 cadangan v1.1 (efek partikel, darah, debu, heal, level-up...) |

---

## 🗺️ tiles/ — 17 file (32×32 px)

| File | Dipakai objek | Status |
|---|---|---|
| `grass.png` | **TileGrass** | ✅ v1.0 (puluhan instance) |
| `dirt.png` | **TileDirt** | ✅ v1.0 |
| `night-overlay.png` | **NightOverlay** | ✅ v1.0 (overlay malam, RGBA semi-transparan) |
| `ash, sand, snow, swamp, rocky, spacerock, crystal-ground, dirt-pebbles, path-stone, grass-flowers, grass-mushroom, grass-dirt-edge, water, water-edge.png` | — | 🔒 cadangan v1.1 (biome: gurun/tundra/rawa/kristal/laut — biome patch sudah di ROADMAP) |

---

## 🖱️ ui/ — 17 file (96×N px)

| File | Dipakai objek | Status |
|---|---|---|
| `ui-0.png` | BtnStart, BtnQuit, BtnRetry, UIPanel | ✅ v1.0 (panel rounded 96×46) |
| `ui-1.png` | UIButton | ✅ v1.0 |
| `ui-2.png` | UIPortrait | ✅ v1.0 (3 portrait HUD bawah) |
| `ui-5.png` | **BtnFast** | ✅ v1.0 (fast-forward 96×90) |
| `ui-6.png` | **BtnPause** | ✅ v1.0 (pause 96×89) |
| `ui-7.png` | **BtnPlay** | ✅ v1.0 (play 96×89) |
| `ui-14.png` | UIIcon | ✅ v1.0 |
| `ui-15.png` | **BtnBuild** | ✅ v1.0 (palu 96×93) |
| `ui-3,4,8..13,16.png` | — | 🔒 cadangan v1.1 (ikon menu, slider, checkbox, tab...) |

---

## 🏞️ menu/ — 3 file

| File | Dipakai objek | Status |
|---|---|---|
| `menu-background.png` | **MenuBackground** | ✅ v1.0 (background menu 909×513) |
| `title-art.png` | **TitleArt** | ✅ v1.0 (judul pixel art) |
| `logo-icon.png` | — | 🔒 cadangan (ikon game/APK — kandidat `platformSpecificAssets` Android) |

---

## 📊 Ringkasan

| Folder | Jumlah | Dipakai v1.0 | Cadangan v1.1 |
|---|---|---|---|
| audio | 4 | 4 | 0 |
| characters | 18 | 18 | 0 |
| monsters | 30 | 30 | 0 |
| buildings | 21 | 13 | 8 |
| items | 21 | 6 | 15 |
| effects | 25 | 5 | 20 |
| tiles | 17 | 3 | 14 |
| ui | 17 | 9 | 8 |
| menu | 3 | 2 | 1 |
| **TOTAL** | **156** | **79** | **77** |

Semua sprite pixel art dengan **alpha transparan bersih** (sudut magenta = transparan alpha-0, bukan border). Ukuran frame konsisten: karakter 32×48, lainnya 32×32, UI 96×N.
