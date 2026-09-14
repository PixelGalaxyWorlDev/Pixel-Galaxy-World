# Pixel Galaxy World 🌌

**Mobile colony-sim pixel art terinspirasi RimWorld — dibangun 100% dengan [GDevelop 5](https://gdevelop.io).**

Kolonisasi planet asing bersama tiga kolonis (Rex, Luna, Bolt). Panen sumber daya, bangun shelter, bertahan dari monster malam, dan **selamat sampai hari ke-30**.

![Genre](https://img.shields.io/badge/genre-colony--sim%20%2F%20survival-blue) ![Engine](https://img.shields.io/badge/engine-GDevelop%205-orange) ![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-green) ![Status](https://img.shields.io/badge/status-v1.0%20playable-brightgreen)

---

## 🎮 Gameplay (v1.0)

| Mekanik | Detail |
|---|---|
| **Tujuan** | Bertahan **30 hari** — atau selamatkan seluruh koloni sampai hari 30 tanpa ada yang tumbang |
| **Kolonis** | Rex (petarung), Luna (panen cepat), Bolt (pembangun) — masing-masing punya HP, rasa lapar, kantuk, mood |
| **Sumber daya** | Kayu (pohon), Batu (batu), Logam (bijih), Kristal (vena kristal), Makanan (semak beri) |
| **Siklus harian** | Siang (panen/bangun) → Malam (monster spawn: Slime, Zapper, Golem, Stalker, Bat) |
| **Bangunan** | Dinding kayu (bangun via tombol palu, 5 kayu) — v1.0 |
| **Raid** | Setiap ~5 menit: raid besar dengan spawn gelombang monster + alarm |
| **Kontrol** | Touch/drag: tap objek untuk perintah, drag untuk pan kamera, tombol pause/play/fast |

**Kalah** jika ketiga kolonis tumbang (hp ≤ 0). **Menang** jika bertahan sampai hari 30.

---

## 📱 Cara Buka di GDevelop (Android APK)

### Opsi A — Aplikasi GDevelop di Android (paling mudah)
1. Install **[GDevelop app dari Google Play](https://play.google.com/store/apps/details?id=io.gdevelop.gdevelop)** (atau unduh APK dari [gdevelop.io/download](https://gdevelop.io/download))
2. Clone repo ini atau unduh ZIP:
   ```
   git clone https://github.com/KenopsiaHUB-101/Pixel-Galaxy-World.git
   ```
   (Atau dari GitHub app: **Code → Download ZIP**, lalu ekstrak)
3. Buka GDevelop → **Open Project** → pilih folder `Pixel-Galaxy-World/project` → pilih `game.json`
4. Preview langsung di layar Android — atau **Package → Android** untuk build APK resmi via GDevelop build service (perlu akun GDevelop)

### Opsi B — Desktop / Web
1. Buka [gdevelop.io](https://gdevelop.io) (web app) atau GDevelop Desktop
2. **Open Project** → `Pixel-Galaxy-World/project/game.json`
3. Preview (F5) / Publish — game sudah mobile-landscape (909×513) touch-ready

> 💡 **Format project**: `project/game.json` + `project/resources/` — format standar GDevelop 5 (gdVersion 5.0.280). Objek global (top-level) sehingga dipakai lintas scene.

---

## 🕹️ Kontrol (Mobile)

| Aksi | Cara |
|---|---|
| Pilih kolonis / perintah kerja | Tap kolonis → tap pohon/batu/bijih/semak/monster |
| Pan kamera | Drag di area kosong |
| Bangun dinding | Tap tombol **palu** (kanan bawah) → tap area (biaya 5 kayu) |
| Kecepatan | Pause ▮▮ / Play ▶ / Fast ▶▶ (kanan atas) |
| Serang monster | Tap monster saat kolonis terpilih |

---

## 📁 Struktur Repo

```
Pixel-Galaxy-World/
├── project/                  # ← BUKA INI di GDevelop
│   ├── game.json             # Project GDevelop utama (3 scene, 59 objek, 214 events)
│   └── resources/            # 156 asset (152 sprite PNG + 4 audio WAV)
│       ├── characters/       # rex/luna/bolt + monster (slime/zapper/golem/stalker/bat)
│       ├── tiles/            # tileset ground + night-overlay
│       ├── buildings/        # wall, door, bed, campfire, solar, turret...
│       ├── resources/        # pohon, batu, bijih, kristal, semak
│       ├── ui/               # panel, tombol, ikon, portrait
│       ├── fx/               # explosion, hit, item drop
│       └── audio/            # menu/ambient/alert/build (.wav)
├── tools/                    # Generator Python (rebuild game.json)
│   ├── gd_lib.py             # Helper JSON GDevelop
│   ├── gd_objects.py         # 59 definisi objek
│   ├── gd_scenes.py          # 3 scene + 214 events (logic game)
│   ├── gen_audio.py          # Generator 4 audio WAV sintetis
│   └── build_game.py         # Assembler + validator game.json
├── docs/
│   ├── ASSETS_INDEX.md       # Katalog semua 156 asset
│   └── ROADMAP.md            # Rencana v1.1+
├── memory.md                 # Log pengembangan lengkap (canon game)
└── README.md
```

---

## 🔧 Rebuild / Modifikasi via Tools

Project dibangun oleh generator Python — jika ingin mengubah logic secara programatik:

```bash
cd tools
python3 build_game.py     # rebuild + auto-validate project/game.json
python3 gen_audio.py      # regenerate 4 audio WAV (opsional)
```

Validator memastikan: JSON valid, semua instance ↔ objek ada, semua resource ↔ file ada, semua sprite ↔ resource terdaftar, param PlaySound/StopSoundChannel benar.

---

## 🧠 Lore Singkat

Kapal koloni **Nusantara-7** jatuh di planet **Kepler-Pixel**. CrashPod berisi tiga kolonis terakhir: **Rex** sang veteran, **Luna** sang ahli botani, **Bolt** sang insinyur. Setiap malam monster planet mendekat — bertahanlah, bangunlah, dan buat kolonimu bertumbuh.

---

## 📜 Lisensi & Kredit

- **Kode & logic**: MIT License
- **Aset pixel art**: dibuat khusus untuk project ini (lihat `docs/ASSETS_INDEX.md`)
- **Audio**: disintesis programatik (chiptune pentatonik + drone ambient)
- Dibuat oleh **PixelGalaxyWorlDev** dengan bantuan **Github CopilotAgent** 

**Repo**: https://github.com/PixelGalaxyWorlDev/Pixel-Galaxy-World
