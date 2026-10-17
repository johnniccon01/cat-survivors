"""Generates all of the game's sound effects and music as WAV files.

Everything is synthesised from scratch (square/triangle/sine waves and
noise), so there are no third-party assets or licences involved.

    python tools/gen_audio.py

writes into assets/audio/. Re-run after tweaking anything below.
"""
import sys
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

    secret_sfx()
    more_sfx()


def more_sfx():
    """Boss roar, golden mouse squeak, champion sparkle, sparks, thunder, coins."""
    growl = mix(tone(0.9, 90, 60, "saw", 0.35, attack=0.08, release=0.4, vibrato=9),
                tone(0.9, 135, 90, "square", 0.15, duty=0.3, attack=0.08, release=0.4, vibrato=7),
                lowpass(tone(0.9, 0, 0, "noise", 0.35, attack=0.05, release=0.5), 0.08))
    save("roar", growl, gain=1.3)
    save("squeak", seq(tone(0.06, 1700, 2300, "square", 0.22, duty=0.25), silence(0.03), tone(0.08, 1900, 2600, "square", 0.22, duty=0.25, release=0.05)))
    save("sparkle", mix(*[seq(silence(i * 0.05), tone(0.25, f, None, "sine", 0.18, release=0.2)) for i, f in enumerate((1568, 2093, 2637, 3136))]))
    crack = []
    for i in range(6):
        crack += lowpass(tone(0.02, 0, 0, "noise", 0.5, attack=0.001, release=0.01), 0.6) + silence(0.012 * (i % 3))
    save("zap", mix(crack, tone(0.14, 2400, 900, "square", 0.12, duty=0.125, release=0.05)))
    save("thunder", mix(lowpass(tone(1.1, 0, 0, "noise", 0.8, attack=0.005, release=0.9), 0.12),
                        lowpass(tone(0.08, 0, 0, "noise", 0.7, attack=0.001, release=0.05), 0.7)), gain=1.4)
    save("coin", seq(tone(0.05, 1319, None, "square", 0.18, duty=0.25), tone(0.12, 1976, None, "square", 0.18, duty=0.25, release=0.1)))


def secret_sfx():
    """The angel cat and devil cat moments."""
    # The cat goes down: two slow, low thumps.
    save("fall", seq(tone(0.14, 95, 60, "sine", 0.7, release=0.1), silence(0.16), tone(0.3, 80, 45, "sine", 0.7, release=0.25)))
    # Harp glissando with a soft choir pad underneath.
    harp = [523, 659, 784, 1047, 1319, 1568, 2093]
    notes = [seq(silence(i * 0.09), tone(1.3, f, None, "sine", 0.2, attack=0.004, release=1.1),) for i, f in enumerate(harp)]
    pad = mix(tone(2.0, 523, None, "tri", 0.12, attack=0.5, release=1.0, vibrato=5), tone(2.0, 659, None, "tri", 0.1, attack=0.5, release=1.0, vibrato=5),
              tone(2.0, 784, None, "tri", 0.1, attack=0.5, release=1.0, vibrato=5))
    save("angel", mix(pad, *notes), gain=1.2)
    # Low rumble, a falling tritone and a growl.
    rumble = lowpass(tone(2.0, 0, 0, "noise", 0.7, attack=0.3, release=0.8), 0.04)
    fall = mix(tone(1.6, 110, 55, "saw", 0.25, attack=0.05, release=0.6, vibrato=3), tone(1.6, 155.6, 77.8, "saw", 0.2, attack=0.05, release=0.6, vibrato=3))
    save("devil", mix(rumble, seq(silence(0.2), fall)), gain=1.4)


# --- music -------------------------------------------------------------------------
#
# A small chiptune "band": lead with vibrato and echo, a harmony voice,
# driving octave bass, 16th-note arpeggios and drums with fills. Songs are
# written as chord lists plus melodies in a compact text notation:
#   "E5:.5 G5:.5 C6:1 R:1"  = note:beats, R is a rest.
# A song plays its A part twice and B part twice (A B A' B', where the
# repeats add a harmony voice), so each loop is 32 bars.

NOTE = {"C": 0, "C#": 1, "DB": 1, "D": 2, "D#": 3, "EB": 3, "E": 4, "F": 5, "F#": 6, "GB": 6,
        "G": 7, "G#": 8, "AB": 8, "A": 9, "A#": 10, "BB": 10, "B": 11}


def midi(name):
    """'C#5' -> MIDI number."""
    name = name.upper()
    octave = int(name[-1])
    return NOTE[name[:-1]] + 12 * (octave + 1)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def parse_chord(c):
    """'Am' -> (root semitone 0-11, minor?)."""
    minor = c.endswith("m")
    root = c[:-1] if minor else c
    return NOTE[root.upper()], minor


def parse_melody(text):
    out = []
    for tok in text.split():
        n, beats = tok.split(":")
        out.append((None if n.upper() == "R" else midi(n), float(beats)))
    return out


class Track:
    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.buf = array.array("f", bytes(4 * self.n))

    def add(self, samples, start):
        i0 = int(start * SR)
        buf = self.buf
        n = self.n
        for i, v in enumerate(samples):
            j = i0 + i
            if j >= n:
                j -= n  # wrap so tails ring into the loop start (seamless loop)
            buf[j] += v


def note(dur, f, kind="square", vol=0.2, duty=0.25, attack=0.005, decay=0.12, sustain=0.7, release=0.06, vib=0.0, vib_delay=0.15):
    n = max(int(dur * SR), 1)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        ff = f
        if vib and t > vib_delay:
            ff *= 1.0 + 0.012 * math.sin(2 * math.pi * vib * t)
        phase += ff / SR
        if t < attack:
            env = t / attack
        elif t < attack + decay:
            env = 1.0 - (1.0 - sustain) * (t - attack) / decay
        else:
            env = sustain
        tail = dur - t
        if tail < release:
            env *= max(tail / release, 0.0)
        out.append(osc(kind, phase, duty) * vol * env)
    return out


def kick():
    return [math.sin(2 * math.pi * (55 + 100 * math.exp(-i / 400.0)) * i / SR) * 0.6 * math.exp(-i / 2600.0) for i in range(int(0.16 * SR))]


def snare():
    out, y = [], 0.0
    for i in range(int(0.14 * SR)):
        y += 0.6 * (random.uniform(-1, 1) - y)
        out.append((y * 0.35 + 0.15 * math.sin(2 * math.pi * 190 * i / SR)) * math.exp(-i / 1500.0))
    return out


def hat(open_=False):
    length = 0.12 if open_ else 0.035
    out, prev = [], 0.0
    for i in range(int(length * SR)):
        x = random.uniform(-1, 1)
        out.append((x - prev) * 0.09 * math.exp(-i / (1600.0 if open_ else 300.0)))
        prev = x
    return out


DRUM_KICK = kick()
DRUM_SNARE = snare()
DRUM_HAT = hat()
DRUM_OPEN = hat(True)


def song(name, bpm, sections, order=("A", "B", "A+", "B+"), style="drive", lead_kind="square", lead_duty=0.25, drums=True, gain=1.1):
    """`sections`: name -> (chords, melody). `order` lists the sections to
    play; a "+" suffix adds the harmony voice, "~" is a breakdown (no drums,
    long bass notes, quieter arpeggio)."""
    beat = 60.0 / bpm
    bar = beat * 4
    for key, (chords, mel) in sections.items():
        beats = sum(b for _, b in parse_melody(mel))
        assert abs(beats - 4 * len(chords)) < 1e-6, "%s %s: %s beats for %d bars" % (name, key, beats, len(chords))
    parts = []
    for entry in order:
        key = entry.rstrip("+~")
        chords, mel = sections[key]
        parts.append((chords, mel, "+" in entry, "~" in entry))
    bars_total = sum(len(p[0]) for p in parts)
    total = bars_total * bar
    lead = Track(total)
    back = Track(total)
    t0 = 0.0
    bar_index = 0
    for chords, mel_text, harmony, calm in parts:
        # --- accompaniment, bar by bar ---
        for ci, c in enumerate(chords):
            root, minor = parse_chord(c)
            tones = [root, root + (3 if minor else 4), root + 7]
            bt = t0 + ci * bar
            # Bass
            for k in range(8):
                pos = bt + k * beat * 0.5
                if calm:
                    if k % 4 == 0:
                        back.add(note(beat * 1.9, hz(36 + root), "tri", 0.3, release=0.2), pos)
                elif style == "drive":
                    m = 36 + root + (12 if k % 2 else 0)
                    back.add(note(beat * 0.45, hz(m), "tri", 0.34, release=0.03), pos)
                elif style == "gallop":
                    m = 36 + root + (7 if k in (3, 7) else 0)
                    back.add(note(beat * 0.4, hz(m), "tri", 0.34, release=0.03), pos)
                elif k % 2 == 0:  # "bounce": root on beats, fifth on 2 and 4
                    m = 36 + root + (7 if k in (2, 6) else 0)
                    back.add(note(beat * 0.85, hz(m), "tri", 0.32, release=0.08), pos)
            # 16th-note arpeggio across two octaves (8ths, softer, in a breakdown)
            arp = [60 + tones[0], 60 + tones[1], 60 + tones[2], 72 + tones[0], 60 + tones[2], 60 + tones[1]]
            steps = 8 if calm else 16
            for k in range(steps):
                m = arp[k % len(arp)] - (12 if style == "bounce" else 0)
                back.add(note(beat * (0.4 if calm else 0.2), hz(m), "square", 0.025 if calm else 0.035, duty=0.125, release=0.02), bt + k * beat * (4.0 / steps))
            # Drums
            if drums and not calm:
                is_fill = (bar_index + ci) % 4 == 3
                for k in range(8):
                    pos = bt + k * beat * 0.5
                    if k in (0, 4) or (style == "drive" and k == 7 and not is_fill):
                        back.add(DRUM_KICK, pos)
                    if k in (2, 6):
                        back.add(DRUM_SNARE, pos)
                    if is_fill and k >= 5:
                        back.add(DRUM_SNARE, pos + beat * 0.25)
                    back.add(DRUM_OPEN if (k == 7 and is_fill) else DRUM_HAT, pos)
            elif drums and calm and ci % 2 == 1:
                back.add(DRUM_OPEN, bt + beat * 3.5)
        # --- melody (+ echo, + harmony on repeats) ---
        t = t0
        for m, beats in parse_melody(mel_text):
            dur = beats * beat
            if m is not None:
                tone_samples = note(dur * 0.92, hz(m), lead_kind, 0.15, duty=lead_duty, vib=5.5, release=min(0.08, dur * 0.3))
                lead.add(tone_samples, t)
                lead.add([v * 0.28 for v in tone_samples], t + beat * 0.75)  # echo
                if harmony:
                    # A third (or so) below, quieter, on a softer wave.
                    lead.add(note(dur * 0.9, hz(m - 4), "tri", 0.07, release=min(0.08, dur * 0.3)), t)
            t += dur
        t0 += len(chords) * bar
        bar_index += len(chords)

    out = [lowpass_v + bv for lowpass_v, bv in zip(lowpass(list(lead.buf), 0.55), back.buf)]
    save(name, out, gain=gain)


# --- the songs ----------------------------------------------------------------
#
# Every map has a long day/evening track (A B, repeats, a calm bridge C, a
# climax D, then home) and a night track that takes over half way through
# the night. Final bosses and the devil have their own themes.

MAP_ORDER = ("A", "B", "A+", "B+", "C~", "C", "D", "D+", "A+", "B+")
NIGHT_ORDER = ("A", "B", "A+", "B+", "C", "C+", "A+", "B+")


def music(only=None):
    def want(n):
        return only is None or n in only

    # Apartment: bouncy C major, a hummable hook.
    if want("music_apartment"):
        song("music_apartment", 132, {
            "A": (["C", "G", "Am", "F", "C", "G", "F", "G"],
                  "E5:.5 G5:.5 C6:1 B5:.5 G5:.5 E5:1  D5:.5 G5:.5 B5:1 A5:.5 G5:.5 D5:1  "
                  "C5:.5 E5:.5 A5:1 G5:.5 E5:.5 C5:1  F5:1 E5:.5 D5:.5 C5:2  "
                  "E5:.5 G5:.5 C6:1 D6:.5 C6:.5 G5:1  B5:.5 D6:.5 G6:1 F6:.5 D6:.5 B5:1  "
                  "A5:1 G5:.5 F5:.5 E5:.5 F5:.5 G5:1  G5:3 R:1"),
            "B": (["Am", "F", "C", "G", "Am", "F", "G", "G"],
                  "A5:1.5 G5:.5 E5:1 C5:1  F5:1.5 E5:.5 C5:1 A4:1  E5:.5 F5:.5 G5:1 C6:1 G5:1  "
                  "D5:.5 E5:.5 F5:.5 G5:.5 B5:2  A5:.5 B5:.5 C6:1 B5:.5 A5:.5 E5:1  "
                  "F5:.5 G5:.5 A5:1 G5:.5 F5:.5 C5:1  B4:.5 D5:.5 G5:1 F5:.5 D5:.5 B4:1  D5:2 G5:2"),
            "C": (["F", "G", "Em", "Am", "F", "G", "C", "C"],
                  "C5:2 E5:1 F5:1  G5:2 B4:1 D5:1  E5:1.5 D5:.5 B4:1 G4:1  A4:3 C5:1  "
                  "F5:1 A5:1 C6:1 A5:1  G5:1 B5:1 D6:1 B5:1  C6:1 G5:1 E5:1 C5:1  C5:3 R:1"),
            "D": (["C", "Em", "F", "G", "Am", "Em", "F", "G"],
                  "G5:.5 A5:.5 G5:.5 E5:.5 C6:1 G5:1  B5:.5 C6:.5 B5:.5 G5:.5 E5:2  "
                  "A5:.5 C6:.5 A5:.5 F5:.5 C5:1 F5:1  G5:.5 B5:.5 D6:.5 B5:.5 G5:2  "
                  "E6:1 D6:.5 C6:.5 A5:1 C6:1  B5:1 G5:.5 E5:.5 B4:2  "
                  "C6:.5 A5:.5 F5:.5 A5:.5 C6:1 F6:1  D6:1 B5:1 G5:2"),
        }, MAP_ORDER, style="bounce")

    # Basement: dark A minor, driving octave bass.
    if want("music_basement"):
        song("music_basement", 116, {
            "A": (["Am", "Am", "F", "G", "Am", "Am", "E", "E"],
                  "A4:.5 C5:.5 E5:.5 A5:1.5 G5:.5 E5:.5  F5:.5 E5:.5 D5:.5 C5:.5 B4:1 C5:1  "
                  "A4:.5 C5:.5 F5:.5 A5:1.5 G5:.5 F5:.5  G5:1 F5:.5 E5:.5 D5:2  "
                  "A4:.5 C5:.5 E5:.5 A5:1 B5:.5 C6:1  B5:.5 A5:.5 G5:.5 E5:.5 C5:2  "
                  "B4:.5 D5:.5 E5:.5 G#5:1 F5:.5 E5:1  E5:3 R:1"),
            "B": (["Dm", "Dm", "Am", "Am", "F", "G", "E", "E"],
                  "D5:1 F5:1 A5:1.5 G5:.5  F5:.5 E5:.5 D5:1 A4:2  C5:1 E5:1 A5:1.5 B5:.5  "
                  "C6:.5 B5:.5 A5:1 E5:2  F5:.5 G5:.5 A5:1 C6:1 A5:1  B5:.5 A5:.5 G5:1 D5:2  "
                  "E5:.5 F5:.5 G#5:1 B5:1 G#5:1  E5:2 R:2"),
            "C": (["Am", "G", "F", "E", "Am", "G", "F", "E"],
                  "E5:2 D5:1 C5:1  B4:2 C5:1 D5:1  C5:2 B4:1 A4:1  G#4:3 R:1  "
                  "E5:1 F5:1 G5:1 A5:1  B5:2 G5:2  A5:1 G5:1 F5:1 E5:1  E5:3 R:1"),
            "D": (["Dm", "E", "Am", "C", "Dm", "E", "Am", "Am"],
                  "D5:.5 F5:.5 A5:.5 D6:.5 C6:1 A5:1  B5:.5 G#5:.5 E5:.5 B4:.5 E5:2  "
                  "A5:.5 C6:.5 E6:1 D6:.5 C6:.5 A5:1  G5:.5 E5:.5 C5:.5 E5:.5 G5:2  "
                  "F5:1 A5:1 D6:1 F6:1  E6:1 D6:.5 B5:.5 G#5:2  "
                  "A5:.5 B5:.5 C6:.5 B5:.5 A5:1 E5:1  A5:3 R:1"),
        }, MAP_ORDER, style="drive")

    # Garden: sunny F major, soft triangle "flute" lead.
    if want("music_garden"):
        song("music_garden", 124, {
            "A": (["F", "C", "Dm", "Bb", "F", "C", "Bb", "C"],
                  "C5:.5 F5:.5 A5:1 G5:.5 F5:.5 C5:1  E5:.5 G5:.5 C6:1 Bb5:.5 G5:.5 E5:1  "
                  "D5:.5 F5:.5 A5:1 C6:.5 A5:.5 F5:1  D5:1 F5:1 Bb5:2  "
                  "A5:.5 C6:.5 A5:.5 F5:.5 G5:1 A5:1  G5:.5 E5:.5 C5:1 E5:.5 G5:.5 C6:1  "
                  "Bb5:.5 A5:.5 G5:.5 F5:.5 D5:1 F5:1  E5:1 G5:1 C5:2"),
            "B": (["Dm", "Bb", "F", "C", "Dm", "Bb", "C", "C"],
                  "A5:1.5 F5:.5 D5:1 F5:1  Bb5:1.5 F5:.5 D5:1 Bb4:1  A5:.5 G5:.5 F5:1 C6:1 A5:1  "
                  "G5:3 R:1  D6:1 C6:.5 A5:.5 F5:1 A5:1  Bb5:1 A5:.5 F5:.5 D5:2  "
                  "C5:.5 E5:.5 G5:.5 Bb5:.5 C6:1 Bb5:1  G5:2 E5:2"),
            "C": (["Bb", "C", "Am", "Dm", "Bb", "C", "F", "F"],
                  "D5:2 F5:1 Bb5:1  C6:2 G5:1 E5:1  C5:1.5 E5:.5 A5:2  F5:3 R:1  "
                  "Bb5:1 A5:1 G5:1 F5:1  E5:1 G5:1 C6:2  A5:1 F5:1 C5:1 A4:1  F5:3 R:1"),
            "D": (["F", "Am", "Bb", "C", "Dm", "Am", "Bb", "C"],
                  "F5:.5 G5:.5 A5:.5 C6:.5 F6:1 C6:1  E6:.5 C6:.5 A5:.5 E5:.5 A5:2  "
                  "D6:.5 C6:.5 Bb5:.5 F5:.5 D5:1 F5:1  E5:.5 G5:.5 C6:.5 G5:.5 E5:2  "
                  "F5:1 A5:1 D6:1 A5:1  C6:1 A5:.5 E5:.5 C5:2  "
                  "D5:.5 F5:.5 Bb5:.5 D6:.5 F6:1 D6:1  C6:1 Bb5:1 G5:2"),
        }, MAP_ORDER, style="bounce", lead_kind="tri", lead_duty=0.5, gain=1.3)

    # Rooftop: epic night run, D minor, galloping bass.
    if want("music_rooftop"):
        song("music_rooftop", 146, {
            "A": (["Dm", "Bb", "C", "A", "Dm", "Bb", "Gm", "A"],
                  "D5:.5 F5:.5 A5:.5 D6:1.5 C6:.5 A5:.5  Bb5:1 A5:.5 G5:.5 F5:1 D5:1  "
                  "E5:.5 G5:.5 C6:.5 E6:1.5 D6:.5 C6:.5  C#6:1 E6:1 A5:2  "
                  "D6:.5 C6:.5 A5:.5 F5:.5 D5:1 F5:1  G5:.5 F5:.5 D5:.5 Bb4:.5 D5:1 F5:1  "
                  "G5:.5 A5:.5 Bb5:1 A5:.5 G5:.5 D5:1  E5:.5 F5:.5 G5:.5 A5:.5 C#6:2"),
            "B": (["Bb", "C", "Dm", "Dm", "Gm", "A", "Dm", "A"],
                  "F5:1 Bb5:1 D6:1.5 C6:.5  E5:1 G5:1 C6:1.5 Bb5:.5  A5:.5 D6:.5 F6:1 E6:.5 D6:.5 A5:1  "
                  "D6:3 R:1  G5:.5 Bb5:.5 D6:1 C6:.5 Bb5:.5 G5:1  A5:.5 C#6:.5 E6:1 D6:.5 C#6:.5 A5:1  "
                  "F5:.5 A5:.5 D6:1 F6:1 E6:1  C#6:2 A5:2"),
            "C": (["Gm", "A", "Dm", "Bb", "Gm", "A", "Dm", "Dm"],
                  "G5:2 Bb5:1 D6:1  C#6:2 A5:1 E5:1  F5:1.5 E5:.5 D5:2  F5:2 Bb5:2  "
                  "G5:1 A5:1 Bb5:1 D6:1  E6:2 C#6:2  D6:1 A5:1 F5:1 D5:1  D5:3 R:1"),
            "D": (["Dm", "C", "Bb", "A", "Dm", "C", "Bb", "A"],
                  "A5:.5 D6:.5 F6:.5 D6:.5 A5:1 F5:1  G5:.5 C6:.5 E6:.5 C6:.5 G5:2  "
                  "F5:.5 Bb5:.5 D6:.5 F6:.5 D6:1 Bb5:1  C#6:.5 E6:.5 A6:.5 E6:.5 C#6:2  "
                  "D6:1 F6:1 E6:.5 D6:.5 C6:1  E6:1 C6:1 G5:2  "
                  "F5:.5 G5:.5 A5:.5 Bb5:.5 D6:1 F6:1  E6:1 C#6:1 A5:2"),
        }, MAP_ORDER, style="gallop", lead_duty=0.5)

    # --- night tracks: from half way through the night ---
    if want("music_apartment_night"):
        song("music_apartment_night", 138, {
            "A": (["Am", "F", "C", "G", "Am", "F", "E", "E"],
                  "A4:.5 C5:.5 E5:.5 A5:.5 G5:1 E5:1  F5:.5 A5:.5 C6:.5 A5:.5 F5:2  "
                  "E5:.5 G5:.5 C6:.5 G5:.5 E5:1 C5:1  D5:.5 G5:.5 B5:.5 G5:.5 D5:2  "
                  "A5:1 C6:1 B5:.5 A5:.5 E5:1  F5:1 A5:1 C6:2  "
                  "B5:.5 G#5:.5 E5:.5 G#5:.5 B5:1 E6:1  E6:3 R:1"),
            "B": (["F", "G", "Em", "Am", "F", "G", "E", "Am"],
                  "C6:1.5 A5:.5 F5:1 A5:1  D6:1.5 B5:.5 G5:1 B5:1  E6:1 B5:1 G5:1 E5:1  A5:2 C6:2  "
                  "F6:1 E6:.5 D6:.5 C6:1 A5:1  D6:1 C6:.5 B5:.5 G5:2  "
                  "G#5:.5 B5:.5 E6:1 D6:.5 B5:.5 G#5:1  A5:3 R:1"),
            "C": (["Dm", "Am", "F", "E", "Dm", "Am", "F", "E"],
                  "D5:1 F5:1 A5:1 D6:1  C6:1 A5:1 E5:1 C5:1  F5:1 A5:1 C6:1 F6:1  E6:2 B5:2  "
                  "D6:.5 C6:.5 A5:.5 F5:.5 D5:2  E5:.5 A5:.5 C6:.5 E6:.5 A5:2  "
                  "F5:.5 A5:.5 C6:.5 F6:.5 E6:1 C6:1  B5:1 G#5:1 E5:2"),
        }, NIGHT_ORDER, style="drive")

    if want("music_basement_night"):
        song("music_basement_night", 100, {
            "A": (["Em", "Em", "C", "D", "Em", "Em", "B", "B"],
                  "E4:1 G4:.5 B4:.5 E5:1 D5:1  B4:1 G4:1 E4:2  C5:1 E5:.5 G5:.5 C6:1 B5:1  "
                  "A5:1 F#5:1 D5:2  E5:.5 G5:.5 B5:.5 E6:.5 D6:1 B5:1  G5:1 E5:1 B4:2  "
                  "D#5:1 F#5:1 B5:1 A5:1  B5:3 R:1"),
            "B": (["Am", "Am", "Em", "Em", "C", "D", "B", "B"],
                  "A5:2 C6:1 B5:1  A5:1 E5:1 C5:2  B4:1 E5:1 G5:1 B5:1  E6:3 R:1  "
                  "C6:1 G5:1 E5:1 C5:1  D5:1 F#5:1 A5:1 D6:1  D#6:1 B5:1 F#5:1 D#5:1  B4:3 R:1"),
            "C": (["C", "D", "Em", "Em", "C", "D", "B", "Em"],
                  "G5:.5 E5:.5 C5:.5 E5:.5 G5:1 C6:1  A5:.5 F#5:.5 D5:.5 F#5:.5 A5:2  "
                  "B5:.5 G5:.5 E5:.5 G5:.5 B5:1 E6:1  D6:1 B5:1 G5:2  "
                  "C6:1 E6:1 D6:.5 C6:.5 G5:1  A5:1 D6:1 F#5:2  "
                  "D#6:.5 B5:.5 F#5:.5 B5:.5 D#6:1 F#6:1  E6:3 R:1"),
        }, NIGHT_ORDER, style="drive", lead_duty=0.125)

    if want("music_garden_night"):
        song("music_garden_night", 118, {
            "A": (["G", "D", "Em", "C", "G", "D", "C", "D"],
                  "B4:.5 D5:.5 G5:1 F#5:.5 D5:.5 A4:1  A4:.5 D5:.5 F#5:1 E5:.5 D5:.5 A4:1  "
                  "G4:.5 B4:.5 E5:1 D5:.5 B4:.5 G4:1  C5:1 E5:1 G5:2  "
                  "B5:.5 A5:.5 G5:1 D5:1 B4:1  A4:.5 D5:.5 F#5:1 A5:2  "
                  "G5:.5 E5:.5 C5:.5 E5:.5 G5:1 C6:1  A5:3 R:1"),
            "B": (["Em", "C", "G", "D", "Em", "C", "D", "D"],
                  "E5:1.5 G5:.5 B5:1 E6:1  C6:1.5 B5:.5 G5:1 E5:1  D5:1 G5:1 B5:1 D6:1  A5:2 F#5:2  "
                  "G5:1 B5:1 E6:1 B5:1  C6:1 A5:.5 G5:.5 E5:2  F#5:.5 G5:.5 A5:1 D6:1 C6:1  A5:2 D5:2"),
            "C": (["C", "G", "Am", "Em", "C", "G", "Am", "D"],
                  "E5:2 G5:1 C6:1  B5:2 G5:1 D5:1  C5:1 E5:1 A5:1 C6:1  B5:3 R:1  "
                  "E6:1 D6:.5 C6:.5 G5:1 E5:1  D6:1 B5:.5 G5:.5 D5:2  "
                  "C6:.5 B5:.5 A5:.5 E5:.5 C5:1 E5:1  F#5:1 A5:1 D6:2"),
        }, NIGHT_ORDER, style="bounce", lead_duty=0.5)

    if want("music_rooftop_night"):
        song("music_rooftop_night", 152, {
            "A": (["Bm", "G", "A", "F#", "Bm", "G", "Em", "F#"],
                  "B4:.5 D5:.5 F#5:.5 B5:1.5 A5:.5 F#5:.5  G5:1 F#5:.5 E5:.5 D5:1 B4:1  "
                  "C#5:.5 E5:.5 A5:.5 C#6:1.5 B5:.5 A5:.5  A#5:1 C#6:1 F#5:2  "
                  "B5:.5 A5:.5 F#5:.5 D5:.5 B4:1 D5:1  E5:.5 D5:.5 B4:.5 G4:.5 B4:1 D5:1  "
                  "E5:.5 F#5:.5 G5:1 F#5:.5 E5:.5 B4:1  C#5:.5 D5:.5 E5:.5 F#5:.5 A#5:2"),
            "B": (["G", "A", "Bm", "Bm", "Em", "F#", "Bm", "F#"],
                  "D5:1 G5:1 B5:1.5 A5:.5  C#5:1 E5:1 A5:1.5 G5:.5  F#5:.5 B5:.5 D6:1 C#6:.5 B5:.5 F#5:1  "
                  "B5:3 R:1  E5:.5 G5:.5 B5:1 A5:.5 G5:.5 E5:1  F#5:.5 A#5:.5 C#6:1 B5:.5 A#5:.5 F#5:1  "
                  "D5:.5 F#5:.5 B5:1 D6:1 C#6:1  A#5:2 F#5:2"),
            "C": (["Em", "F#", "G", "A", "Em", "F#", "Bm", "Bm"],
                  "E5:2 G5:1 B5:1  A#5:2 F#5:1 C#5:1  D5:1.5 E5:.5 B5:2  C#6:2 A5:2  "
                  "B5:1 E6:1 D6:1 B5:1  C#6:1 A#5:1 F#5:2  B5:1 F#5:1 D5:1 B4:1  B4:3 R:1"),
        }, NIGHT_ORDER, style="gallop")

    # --- final bosses ---
    if want("music_boss"):
        # The Vacuum King (and the default): fast E minor.
        song("music_boss", 160, {
            "A": (["Em", "C", "D", "B", "Em", "C", "Am", "B"],
                  "E5:.5 E5:.5 G5:.5 E5:.5 B5:1 A5:1  G5:.5 G5:.5 E5:.5 G5:.5 C6:1 B5:1  "
                  "A5:.5 A5:.5 F#5:.5 A5:.5 D6:1 C6:1  B5:1 D#6:1 F#6:2  "
                  "E6:.5 D6:.5 B5:.5 G5:.5 E5:1 G5:1  C6:.5 B5:.5 G5:.5 E5:.5 C5:1 E5:1  "
                  "A5:.5 C6:.5 E6:1 D6:.5 C6:.5 A5:1  B5:.5 A5:.5 G5:.5 F#5:.5 D#5:2"),
            "B": (["Em", "C", "D", "B", "Em", "Am", "D", "B"],
                  "E5:1 G5:1 B5:1 E6:1  C6:1 B5:.5 A5:.5 G5:2  D5:1 F#5:1 A5:1 D6:1  "
                  "B5:1 A5:.5 G5:.5 F#5:2  G5:.5 A5:.5 B5:1 E6:1 D6:1  C6:.5 B5:.5 A5:1 E5:2  "
                  "F#5:.5 G5:.5 A5:1 C6:1 A5:1  B5:2 B4:2"),
        }, style="drive")

    if want("music_boss_rat"):
        song("music_boss_rat", 168, {
            "A": (["Am", "F", "G", "E", "Am", "F", "Dm", "E"],
                  "A5:.5 A5:.5 C6:.5 A5:.5 E6:1 C6:1  F5:.5 F5:.5 A5:.5 F5:.5 C6:1 A5:1  "
                  "G5:.5 G5:.5 B5:.5 G5:.5 D6:1 B5:1  G#5:1 B5:1 E6:2  "
                  "A5:.5 C6:.5 E6:.5 C6:.5 A5:1 E5:1  F5:.5 A5:.5 C6:.5 A5:.5 F5:1 C5:1  "
                  "D5:.5 F5:.5 A5:.5 D6:.5 F6:1 D6:1  E6:1 D6:.5 B5:.5 G#5:2"),
            "B": (["F", "G", "Am", "Am", "Dm", "E", "Am", "E"],
                  "C6:1 A5:1 F5:1 C6:1  D6:1 B5:1 G5:1 D6:1  E6:1.5 D6:.5 C6:1 A5:1  E6:3 R:1  "
                  "F6:1 D6:1 A5:1 F5:1  G#5:1 B5:1 D6:1 E6:1  C6:.5 B5:.5 A5:1 E5:1 A5:1  B5:2 G#5:2"),
        }, style="drive")

    if want("music_boss_mower"):
        song("music_boss_mower", 164, {
            "A": (["Cm", "Ab", "Bb", "G", "Cm", "Ab", "Fm", "G"],
                  "C5:.5 Eb5:.5 G5:.5 C6:1.5 Bb5:.5 G5:.5  Ab5:1 G5:.5 F5:.5 Eb5:1 C5:1  "
                  "D5:.5 F5:.5 Bb5:.5 D6:1.5 C6:.5 Bb5:.5  B5:1 D6:1 G5:2  "
                  "C6:.5 Bb5:.5 G5:.5 Eb5:.5 C5:1 Eb5:1  F5:.5 Eb5:.5 C5:.5 Ab4:.5 C5:1 Eb5:1  "
                  "F5:.5 G5:.5 Ab5:1 G5:.5 F5:.5 C5:1  D5:.5 Eb5:.5 F5:.5 G5:.5 B5:2"),
            "B": (["Ab", "Bb", "Cm", "Cm", "Fm", "G", "Cm", "G"],
                  "Eb5:1 Ab5:1 C6:1.5 Bb5:.5  D5:1 F5:1 Bb5:1.5 Ab5:.5  G5:.5 C6:.5 Eb6:1 D6:.5 C6:.5 G5:1  "
                  "C6:3 R:1  F5:.5 Ab5:.5 C6:1 Bb5:.5 Ab5:.5 F5:1  G5:.5 B5:.5 D6:1 C6:.5 B5:.5 G5:1  "
                  "Eb5:.5 G5:.5 C6:1 Eb6:1 D6:1  B5:2 G5:2"),
        }, style="gallop", lead_duty=0.5)

    if want("music_boss_bruno"):
        song("music_boss_bruno", 172, {
            "A": (["Gm", "Eb", "F", "D", "Gm", "Eb", "Cm", "D"],
                  "G5:.5 G5:.5 Bb5:.5 G5:.5 D6:1 Bb5:1  Eb5:.5 Eb5:.5 G5:.5 Eb5:.5 Bb5:1 G5:1  "
                  "F5:.5 F5:.5 A5:.5 F5:.5 C6:1 A5:1  F#5:1 A5:1 D6:2  "
                  "G5:.5 Bb5:.5 D6:.5 Bb5:.5 G5:1 D5:1  Eb5:.5 G5:.5 Bb5:.5 G5:.5 Eb5:1 Bb4:1  "
                  "C5:.5 Eb5:.5 G5:.5 C6:.5 Eb6:1 C6:1  D6:1 C6:.5 A5:.5 F#5:2"),
            "B": (["Eb", "F", "Gm", "Gm", "Cm", "D", "Gm", "D"],
                  "Bb5:1 G5:1 Eb5:1 Bb5:1  C6:1 A5:1 F5:1 C6:1  D6:1.5 C6:.5 Bb5:1 G5:1  D6:3 R:1  "
                  "Eb6:1 C6:1 G5:1 Eb5:1  F#5:1 A5:1 C6:1 D6:1  Bb5:.5 A5:.5 G5:1 D5:1 G5:1  A5:2 F#5:2"),
        }, style="drive", lead_duty=0.5)

    if want("music_menu"):
        # Main menu: the apartment tune, calmer and without drums.
        song("music_menu", 100, {
            "A": (["C", "Am", "F", "G", "C", "Am", "F", "G"],
                  "E5:1 G5:1 C6:2  C6:1 A5:1 E5:2  F5:1 A5:1 C6:1.5 A5:.5  G5:4  "
                  "E5:1 G5:1 C6:1 D6:1  E6:1 C6:1 A5:2  F5:1 E5:.5 D5:.5 C5:1 D5:1  G4:4"),
            "B": (["F", "G", "Em", "Am", "F", "G", "C", "C"],
                  "A5:1.5 G5:.5 F5:2  B5:1.5 A5:.5 G5:2  G5:1 E5:1 B4:2  C5:1 E5:1 A5:2  "
                  "A5:1 C6:1 F6:2  D6:1 B5:1 G5:2  E5:1 G5:1 C6:2  C6:4"),
        }, style="bounce", drums=False, lead_kind="tri", lead_duty=0.5, gain=1.3)

    if want("music_devil"):
        # Slow and heavy, a tritone at its heart.
        song("music_devil", 84, {
            "A": (["Cm", "Cm", "Gb", "Gb", "Cm", "Cm", "G", "G"],
                  "C5:2 Eb5:1 Gb5:1  G5:2 Gb5:2  Gb5:1 Eb5:1 Db5:1 C5:1  Db5:4  "
                  "C5:1 C6:1 Bb5:1 G5:1  Gb5:2 Eb5:2  D5:1 F5:1 Ab5:1 B5:1  B5:3 R:1"),
            "B": (["Ab", "G", "Cm", "Cm", "Ab", "G", "Gb", "G"],
                  "Ab5:2 C6:1 Eb6:1  D6:2 B5:2  C6:1 G5:1 Eb5:1 C5:1  C5:3 R:1  "
                  "Eb6:1 C6:1 Ab5:1 Eb5:1  D5:1 G5:1 B5:1 D6:1  Db6:2 Gb5:2  G5:3 R:1"),
        }, style="drive", lead_kind="saw", lead_duty=0.5, gain=1.2)


if __name__ == "__main__":
    # `python tools/gen_audio.py music_garden music_boss` rebuilds only those.
    names = sys.argv[1:]
    if not names:
        sfx()
    music(set(names) if names else None)
    print("written to", OUT)
