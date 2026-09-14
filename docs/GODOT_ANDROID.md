# Godot Android

## Membuka project

1. Install Godot 4 atau Godot Android Editor.
2. Clone atau ekstrak repository ini.
3. Pilih folder repository sebagai project. Jangan memilih `project/`; folder itu adalah resource legacy dari GDevelop.
4. Jalankan `main.tscn` atau tekan Play Project.

Project memakai renderer `gl_compatibility`, resolusi landscape 909x513, dan aset dari `project/resources/`. Godot akan mengimpor PNG dan WAV saat project pertama kali dibuka.

## Kontrol

- Tap kolonis untuk memilihnya.
- Tap pohon, batu, bijih, kristal, atau semak untuk memberi perintah panen.
- Tap monster untuk memberi perintah serang.
- Drag area dunia untuk menggeser kamera.
- Tombol `PALU`, lalu tap dunia untuk membangun dinding kayu seharga 5 kayu.
- Tombol `>>`, `>`, dan `||` mengatur kecepatan atau pause.

## Export APK

1. Buka menu Project > Export.
2. Tambahkan preset Android.
3. Isi package name dan keystore sesuai kebutuhan distribusi.
4. Export project menjadi APK atau AAB.

Godot Android Editor dapat menjalankan dan mengekspor project langsung dari perangkat Android jika template export Android tersedia pada versi yang dipakai.

## Struktur runtime

Godot hanya membutuhkan `project.godot`, `main.tscn`, `scripts/main.gd`, dan aset di `project/resources/`. Tidak ada generator atau project eksternal yang perlu dijalankan sebelum membuka game.