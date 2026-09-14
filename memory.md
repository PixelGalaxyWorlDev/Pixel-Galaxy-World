# Pixel Galaxy World - Catatan Proyek

## Runtime

- Engine: Godot 4, target Android dan desktop.
- Project file: `project.godot` di root.
- Scene utama: `main.tscn`.
- Logic gameplay: `scripts/main.gd`.
- Renderer: GL Compatibility.
- Resolusi dasar: 909x513 landscape.

## Gameplay v1.0

- Tiga kolonis: Rex, Luna, dan Bolt.
- Resource: kayu, batu, logam, kristal, dan makanan.
- Kolonis dapat dipilih, memanen resource, menyerang monster, dan membangun dinding kayu.
- Monster malam: slime, zapper, golem, stalker, dan bat.
- Sistem hari-malam, kebutuhan hunger/sleep/mood, raid, pause, speed, kamera drag, menang hari 30, dan game-over.

## Aset

- Semua aset runtime berada di `project/resources/`.
- Folder `characters`, `monsters`, `tiles`, `buildings`, `items`, `effects`, `ui`, `menu`, dan `audio` dipakai langsung oleh `scripts/main.gd`.
- Sheet sumber dan pipeline generator lama sudah dihapus karena tidak diperlukan runtime.

## Aturan pengembangan

- Buka folder root repo di Godot, bukan folder `project/`.
- Jalankan `main.tscn` untuk preview.
- Jangan menghapus resource yang direferensikan `scripts/main.gd`.
- Untuk Android, gunakan Godot Android Editor atau preset Export Android dari Godot 4.