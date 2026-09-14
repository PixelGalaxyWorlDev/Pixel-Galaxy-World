#!/usr/bin/env python3
"""
Pixel Galaxy World — Sprite Processing Pipeline v2
Strategi:
- Karakter & monster: deteksi baris via gutter, lalu per-baris bagi merata sesuai jumlah frame ekspektasi
- Tileset: grid 4x4 merata, full cell (TANPA autocrop), resize 32x32
- Koleksi (buildings/items/ui/effects): connected-component labeling
- Semua: chroma-key magenta, quantize palet pixel-art
"""
import os
from PIL import Image
import numpy as np

try:
    from scipy import ndimage
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

SRC = "assets-source"
DST = "project/resources"

# ---------------- util dasar ----------------
def remove_magenta(img: Image.Image) -> Image.Image:
    arr = np.array(img.convert("RGBA"))
    r, g, b, a = arr[..., 0].astype(int), arr[..., 1].astype(int), arr[..., 2].astype(int), arr[..., 3].astype(int)
    magenta_mask = (r > 140) & (b > 140) & (g < 110)
    halo_mask = (r > 170) & (b > 170) & (g >= 110) & (g < 170) & (np.abs(r - b) < 60)
    mask = magenta_mask | halo_mask
    arr[..., 3] = np.where(mask, 0, a).astype(np.uint8)
    return Image.fromarray(arr)

def autocrop(img: Image.Image, thresh=8) -> Image.Image:
    arr = np.array(img)
    if arr[..., 3].max() <= thresh:
        return img
    rows = np.any(arr[..., 3] > thresh, axis=1)
    cols = np.any(arr[..., 3] > thresh, axis=0)
    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]
    return img.crop((cmin, rmin, cmax + 1, rmax + 1))

def quantize(img: Image.Image) -> Image.Image:
    arr = np.array(img.convert("RGBA"))
    q = 255 / 4
    for c in range(3):
        arr[..., c] = (np.round(arr[..., c] / q) * q).astype(np.uint8)
    arr[..., 3] = np.where(arr[..., 3] > 128, 255, 0).astype(np.uint8)
    return Image.fromarray(arr)

def coverage(img: Image.Image) -> float:
    arr = np.array(img)
    if arr.size == 0:
        return 0.0
    return float((arr[..., 3] > 8).mean())

def content_bbox(img: Image.Image):
    arr = np.array(img)
    rows = np.any(arr[..., 3] > 8, axis=1)
    cols = np.any(arr[..., 3] > 8, axis=0)
    if not rows.any():
        return None
    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]
    return (cmin, rmin, cmax + 1, rmax + 1)

def row_bounds(img: Image.Image):
    """Deteksi baris sprite via baris kosong (gutter horizontal)."""
    arr = np.array(img)
    empty_rows = ~np.any(arr[..., 3] > 8, axis=1)
    segs, start = [], None
    for i, e in enumerate(empty_rows):
        if not e and start is None:
            start = i
        elif e and start is not None:
            segs.append((start, i)); start = None
    if start is not None:
        segs.append((start, len(empty_rows)))
    # gabung segmen tipis (noise < 6% tinggi gambar)
    min_h = img.height * 0.06
    merged = []
    for s in segs:
        if merged and (s[1] - s[0] < min_h or s[0] - merged[-1][1] < min_h):
            merged[-1] = (merged[-1][0], s[1])
        else:
            merged.append(s)
    return merged

def slice_row(img: Image.Image, r0, r1, n_frames, gutter_first=True):
    """Ambil satu baris, potong jadi n frame. Coba gutter dulu, fallback bagi merata."""
    row = img.crop((0, r0, img.width, r1))
    bbox = content_bbox(row)
    if bbox is None:
        return []
    row = row.crop(bbox)
    arr = np.array(row)
    empty_cols = ~np.any(arr[..., 3] > 8, axis=0)
    segs, start = [], None
    for i, e in enumerate(empty_cols):
        if not e and start is None:
            start = i
        elif e and start is not None:
            segs.append((start, i)); start = None
    if start is not None:
        segs.append((start, len(empty_cols)))
    min_w = row.width * 0.04
    merged = []
    for s in segs:
        if merged and (s[1] - s[0] < min_w or s[0] - merged[-1][1] < min_w):
            merged[-1] = (merged[-1][0], s[1])
        else:
            merged.append(s)
    if gutter_first and len(merged) == n_frames:
        cells = [row.crop((c0, 0, c1, row.height)) for c0, c1 in merged]
    else:
        # bagi merata n kolom
        w = row.width / n_frames
        cells = [row.crop((int(i * w), 0, int((i + 1) * w), row.height)) for i in range(n_frames)]
    return cells

def normalize_size(img: Image.Image, max_wh: int) -> Image.Image:
    if img.width > max_wh or img.height > max_wh:
        scale = max_wh / max(img.width, img.height)
        img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.NEAREST)
    return img

# ---------------- 1) karakter & monster ----------------
def process_anim_sheet(src_path, out_dir, prefix, rows_layout, max_wh):
    """rows_layout: list jumlah frame per baris, mis. [4, 2]."""
    img = remove_magenta(Image.open(src_path))
    rows = row_bounds(img)
    if len(rows) != len(rows_layout):
        print(f"  ⚠ {prefix}: baris terdeteksi {len(rows)}, ekspektasi {len(rows_layout)} — pakai bagi merata")
        # fallback: bagi tinggi gambar merata sesuai layout proporsional
        total = sum(rows_layout)
        bounds = []
        y = 0
        for n in rows_layout:
            h = img.height * n / total
            bounds.append((int(y), int(y + h)))
            y += h
        rows = bounds
    n = 0
    saved = []
    for (r0, r1), nframes in zip(rows, rows_layout):
        cells = slice_row(img, r0, r1, nframes)
        for cell in cells:
            cell = autocrop(cell)
            if coverage(cell) < 0.02:
                continue  # buang sel kosong
            cell = quantize(cell)
            cell = normalize_size(cell, max_wh)
            cell.save(f"{out_dir}/{prefix}-{n}.png")
            saved.append((n, cell.size))
            n += 1
    print(f"  ✓ {prefix}: {n} frame → {out_dir}/{prefix}-*.png  {saved}")
    return n

# ---------------- 2) tileset ----------------
def process_tileset(src_path, out_dir, grid=4, tile_size=32, names=None):
    img = remove_magenta(Image.open(src_path))
    bbox = content_bbox(img)
    img = img.crop(bbox) if bbox else img
    w, h = img.width // grid, img.height // grid
    n = 0
    for r in range(grid):
        for c in range(grid):
            cell = img.crop((c * w, r * h, (c + 1) * w, (r + 1) * h))
            # tile HARUS full-bleed square — isi magenta sisa jadi warna dasar tile
            arr = np.array(cell)
            mag = (arr[..., 0] > 140) & (arr[..., 2] > 140) & (arr[..., 1] < 110)
            if mag.any():
                # ganti magenta dengan pixel warna mayoritas non-magenta
                good = arr[~mag]
                if len(good) > 0:
                    fill = tuple(np.median(good[:, :3], axis=0).astype(int))
                    arr[mag] = [*fill, 255]
                    cell = Image.fromarray(arr)
            cell = cell.resize((tile_size, tile_size), Image.NEAREST)
            cell = quantize(cell)
            name = names[n] if names and n < len(names) else f"tile-{n}"
            cell.save(f"{out_dir}/{name}.png")
            n += 1
    print(f"  ✓ tileset: {n} tile → {out_dir}")

# ---------------- 3) koleksi via connected components ----------------
def process_collection(src_path, out_dir, prefix, max_wh=64, min_area=400, dilate=0):
    img = remove_magenta(Image.open(src_path))
    arr = np.array(img)
    alpha = (arr[..., 3] > 8).astype(np.uint8)
    if HAS_SCIPY:
        if dilate > 0:
            # dilasi: gabungkan partikel berdekatan jadi satu sprite (mis. ledakan + percikan)
            struct = np.ones((dilate * 2 + 1, dilate * 2 + 1), dtype=np.uint8)
            alpha_d = ndimage.binary_dilation(alpha.astype(bool), structure=struct, iterations=1).astype(np.uint8)
        else:
            alpha_d = alpha
        labels, nlab = ndimage.label(alpha_d)
        print(f"  {prefix}: {nlab} komponen terdeteksi" + (f" (dilasi {dilate}px)" if dilate else ""))
        comps = []
        for lb in range(1, nlab + 1):
            ys, xs = np.where(labels == lb)
            if len(ys) < min_area:
                continue
            c0, c1, r0, r1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            comps.append((r0, c0, r1, c1))
    else:
        # fallback: grid gutter sederhana (scan kolom & baris kosong)
        comps = []
        rows = row_bounds(img)
        for r0, r1 in rows:
            cells = slice_row(img, r0, r1, 6, gutter_first=True)
            for cell in cells:
                b = content_bbox(cell)
                if b is None: continue
                comps.append((r0 + b[1], b[0], r0 + b[3], b[2]))
    # urutkan top-to-bottom, lalu left-to-right (baris toleransi 15% tinggi)
    comps.sort(key=lambda c: (c[0] // max(1, (c[3] - c[0]) // 2), c[1]))
    n = 0
    for (r0, c0, r1, c1) in comps:
        spr = img.crop((c0, r0, c1, r1))
        spr = quantize(spr)
        spr = normalize_size(spr, max_wh)
        spr.save(f"{out_dir}/{prefix}-{n}.png")
        n += 1
    print(f"  ✓ {prefix}: {n} sprite → {out_dir}/{prefix}-*.png")
    return n

# ---------------- 4) contact sheet untuk verifikasi visual ----------------
def make_contact_sheet(folder, prefix, out_name, cols=8):
    files = sorted([f for f in os.listdir(folder) if f.startswith(prefix) and f.endswith(".png")],
                   key=lambda f: int(f.split("-")[-1].split(".")[0]))
    if not files:
        return
    cell = 72
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell + 20), (40, 40, 60, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(files):
        img = Image.open(f"{folder}/{f}")
        img.thumbnail((cell - 8, cell - 28))
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(img, (x + (cell - img.width) // 2, y + 4), img)
        d.text((x + 4, y + cell - 16), f.split(".")[0], fill=(255, 255, 0, 255))
    sheet.save(f"tools/_contact_{out_name}.png")
    print(f"  📸 contact sheet: tools/_contact_{out_name}.png ({len(files)} sprite)")

if __name__ == "__main__":
    print("== PIXEL GALAXY WORLD :: SPRITE PIPELINE v2 ==")
    for d in ["characters", "monsters", "tiles", "buildings", "items", "ui", "effects"]:
        os.makedirs(f"{DST}/{d}", exist_ok=True)

    # Karakter: baris1 = 4 frame jalan, baris2 = 2 frame idle
    for name, src in [("rex", "char-rex-sheet"), ("luna", "char-luna-sheet"), ("bolt", "char-bolt-sheet")]:
        process_anim_sheet(f"{SRC}/{src}.png", f"{DST}/characters", name, [4, 2], max_wh=48)
    for name, src in [("slime", "monster-slime-sheet"), ("zapper", "monster-zapper-sheet"),
                      ("golem", "monster-golem-sheet"), ("stalker", "monster-stalker-sheet"),
                      ("bat", "monster-bat-sheet")]:
        process_anim_sheet(f"{SRC}/{src}.png", f"{DST}/monsters", name, [4, 2], max_wh=64)

    # Tileset 4x4
    tile_names = ["grass", "dirt", "sand", "water",
                  "spacerock", "grass-mushroom", "dirt-pebbles", "water-edge",
                  "crystal-ground", "ash", "swamp", "path-stone",
                  "grass-flowers", "rocky", "snow", "grass-dirt-edge"]
    process_tileset(f"{SRC}/tileset-terrain.png", f"{DST}/tiles", 4, 32, tile_names)

    # Koleksi
    process_collection(f"{SRC}/buildings-sheet.png", f"{DST}/buildings", "building", max_wh=96)
    process_collection(f"{SRC}/items-sheet.png", f"{DST}/items", "item", max_wh=48)
    process_collection(f"{SRC}/ui-sheet.png", f"{DST}/ui", "ui", max_wh=96, min_area=250)
    process_collection(f"{SRC}/effects-sheet.png", f"{DST}/effects", "fx", max_wh=48, min_area=120, dilate=12)

    # Menu assets (langsung, tanpa potong)
    for src, dst in [("title-art.png", "menu/title-art.png"), ("logo-icon.png", "menu/logo-icon.png"),
                     ("menu-background.png", "menu/menu-background.png")]:
        img = remove_magenta(Image.open(f"{SRC}/{src}"))
        img.save(f"{DST}/{dst}")
        print(f"  ✓ {dst}")

    # Contact sheets untuk verifikasi
    for folder, prefix in [("characters", "rex"), ("characters", "luna"), ("characters", "bolt"),
                           ("monsters", "slime"), ("monsters", "zapper"), ("monsters", "golem"),
                           ("monsters", "stalker"), ("monsters", "bat"),
                           ("buildings", "building"), ("items", "item"), ("ui", "ui"), ("effects", "fx")]:
        make_contact_sheet(f"{DST}/{folder}", prefix, f"{folder}-{prefix}")

    print("== SELESAI ==")
