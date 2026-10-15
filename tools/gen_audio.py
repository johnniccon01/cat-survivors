"""Generates all of the game's sound effects and music as WAV files.

Everything is synthesised from scratch (square/triangle/sine waves and
noise), so there are no third-party assets or licences involved.

    python tools/gen_audio.py

writes into assets/audio/. Re-run after tweaking anything below.
"""
import array
import math
import os
import random
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
random.seed(7)


# --- basic waves ---------------------------------------------------------------

def osc(kind, phase, duty=0.5):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "tri":
        return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "noise":
        return random.uniform(-1.0, 1.0)
    return math.sin(2.0 * math.pi * p)


def tone(dur, f0, f1=None, kind="square", vol=0.5, attack=0.005, release=0.05, duty=0.5, vibrato=0.0):
    """One note with a linear pitch slide from f0 to f1 and an AR envelope."""
    f1 = f0 if f1 is None else f1
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        k = i / max(n - 1, 1)
        f = f0 + (f1 - f0) * k
        if vibrato:
            f *= 1.0 + 0.02 * math.sin(2 * math.pi * vibrato * t)
        phase += f / SR
        env = min(1.0, t / attack) if attack > 0 else 1.0
        env *= min(1.0, (dur - t) / release) if release > 0 else 1.0
        out.append(osc(kind, phase, duty) * vol * max(env, 0.0))
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def lowpass(samples, amount=0.3):
    out, y = [], 0.0
    for v in samples:
        y += amount * (v - y)
        out.append(y)
    return out


def save(name, samples, gain=1.0):
    os.makedirs(OUT, exist_ok=True)
    data = array.array("h")
    for v in samples:
        v = math.tanh(v * gain)  # soft limiter
        data.append(int(max(-1.0, min(1.0, v)) * 32000))
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# --- sound effects -----------------------------------------------------------------

def sfx():
    save("hit", tone(0.06, 400, 180, "square", 0.35, duty=0.25, release=0.04))
    save("pop", mix(tone(0.09, 600, 120, "square", 0.3, duty=0.5), lowpass(tone(0.08, 0, 0, "noise", 0.25), 0.4)))
    save("xp", tone(0.06, 1300, 1800, "square", 0.22, duty=0.25, release=0.03))
    save("heal", seq(tone(0.07, 660, None, "tri", 0.4), tone(0.07, 880, None, "tri", 0.4), tone(0.14, 1320, None, "tri", 0.4, release=0.1)))
    save("hurt", mix(tone(0.18, 220, 70, "square", 0.4, duty=0.4, release=0.1), lowpass(tone(0.12, 0, 0, "noise", 0.3), 0.2)))
    save("levelup", seq(*[tone(0.08, f, None, "square", 0.3, duty=0.25) for f in (523, 659, 784, 1047)], tone(0.25, 1319, None, "square", 0.3, duty=0.25, release=0.2, vibrato=6)))
    save("chest", seq(tone(0.12, 196, 392, "tri", 0.45), *[tone(0.06, f, None, "square", 0.25, duty=0.125) for f in (784, 988, 1175, 1568, 1976)], tone(0.3, 2349, None, "tri", 0.3, release=0.25)))
    save("click", tone(0.03, 900, 700, "square", 0.25, duty=0.25))
    save("select", seq(tone(0.05, 660, None, "square", 0.25, duty=0.25), tone(0.1, 990, None, "square", 0.25, duty=0.25, release=0.08)))
    save("scratch", lowpass(tone(0.12, 0, 0, "noise", 0.5, attack=0.01, release=0.08), 0.55))
    save("throw", tone(0.1, 300, 700, "tri", 0.4, release=0.05))
    save("hairball", mix(tone(0.16, 160, 90, "saw", 0.3), lowpass(tone(0.16, 0, 0, "noise", 0.3), 0.15)))
    save("laser", tone(0.14, 1800, 300, "square", 0.25, duty=0.125, release=0.06))
    save("splash", lowpass(seq(tone(0.04, 0, 0, "noise", 0.4), tone(0.2, 0, 0, "noise", 0.25, release=0.18)), 0.25))
    save("bell", mix(tone(0.6, 1568, None, "sine", 0.35, release=0.55), tone(0.6, 2093, None, "sine", 0.15, release=0.5), tone(0.6, 3136, None, "sine", 0.08, release=0.3)))
    save("whoosh", lowpass(tone(0.22, 0, 0, "noise", 0.45, attack=0.08, release=0.12), 0.18))
    save("break", mix(lowpass(tone(0.15, 0, 0, "noise", 0.5), 0.35), tone(0.1, 180, 80, "square", 0.25)))
    save("magnet", tone(0.4, 200, 1200, "tri", 0.35, release=0.1, vibrato=12))
    save("warning", seq(*[tone(0.18, f, None, "square", 0.3, duty=0.5, release=0.04) for f in (440, 330, 440, 330)]))
    save("quest", seq(tone(0.08, 784, None, "tri", 0.4), tone(0.08, 988, None, "tri", 0.4), tone(0.18, 1175, None, "tri", 0.4, release=0.15)))
    save("quest_done", seq(*[tone(0.09, f, None, "square", 0.28, duty=0.25) for f in (523, 659, 784, 659, 784)], tone(0.35, 1047, None, "square", 0.28, duty=0.25, release=0.3, vibrato=6)))
    save("meow", mix(tone(0.35, 700, 520, "saw", 0.25, attack=0.04, release=0.15, vibrato=8), tone(0.35, 1400, 1040, "sine", 0.1, attack=0.04, release=0.15)))
    save("victory", seq(*[tone(0.12, f, None, "square", 0.3, duty=0.25) for f in (523, 523, 523, 659, 784, 659, 784)], tone(0.6, 1047, None, "square", 0.3, duty=0.25, release=0.5, vibrato=5)))
    save("gameover", seq(*[tone(0.22, f, None, "tri", 0.4) for f in (392, 370, 349)], tone(0.7, 330, 260, "tri", 0.4, release=0.6, vibrato=4)))


# --- music -------------------------------------------------------------------------

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def freq(name, octave):
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octave - 4) - 9) / 12.0)


def chord_tones(root, minor):
    third = 3 if minor else 4
    r = NOTE[root]
    return [r, r + third, r + 7]


def song(name, bpm, chords, melody, lead_duty=0.25, drums=True, bars_per_chord=1, lead_vol=0.16):
    """chords: list of (root, minor); melody: list of (semitone offset from C5 or None, beats)."""
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * bars_per_chord * len(chords)
    n = int(total * SR)
    out = [0.0] * n

    def add(samples, start):
        i0 = int(start * SR)
        for i, v in enumerate(samples):
            if i0 + i < n:
                out[i0 + i] += v

    t = 0.0
    for root, minor in chords:
        tones = chord_tones(root, minor)
        for b in range(bars_per_chord * 4):
            # Bass: root on the beat, fifth on the off-beat.
            add(tone(beat * 0.45, freq(root, 2), None, "tri", 0.35, release=0.05), t)
            fifth = 440.0 * 2 ** ((tones[2] - 9 - 24) / 12.0)
            add(tone(beat * 0.4, fifth, None, "tri", 0.25, release=0.05), t + beat * 0.5)
            # Arpeggio on eighth notes, quiet.
            for k in range(2):
                semi = tones[(b * 2 + k) % 3]
                f = 440.0 * 2 ** ((semi - 9) / 12.0)
                add(tone(beat * 0.22, f, None, "square", 0.05, duty=0.125, release=0.04), t + k * beat * 0.5)
            if drums:
                if b % 2 == 0:
                    add(tone(0.12, 150, 45, "sine", 0.55, release=0.08), t)
                else:
                    add(lowpass(tone(0.1, 0, 0, "noise", 0.3, release=0.08), 0.5), t)
                add(tone(0.03, 0, 0, "noise", 0.08, release=0.02), t + beat * 0.5)
            t += beat
    # Lead melody, looped over the whole song.
    t = 0.0
    i = 0
    while t < total - 0.01:
        semi, beats = melody[i % len(melody)]
        dur = beats * beat
        if semi is not None:
            f = freq("C", 5) * 2 ** (semi / 12.0)
            add(tone(dur * 0.9, f, None, "square", lead_vol, duty=lead_duty, release=min(0.08, dur * 0.4), vibrato=5), t)
        t += dur
        i += 1
    save(name, out, gain=1.2)


def music():
    # Apartment: cheerful C major, C - Am - F - G.
    song("music_apartment", 124,
         [("C", False), ("A", True), ("F", False), ("G", False)] * 2,
         [(7, 1), (4, 0.5), (7, 0.5), (9, 1), (7, 1), (4, 1), (2, 0.5), (0, 0.5), (2, 1), (None, 1),
          (5, 1), (4, 0.5), (5, 0.5), (7, 1), (9, 1), (11, 1), (12, 1), (7, 2)])
    # Basement: slower, A minor, sparse lead.
    song("music_basement", 96,
         [("A", True), ("F", False), ("D", True), ("E", False)] * 2,
         [(-3, 1.5), (0, 0.5), (2, 1), (None, 1), (3, 1.5), (2, 0.5), (0, 1), (None, 1),
          (-1, 1), (0, 1), (2, 1), (-4, 1), (-3, 3), (None, 1)],
         lead_duty=0.5, lead_vol=0.12)
    # Final boss: fast, driving D minor.
    song("music_boss", 156,
         [("D", True), ("A#", False), ("C", False), ("A", False)] * 2,
         [(2, 0.5), (2, 0.5), (5, 0.5), (2, 0.5), (9, 1), (7, 0.5), (5, 0.5), (4, 1), (2, 1), (1, 1), (4, 1),
          (2, 0.5), (5, 0.5), (9, 0.5), (14, 0.5), (12, 1), (10, 1), (9, 2)],
         lead_vol=0.15)


if __name__ == "__main__":
    sfx()
    music()
    print("written to", OUT)
