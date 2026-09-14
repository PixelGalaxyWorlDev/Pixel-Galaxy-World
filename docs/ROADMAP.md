# 🗺️ ROADMAP — Pixel Galaxy World

Status **v1.0 PLAYABLE**: scene utama Godot, controller gameplay, dan 156 aset — siap dibuka di Godot Android/Desktop.

---

## ✅ v1.0 — Core Survival Loop (SELESAI)

- Main menu → GameScene → GameOver (retry) — siklus penuh
- 3 kolonis (Rex/Luna/Bolt): HP, hunger, sleep, mood — auto-eat & settle-down
- Panen 5 node: Tree→Kayu, Rock→Batu, MetalOre→Logam, CrystalVein→Kristal, BerryBush→Makanan
- Bangun WallWood (tombol palu, 5 kayu)
- Siklus siang-malam (TimeOfDay + NightOverlay)
- 5 monster malam dengan AI chase + attack (Slime/Zapper/Golem/Stalker/Bat)
- Kolonis bisa disuruh serang monster (jobType attack)
- Raid timer ~5 menit + alarm sound
- Menang: bertahan sampai hari 30 • Kalah: semua kolonis tumbang
- Audio 4 channel (menu/ambient/alert/build) dengan stop di transisi scene
- HUD: hari, sumber daya, alert, kebutuhan 3 kolonis, pause/play/fast
- Kamera drag pan + edge case CamDrag
- Save global G_Title/G_Stat lintas scene

---

## 🚧 v1.1 — Base Building & Furnishing (prioritas tinggi)

Objek dan aset berikut menjadi target pengembangan Godot berikutnya:

- [ ] **Build menu lengkap**: Door, Bed, Table, Lamp, Stove, ResearchBench, FarmPlot, SolarPanel, Turret, WallStone — perlu biaya berbeda (mis. WallStone 8 batu)
- [ ] **Fungsi tempat tidur**: kolonis malam tidur di Bed → sleep naik cepat, mood naik
- [ ] **FarmPlot**: tanam makanan (makanan → tumbuh timer → panen 5 makanan)
- [ ] **Campfire**: hangat di malam → mood +, monster tidak spawn dekat (radius)
- [ ] **Turret**: otomatis tembak monster (Bullet object sudah ada — logic create + collision + dmg)
- [ ] **SolarPanel → energi**: resource ke-6, syarat lamp & stove aktif
- [ ] Ghost build preview (BuildGhost object sudah ada) menampilkan grid 32px

## 🎨 v1.2 — Biome & Ekspansi Dunia

77 aset cadangan siap pakai:

- [ ] Biome patch: sand (gurun), snow (tundra), swamp, rocky, spacerock, crystal-ground — masing-masing dengan spawn node khusus
- [ ] Water/water-edge: danau dengan tepian — blok gerakan (collision)
- [ ] Grass variasi: grass-flowers, grass-mushroom, dirt-pebbles, path-stone jalan setapak
- [ ] Unduhan item baru dari item-5..20: makanan matang, senjata, pakaian (crafting Stove)
- [ ] FX baru dari fx-4..24: heal, debu langkah, level-up, darah, partikel api

## ⚔️ v1.3 — Combat & Monster Depth

- [ ] HP bar kolonis & monster (bisa pakai fx atau ui sprite)
- [ ] Monster khusus biome (crystal biome → Crystal Golem varian warna)
- [ ] Mini-boss tiap 10 hari (golem-4/5 frame lebih besar + stat x3)
- [ ] Loot table monster: kristal drop chance
- [ ] Ripple attack Rex (attack anim sudah ada di karakter frame-5)

## 🏛️ v1.4 — Koloni Berkembang

- [ ] Rekrut kolonis baru (ItemDrop khusus survivor — spawn acak hari 10+)
- [ ] Job assignment permanen: prioritas otomatis (Bolt build > Luna farm > Rex guard)
- [ ] Research tree via ResearchBench (unlock Turret/SolarPanel/FarmPlot)
- [ ] Cuaca: hujan (tile water reuse), badai (monster malam lebih awal)

## 🎮 v1.5 — Polish & Meta

- [ ] Tutorial overlay hari 1 (panel ui-0 reuse)
- [ ] Achievement (bertahan 30 hari tanpa kehilangan kolonis, dsb)
- [ ] High-score day counter persist (localStorage GDevelop)
- [ ] Musik chiptune lebih panjang (menu.wav 2x bar dengan intro)
- [ ] PC release: keyboard shortcut + gamepad
- [ ] Ikon APK Android (logo-icon.png → `platformSpecificAssets/android-icon-*`)

---

## 🧪 Backlog Teknis (kapan saja)

- [ ] Pathfinding behavior untuk kolonis (sekarang pakai AddForceTowardPosition — cukup untuk map terbuka, tapi akan nabrak dinding: perlu Pathfinding obstacle di v1.1 build)
- [ ] Group objects (GDevelop objectsGroups) untuk "allColonists"/"allMonsters" — merapikan event picker
- [ ] Event-based behavior extension untuk AI kolonis (kode bisa dipisah reusable)
- [ ] Optimasi: jika grid tile lag di HP low-end, ubah ke TileMap atau satu tile besar per biome.

---

## 📈 Target Rilis

| Versi | Fokus | Estimasi |
|---|---|---|
| v1.0 | Core loop playable | ✅ **SELESAI** |
| v1.1 | Base building lengkap | 1 sesi pengembangan |
| v1.2 | Biome + dunia variatif | 1-2 sesi |
| v1.3 | Combat depth | 1 sesi |
| v1.4 | Meta koloni | 1-2 sesi |
| v1.5 | Polish + PC | 1 sesi |
