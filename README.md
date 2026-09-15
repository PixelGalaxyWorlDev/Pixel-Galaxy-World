# Pixel Galaxy World

**Mobile colony-sim pixel art untuk Godot 4 Android.**

Kolonisasi planet asing bersama tiga kolonis (Rex, Luna, Bolt). Panen sumber daya, bangun shelter, bertahan dari monster malam, dan selamat sampai hari ke-30.

![Genre](https://img.shields.io/badge/genre-colony--sim%20%2F%20survival-blue) ![Engine](https://img.shields.io/badge/engine-Godot%204-orange) ![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Desktop-green) ![Status](https://img.shields.io/badge/status-v1.0%20playable-brightgreen)

> Jalur utama proyek adalah Godot di root repo. Folder `project/resources/` berisi aset runtime.

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

## Cara Buka di Godot Android

1. Install Godot 4 dari sumber resmi atau Godot Android Editor.
2. Clone repo ini atau unduh ZIP:
   ```
   git clone https://github.com/PixelGalaxyWorlDev/Pixel-Galaxy-World.git
   ```
3. Buka folder repo ini sebagai project Godot. File project-nya adalah `project.godot` di root.
4. Jalankan scene utama `main.tscn`. Kontrol mouse dan touch memakai input yang sama.
5. Untuk APK, gunakan menu Export pada Godot Android Editor dan pilih preset Android.

Detail setup Android ada di [docs/GODOT_ANDROID.md](docs/GODOT_ANDROID.md).

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

## Struktur Repo

```
Pixel-Galaxy-World/
├── project.godot             # Project Godot 4
├── main.tscn                 # Scene utama
├── scripts/main.gd           # Controller gameplay Godot
├── project/resources/        # 156 asset (152 sprite PNG + 4 audio WAV)
│   ├── characters/           # rex/luna/bolt + monster
│   ├── tiles/                # ground + night overlay
│   ├── buildings/            # bangunan
│   ├── items/                # resource node
│   ├── ui/                   # sprite UI
│   ├── effects/              # efek
│   ├── menu/                 # art menu
│   └── audio/                # menu/ambient/alert/build
├── project/resources/        # aset runtime Godot (152 PNG + 4 WAV)
├── docs/
│   ├── GODOT_ANDROID.md      # instruksi Android
│   ├── GDD.md                # desain game
│   ├── ASSETS_INDEX.md       # katalog aset
│   └── ROADMAP.md            # rencana pengembangan
└── project/resources/        # aset runtime Godot
```

---

## Modifikasi aset

Aset runtime berada di `project/resources/` dan direferensikan langsung oleh `scripts/main.gd`. Logic runtime Godot ada di `scripts/main.gd`; tidak ada generator project tambahan yang diperlukan.

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
