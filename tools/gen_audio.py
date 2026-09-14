#!/usr/bin/env python3
"""Generate 4 audio WAV sintetis untuk Pixel Galaxy World.
Output: project/resources/audio/{menu,ambient,alert,build}.wav
Format: mono 16-bit PCM 22050 Hz (kecil, didukung GDevelop).
Semua pakai stdlib (wave + math) — tanpa dependency.
"""
import wave, math, struct, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "project", "resources", "audio")
os.makedirs(OUT, exist_ok=True)


def write_wav(name, samples):
    """samples: list[float] -1..1 -> mono 16-bit WAV"""
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples)
        w.writeframes(frames)
    print(f"  {name}: {len(samples)/SR:.2f}s, {os.path.getsize(path)} bytes")


def tone(freq, dur, vol=0.5, shape="sine", attack=0.01, release=0.05):
    """Satu nada dengan envelope attack/release."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        if shape == "sine":
            v = math.sin(2 * math.pi * freq * t)
        elif shape == "square":
            v = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        elif shape == "triangle":
            v = 2 / math.pi * math.asin(math.sin(2 * math.pi * freq * t))
        elif shape == "noise":
            v = random.uniform(-1, 1)
        # envelope
        env = 1.0
        if t < attack:
            env = t / attack if attack > 0 else 1.0
        if t > dur - release:
            r = dur - t
            env = min(env, r / release if release > 0 else 1.0)
        out.append(v * env * vol)
    return out


def mix(*layers):
    """Superposisi list sampel sama-panjang."""
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, v in enumerate(l):
            out[i] += v
    peak = max(abs(v) for v in out) or 1.0
    if peak > 0.95:
        out = [v * 0.95 / peak for v in out]
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


print("Generating Pixel Galaxy World audio...")

# ============ 1. menu.wav — musik menu loop, chiptune arpeggio lembut ============
# Progresi Am (pentatonik A-C-E-G) 2 bar, loop mulus (nada akhir panjang)
bpm = 100
beat = 60 / bpm
seq = [  # (freq, dur_in_beats)
    (220.00, 0.5), (261.63, 0.5), (329.63, 0.5), (392.00, 0.5),  # Am7 naik
    (440.00, 0.5), (392.00, 0.5), (329.63, 0.5), (261.63, 0.5),  # turun
    (220.00, 0.5), (329.63, 0.5), (392.00, 0.5), (523.25, 0.5),  # arpeggio tinggi
    (440.00, 1.0), (330.00, 1.0),                                 # resolusi lembut
]
lead = []
for f, b in seq:
    lead.extend(tone(f, beat * b, vol=0.32, shape="triangle",
                     attack=0.02, release=0.06))
bass = concat(
    tone(110.00, beat * 4, vol=0.22, shape="sine", attack=0.05, release=0.2),
    tone(98.00, beat * 4, vol=0.22, shape="sine", attack=0.05, release=0.2),
    tone(110.00, beat * 4, vol=0.22, shape="sine", attack=0.05, release=0.2),
    tone(87.31, beat * 4, vol=0.22, shape="sine", attack=0.05, release=0.2),
)
menu = mix(lead, bass)
write_wav("menu.wav", menu)

# ============ 2. ambient.wav — drone ambient planet asing, loop ============
# Dua osilator rendah + shimmer halus, 12 detik loop mulus
dur = 12.0
n = int(SR * dur)
amb = []
drift = 0.0
for i in range(n):
    t = i / SR
    drift += 0.00007
    f1 = 82.4 + 0.6 * math.sin(2 * math.pi * 0.05 * t)   # E2 drift
    f2 = 123.5 + 0.8 * math.sin(2 * math.pi * 0.07 * t)  # B2 drift
    v = (math.sin(2 * math.pi * f1 * t) * 0.30 +
         math.sin(2 * math.pi * f2 * t) * 0.22 +
         math.sin(2 * math.pi * (f1 * 3) * t) * 0.06 +    # harmonik lembut
         (random.uniform(-1, 1) * 0.015))                # noise angin halus
    # fade in/out untuk loop mulus
    env = min(t / 1.5, 1.0, (dur - t) / 1.5)
    amb.append(v * env)
write_wav("ambient.wav", amb)

# ============ 3. alert.wav — alarm raid, dua nada naik ============
alert = concat(
    tone(660, 0.12, vol=0.55, shape="square", attack=0.005, release=0.02),
    tone(880, 0.12, vol=0.55, shape="square", attack=0.005, release=0.02),
    tone(660, 0.12, vol=0.55, shape="square", attack=0.005, release=0.02),
    tone(880, 0.25, vol=0.55, shape="square", attack=0.005, release=0.1),
)
write_wav("alert.wav", alert)

# ============ 4. build.wav — thunk konstruksi pendek ============
thud = tone(140, 0.18, vol=0.6, shape="sine", attack=0.002, release=0.12)
click = tone(1200, 0.03, vol=0.25, shape="square", attack=0.001, release=0.01)
noise_hit = tone(300, 0.08, vol=0.3, shape="noise", attack=0.001, release=0.05)
build = mix(concat(thud, [0.0] * int(SR * 0.02)), concat(noise_hit, click))
write_wav("build.wav", build)

print("Done. Files at:", OUT)
