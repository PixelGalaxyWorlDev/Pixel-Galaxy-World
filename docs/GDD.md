# 📖 GAME DESIGN DOCUMENT — PIXEL GALAXY WORLD
> Versi 1.0 — Fondasi desain game. Detail teknis implementasi ada di `memory.md`.

---

## 1. OVERVIEW

**Pixel Galaxy World** adalah game **colony simulation** mobile yang terinspirasi RimWorld. Pemain memimpin tiga kolonis yang terdampar di planet asing dan harus membangun koloni agar bertahan hidup menghadapi kelaparan, monster alien, dan malam yang berbahaya.

**Pillar desain:**
1. **Sederhana untuk sentuhan** — semua aksi bisa dilakukan dengan tap & drag (tanpa klik kanan/keyboard).
2. **Kolonis punya kehidupan** — needs (lapar, ngantuk, mood) memberi rasa RimWorld.
3. **Siklus hari-malam** — malam berbahaya, monster muncul, listrik penting.
4. **Progres jelas** — dari tenda darurat → kota pixel bertembok.

---

## 2. GAMEPLAY LOOP (CORE LOOP)

```
Pilih Kolonis → Perintah (chop/mine/build/harvest) → Kolonis bekerja
     ↑                                              ↓
  Perbaiki mood & needs ← Acara (serangan, cuaca) ← Hasil: resource & bangunan
```

**Loop menit-ke-menit:** Pemain mengamati needs kolonis → mengarahkan pekerjaan → membangun → bertahan dari event. **Loop sesi-ke-sesi:** Buka tech baru → koloni berkembang → kolonis baru bergabung → ancaman lebih besar.

---

##  RimWorld Features yang Diadaptasi

| Fitur RimWorld | Adaptasi di PGW (versi mobile) |
|---|---|
| Pawns dengan needs & mood | 3 kolonis dengan hunger/sleep/mood bar |
| Mining, chopping, construction | Perintah kerja via tap terrain/bangunan |
| Raid musuh berkala | Gelombang monster tiap 2-3 hari game |
| Research/tech tree | Tech tree sederhana 3 cabang (15 tech) |
| Day/night cycle | Siklus siang-malam dengan pencahayaan overlay |
| Storan stockpile | Stockpile zone dengan kapasitas |
| Medical system | Sederhana: HP kolonis + first-aid kit |
| Taming animals | (Roadmap v2 — belum di v1) |

---

## 3. KONTROL MOBILE (TOUCH-FIRST)

| Aksi | Cara |
|---|---|
| Pilih kolonis | Tap potret di HUD bawah / tap karakter |
| Geser kamera | Drag 1 jari di area kosong |
| Zoom | Pinch 2 jari |
| Perintah kerja | Pilih kolonis → tap objek target (pohon/batu/bangunan plan) |
| Bangun | Tombol 🔨 di HUD → pilih menu → tap-tap-tap di tanah (paint plan) |
| Prioritas | Tap objek lagi untuk naik prioritas (1-4) |
| Pause/speed | Tombol ⏸ / ▶ / ▶▶ di pojok kanan atas |

---

## 4. SYSTEMS DESIGN

### 4.1 Needs Kolonis
- **Hunger** (turun ~cepat): di bawah 15% → kolonis berhenti kerja, cari makan sendiri.
- **Sleep** (turun saat kerja): di bawah 15% → pergi tidur otomatis ke bed.
- **Mood** (dipengaruhi kejadian): bangus bermimpi indah → mood naik; kelaparan/cedera/lalai → turun. Mood < 20% → risiko **mental break** (kolonis mogok 30 detik).

### 4.2 Ekonomi & Resource
| Resource | Sumber | Dipakai untuk |
|---|---|---|
| Kayu | Pohon | Dinding kayu, bed, meja |
| Batu | Rock node | Dinding batu, jalan |
| Logam | Ore logam + scavenge bangkai kapal | Tools, turret, solar panel |
| Kristal | Gua/vein kristal | Tech tinggi, lampu listrik |
| Makanan | Farm + beri liar + hasil buruan | Hunger kolonis |
| Energi | Solar panel / generator | Lampu, turret (malam hari) |

### 4.3 Day/Night & Bahaya Malam
- 1 hari game = **8 menit nyata** (siang 5 menit, malam 3 menit).
- Malam: overlay gelap + monster spawn probabilitas naik.
- Kolonis tanpa bed → mood turun cepat.

### 4.4 Combat
- Kolonis punya HP (max 100). Serangan monster → HP turun.
- Player bisa draft mode: pilih kolonis → tap monster → kolonis serang otomatis.
- Turret menembak otomatis musuh dalam radius.
- Kolonis HP < 25% → "downed" (tidak bisa kerja, perlu ditolong Luna).

### **Kanon per-pangkat (default):**
| Bintang | Trigger | Musuh |
|---|---|---|
| ★ | 2 pemain "downed" | 2-3 Slime Blob |
| ★★ | 3 kolonis downed / 50% hitungan waktu | + Rock Golem |
| ★★ + Void Stalker |
| ★★★ | Koloni kaya (wealth) | + lebih banyak Rock Golem |
| ★★★ | Sinergi: mutasi slime → dapat crystal (roadmap) |

### 4.5 Tech Tree (3 cabang, 15 tech)
- **Construction**: Firebreak → Wooden Wall → Stone Wall → Turret → Solar Panel
- **Agriculture**: Farm Plot → Beri Besar → Hydroponics → Mutasi Beri (v2)
- **Survival**: First Aid → Better Bed → Kitchen → Bow → Med-Bay (v2)

---

## 5. AUDIO & MUSIK (IDE DIRECTION)
- BGM siang: chiptune santai (lembut, pastoral).
- BGM malam: ambient rendah, tension tipis.
- SFX: chop, mine, build, eat, sleep snore, monster growl, alert raid.

---

## 32 GDD (sumber: design intent, bukan data final yang diimplementasi)
*Ini adalah panduan desain, angka bisa disesuaikan saat balancing.*

---

## 6. GDD targets

## 7. UI LAYOUT (LANDSCAPE MOBILE)

```
┌───────────────────────────────┐
│  ⏸ ▶ ▶▶        ☀ Hari 1  ⚡  │ ← Top bar (day counter, energi)
├──────────────────────────────┤
│                               │
│    AREA KAMERA / DUNIA        │
│    (drag pan, pinch zoom)     │
│                               │
├──────────────────────────────┤
│ [Rex][Luna][Bolt]  🪓⛏🏗  📦   │ ← Bottom bar (kolonis + tool menu)
└───────────────────────────────┘
```

---

## 8. DEFINITION OF DONE (v1.0 MOBILE)
- [ ] 3 kolonis selectable & punya needs berjalan
- [ ] Pohon/batu bisa dipanen → resource masuk stockpile
- [ ] Bangun dinding/bed/farm → berfungsi
- [ ] Day/night cycle + monster spawn malam
- [ ] Raid wave tiap 2-3 hari game (bisa dikalahkan)
- raid waves berhenti → survive/rebuild loop jelas
- [ ] Tech unlock berfungsi
- [ ] Win condition: bertahan **30 hari** game → layar kemenangan
- [ ] Pause/speed, save/load (auto-save tiap hari game)
- [ ] Crash-free di HP mid-range Android
- [ ] Bahasa ID default, EN toggle di menu
- [ ] Maksimal 60fps
```
- [ ] Definition of done tersimpan di GDD & konsisten dgn memory.md
```
