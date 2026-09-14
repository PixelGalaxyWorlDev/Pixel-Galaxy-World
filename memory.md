# 🧠 MEMORY.md — PIXEL GALAXY WORLD
> **Dokumen Memori Proyek** — Baca file ini dulu sebelum melanjutkan pengembangan!
> Terakhir diperbarui: 2025 (Phase 1 — Setup & Fondasi)

---

## 📌 IDENTITAS PROYEK

| Item | Detail |
|------|--------|
| **Nama Game** | Pixel Galaxy World |
| **Genre** | Colony Simulation / Survival (inspirasi RimWorld) |
| **Inspirasi** | RimWorld (PC, oleh Ludeon Studios) — *hanya inspirasi, bukan tiruan* |
| **Engine** | GDevelop (APK / Android mobile app) |
| **Platform Target** | 📱 Mobile (Android) dulu → 💻 PC (desktop) nanti |
| **Bahasa UI** | Indonesia + English (bilingual, ID sebagai default) |
| **Repo GitHub** | `KenopsiaHUB-101/Pixel-Galaxy-World` (branch: `main`) |
| **Pemilik** | KenopsiaHUB-101 |

---

## 🎮 KONSEP GAME (SATU PARAGRAF)

**Pixel Galaxy World** adalah game simulasi koloni pixel-art di planet asing. Pemain memimpin 3 kolonis yang terdampar di planet **Kepler-Pixel 7** setelah kapal mereka jatuh. Pemain harus membangun rumah, mencari makanan, bertahan dari serangan monster alien, dan menjaga mood kolonis agar koloni bertahan hidup. Setiap kolonis punya needs (hunger, sleep, mood) seperti RimWorld, dan game berjalan dengan kontrol sentuh (touch) untuk mobile.

---

## 🗺️ STRUKTUR REPO (JANGAN DIUBAH SEMBARANGAN)

```
Pixel-Galaxy-World/
├── memory.md               ← FILE INI — sumber kebenaran proyek
├── README.md               ← Cara buka proyek di GDevelop APK
├── docs/
│   ├── GDD.md              ← Game Design Document lengkap
│   ├── ASSETS_INDEX.md     ← Katalog semua asset (nama, fungsi, ukuran)
│   └── ROADMAP.md          ← Roadmap pengembangan & progres
├── project/
│   ├── game.json           ← File proyek GDevelop (buka ini di GDevelop!)
│   ├── *.json              ← File definisi scene & object GDevelop
│   └── resources/          ← Asset yang dipakai game (folder ini yang GDevelop baca)
│       ├── characters/     ← Sprite kolonis (idle, walk, aksi)
│       ├── monsters/       ← Sprite monster alien
│       ├── tiles/          ← Tileset terrain (32x32 px per tile)
│       ├── buildings/      ← Sprite bangunan & furnitur
│       ├── items/          ← Sprite item/resource
│       ├── ui/             ← Panel, tombol, ikon HUD
│       ├── effects/        ← Efek visual (ledakan, darah, dll)
│       └── menu/           ← Title art, background menu
└── assets-source/          ← Sumber asset resolusi tinggi (cadangan)
```

**ATURAN PENTING:**
- GDevelop APK membaca folder `project/resources/` → semua nama file harus **huruf kecil, tanpa spasi** (pakai `-` atau `_`).
- Ukuran tile = **32x32 px**, skala sprite karakter = **32x48 px** (2 tile tinggi).
- Jangan pernah menghapus file di `assets-source/` — itu cadangan master.

---

## 🧑‍🚀 KARAKTER & ENTITAS (KANON GAME)

### Kolonis (pemain memimpin)
| Kolonis | Peran | Ciri | Warna Tema |
|---------|-------|------|-----------|
| **Rex** | Builder/Miner | Rambut pirang, kuat | Oranye |
| **Luna** | Farmer/Doctor | Rambut pink, pintar | Hijau |
| **Bolt** | Chef/Hunter | Botak + bandana, cepat | Biru |

### Monster Alien (musuh)
| Monster | Kekuatan | Perilaku |
|---------|----------|----------|
| **Slime Blob** | Lemah | Melompat lambat, serang jarak dekat |
| **Zapper Bug** | Sedang | Serang cepat dengan listrik |
| **Rock Golem** | Kuat | Lambat, HP besar, penjaga sumber daya |
| **Void Stalker** | Sangat kuat | Muncul saat malam/invasi |
| **Crystal Bat** | Sedang | Terbang, muncul di gua kristal |

### Sumber Daya (Resources)
`kayu (wood)` · `batu (stone)` · `logam (metal)` · `kristal (crystal)` · `makanan (food)` · `energi (energy)`

---

## 🏗️ STATUS PENGERJAAN (UPDATE TIAP SESI!)

| Phase | Status | Keterangan |
|-------|--------|-----------|
| Phase 1 — Setup & memory.md | ✅ SELESAI | Repo siap, struktur dibuat |
| Phase 2 — Asset production | 🔄 BERJALAN | Sprite sedang digenerate |
| Phase 3 — GDevelop project | ⬜ BELUM | Menunggu asset selesai |
| Phase 4 — Docs & GitHub PR | ⬜ BELUM | Menunggu Phase 3 |

---

## 🔧 SPESIFIKASI TEKNIS (KUNCI GDEVELOP)

- **Orientation:** Landscape (909x513 base resolution → skala otomatis)
- **Renderer:** WebGL via PixJS (default GDevelop)
- **Kontrol:** Touch — tap untuk pilih, drag untuk pan kamera, pinch untuk zoom
- **FPS target:** 60fps di HP mid-range, 30fps minimum
- **Ukuran file:** Total resources harus < 30MB agar performa mobile baik
- **Scene list:** `MainMenu` → `GameScene` → (nanti: `GameOver`, `Tutorial`)
- **Objects utama:** `PlayerChar` (kolonis), `Monster`, `Tile`, `Building`, `ItemDrop`, `UI_Button`, `HUD_Panel`

---

## ⚠️ HAL YANG TELAH DIPUTUSKAN (JANGAN DITANYA LAGI KE USER)

1. ✅ Engine = **GDevelop APK** (bukan Godot/Unity)
2. ✅ Target = **Mobile dulu**, PC belakangan
3. ✅ Penyimpanan = **Repo GitHub ini** (branch `main` via PR dari branch feature)
4. ✅ Semua asset harus **lengkap** (karakter, monster, tileset, dll)
5. ✅ Gaya seni = **pixel art 32x32** dengan tema "galaxy/outer space planet"
6. ✅ Bahasa dokumentasi = Indonesia; nama file/object = English

---

## 📝 CATATAN SESI (LOG)

### Sesi 1 — [Auto: Setup]
- Repo dikloning (kosong) → struktur folder dibuat
- memory.md, GDD, README, ROADMAP, ASSETS_INDEX dibuat
- Mulai generate asset: karakter, monster, tile, building, item, UI
- Target commit: `feat: initial project setup & full asset pack`
