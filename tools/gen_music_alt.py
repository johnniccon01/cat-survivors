"""Generates the maps' second day tracks (see ALT_TRACKS).

Each map has an alternative track in a completely different style (waltz,
swing, synthwave, reggae) with its own instruments, so runs don't all sound
alike; the game picks one of the two per run. The melodies are composed from
a motif per section: one rhythm is repeated with the notes following the
chords.

    python tools/gen_music_alt.py                      # all of them
    python tools/gen_music_alt.py music_garden_alt     # only that one
"""
import math
import random
import sys

from gen_audio import (DRUM_HAT, DRUM_KICK, DRUM_OPEN, DRUM_SNARE, NOTE, OUT, SR,
                       Track, hz, lowpass, note, save)

SCALES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10]}
## Two-bar rhythms in beats; a negative value is a rest.
RHYTHMS = {
    "waltz": [[1.5, .5, 1, 2, 1], [1, 1, 1, 2, -1], [.5, .5, 1, 1, 3], [2, 1, 1.5, .5, 1]],
    "swing": [[.5, .5, 1, .5, 1.5, 1, 1, 2], [-.5, .5, .5, .5, 1, 1, 3, 1], [1, .5, .5, 1, 1, .5, .5, 1, 2]],
    "synth": [[2, 1, 1, 4], [1.5, 1.5, 1, 3, 1], [1, 1, 2, 2, 2]],
    "skank": [[1, .5, .5, 1, 1, .5, .5, 1, 2], [-1, 1, 1, 1, 1.5, .5, 2], [.5, .5, 1, 2, 1, 1, 2]],
}
RANGES = {"waltz": (67, 86), "swing": (62, 81), "synth": (62, 79), "skank": (64, 83)}


def chord_tones(c):
    """'Am7' -> (root 0-11, [chord tones as semitones above C])."""
    q, root = "", c
    for suf in ("maj7", "m7", "7", "m"):
        if c.endswith(suf) and c[:-len(suf)].upper() in NOTE:
            q, root = suf, c[:-len(suf)]
            break
    r = NOTE[root.upper()]
    tones = [r, r + (3 if q in ("m", "m7") else 4), r + 7]
    if q == "maj7":
        tones.append(r + 11)
    elif q in ("7", "m7"):
        tones.append(r + 10)
    return r, tones


def pluck(dur, f, vol=0.2, decay=0.35, bright=0.5):
    """A plucked / music-box note: sine plus overtones, dying away."""
    n = max(int(dur * SR), 1)
    w = 2.0 * math.pi * f / SR
    out = []
    for i in range(n):
        env = math.exp(-i / (decay * SR)) * min(1.0, i / 40.0) * min(1.0, (n - i) / 200.0)
        out.append((math.sin(w * i) + bright * math.sin(2 * w * i) + 0.25 * bright * math.sin(3 * w * i)) * vol * env)
    return out


def pad(dur, f, vol=0.05):
    """Two slightly detuned saws with a slow swell (lowpassed later)."""
    n = max(int(dur * SR), 1)
    out = []
    p1 = p2 = 0.0
    for i in range(n):
        p1 += f * 1.004 / SR
        p2 += f * 0.996 / SR
        env = min(1.0, i / (0.25 * SR)) * min(1.0, (n - i) / (0.3 * SR))
        out.append(((p1 % 1.0) + (p2 % 1.0) - 1.0) * vol * env)
    return out


def scaled(samples, k):
    return [v * k for v in samples]


def compose(rng, chords, bpb, key, scale, rhythms, lo, hi):
    """A melody over `chords` as (midi or None, beats) pairs."""
    pitches = [m for m in range(lo, hi + 1) if (m - key) % 12 in scale]
    motif = rhythms[rng.randrange(len(rhythms))]
    twist = rhythms[rng.randrange(len(rhythms))]
    out = []
    prev = (lo + hi) // 2
    pairs = len(chords) // 2
    for pair in range(pairs):
        beat = 0.0
        for d in (twist if pair == pairs - 1 else motif):
            if d < 0:
                out.append((None, -d))
                beat += -d
                continue
            bar = pair * 2 + int(beat // bpb)
            _, tones = chord_tones(chords[min(bar, len(chords) - 1)])
            if beat % 1.0 == 0.0 and (beat % bpb == 0.0 or d >= 1.0):
                cands = [m for m in pitches if m % 12 in [t % 12 for t in tones]]
            else:
                i = min(range(len(pitches)), key=lambda k: abs(pitches[k] - prev))
                cands = [pitches[max(0, min(len(pitches) - 1, i + s))] for s in (-2, -1, 1, 2)]
            cands.sort(key=lambda m: abs(m - prev) + rng.random() * 3.0)
            prev = cands[0]
            out.append((prev, d))
            beat += d
        assert abs(beat - 2 * bpb) < 1e-6, (beat, bpb)
    # Each section ends on the last chord's root.
    root = chord_tones(chords[-1])[0]
    roots = [m for m in pitches if m % 12 == root % 12]
    if roots and out[-1][0] is not None:
        out[-1] = (min(roots, key=lambda m: abs(m - prev)), out[-1][1])
    return out


def song2(name, bpm, groove, key, mode, sections, order=("A", "B", "A+", "B+", "C~", "C+", "A+", "B+"), seed=1, gain=1.45):
    """`sections`: name -> chord list; `groove` picks the whole arrangement.
    In `order` a "+" adds the extra voice, "~" is a quiet breakdown."""
    rng = random.Random(seed)
    bpb = 3 if groove == "waltz" else 4
    beat = 60.0 / bpm
    bar = beat * bpb
    lo, hi = RANGES[groove]
    melodies = {k: compose(rng, ch, bpb, key, SCALES[mode], RHYTHMS[groove], lo, hi) for k, ch in sections.items()}
    total = sum(len(sections[e.rstrip("+~")]) for e in order) * bar
    lead = Track(total)
    back = Track(total)
    soft = Track(total)  # pads and warm bass, lowpassed hard at the end
    t0 = 0.0
    for entry in order:
        name_ = entry.rstrip("+~")
        harmony, calm = "+" in entry, "~" in entry
        chords = sections[name_]
        for ci, c in enumerate(chords):
            r, tones = chord_tones(c)
            bt = t0 + ci * bar
            if groove == "waltz":
                # Oom-pah-pah: a low pluck, then two soft chord plucks.
                back.add(pluck(bar * 0.9, hz(36 + r), 0.3, 0.5, 0.2), bt)
                soft.add(pad(bar, hz(48 + tones[1]), 0.035), bt)
                if not calm:
                    for k in (1, 2):
                        for t in tones[:3]:
                            back.add(pluck(beat * 0.8, hz(60 + t), 0.045, 0.18, 0.3), bt + k * beat)
                    back.add(DRUM_HAT, bt)
                    back.add(scaled(DRUM_HAT, 0.6), bt + beat)
                    back.add(scaled(DRUM_HAT, 0.6), bt + 2 * beat)
                    if ci % 2 == 0:
                        back.add(scaled(DRUM_KICK, 0.5), bt)
                if harmony:  # a music-box arpeggio on top
                    arp = [72 + tones[0], 72 + tones[1], 72 + tones[2], 84 + tones[0], 72 + tones[2], 72 + tones[1]]
                    for k in range(6):
                        back.add(pluck(beat * 0.5, hz(arp[k]), 0.04, 0.25, 0.1), bt + k * beat * 0.5)
            elif groove == "swing":
                # Walking bass, offbeat chord stabs, swung hi-hats.
                walk = [r, tones[1], tones[2], r + 9]
                if ci % 2:
                    walk[3] = chord_tones(chords[(ci + 1) % len(chords)])[0] - 1
                for k in range(4):
                    m = 36 + walk[k] % 12 + (12 if walk[k] % 12 < 4 else 0)
                    soft.add(note(beat * 0.8, hz(m), "saw", 0.16, release=0.06), bt + k * beat)
                    back.add(note(beat * 0.6, hz(m), "tri", 0.2, release=0.05), bt + k * beat)
                if not calm:
                    for k in (1, 3):
                        for t in tones:
                            back.add(note(beat * 0.3, hz(60 + t % 12), "square", 0.018, duty=0.5, release=0.04), bt + k * beat + beat * 2.0 / 3.0)
                    for k in range(4):
                        back.add(DRUM_OPEN if k % 2 else DRUM_HAT, bt + k * beat)
                        back.add(scaled(DRUM_HAT, 0.5), bt + k * beat + beat * 2.0 / 3.0)
                        back.add(scaled(DRUM_KICK, 0.8) if k in (0, 2) else scaled(DRUM_SNARE, 0.7), bt + k * beat)
                else:
                    for t in tones:
                        soft.add(pad(bar, hz(60 + t % 12), 0.03), bt)
            elif groove == "synth":
                # Pulsing octave bass, a big pad, four-on-the-floor.
                for t in tones[:3]:
                    soft.add(pad(bar, hz(60 + t), 0.045), bt)
                soft.add(pad(bar, hz(48 + r), 0.05), bt)
                for k in range(8):
                    back.add(note(beat * 0.4, hz(36 + r + (12 if k % 2 else 0)), "square", 0.07 if calm else 0.11, duty=0.5, release=0.03), bt + k * beat * 0.5)
                if not calm:
                    for k in range(4):
                        back.add(DRUM_KICK, bt + k * beat)
                        back.add(DRUM_OPEN, bt + k * beat + beat * 0.5)
                        if k in (1, 3):
                            back.add(DRUM_SNARE, bt + k * beat)
                if harmony:
                    arp = [72 + tones[0], 72 + tones[2], 84 + tones[0], 72 + tones[1]]
                    for k in range(8):
                        back.add(note(beat * 0.45, hz(arp[k % 4]), "sine", 0.05, release=0.1), bt + k * beat * 0.5)
            else:  # skank: reggae offbeat chords, bubbling bass, one-drop drums
                back.add(note(beat * 1.4, hz(36 + r), "tri", 0.34, release=0.1), bt)
                back.add(note(beat * 0.45, hz(36 + r + 7), "tri", 0.3, release=0.05), bt + beat * 2.5)
                back.add(note(beat * 0.45, hz(48 + r), "tri", 0.28, release=0.05), bt + beat * 3.0)
                for k in range(4):
                    for t in tones[:3]:
                        back.add(note(beat * 0.22, hz(60 + t), "square", 0.02 if calm else 0.03, duty=0.25, release=0.03), bt + k * beat + beat * 0.5)
                if not calm:
                    for k in range(8):
                        back.add(scaled(DRUM_HAT, 0.9 if k % 2 else 0.5), bt + k * beat * 0.5)
                    back.add(DRUM_KICK, bt + beat * 2)
                    back.add(scaled(DRUM_SNARE, 0.8), bt + beat * 2)
                if harmony:
                    for t in tones[:3]:
                        soft.add(pad(bar, hz(60 + t), 0.025), bt)
        # --- melody, with an echo (and a second voice on "+") ---
        t = t0
        for m, beats in melodies[name_]:
            dur = beats * beat
            if m is not None:
                if groove == "waltz":
                    samples = pluck(dur, hz(m), 0.2, 0.45, 0.45)
                elif groove == "swing":
                    samples = note(dur * 0.9, hz(m), "saw", 0.12, vib=5.0, release=min(0.1, dur * 0.3))
                elif groove == "synth":
                    samples = note(dur * 0.95, hz(m), "square", 0.11, duty=0.5, attack=0.04, vib=4.0, release=min(0.15, dur * 0.3))
                else:
                    samples = note(dur * 0.85, hz(m), "tri", 0.2, vib=6.0, release=min(0.08, dur * 0.3))
                if calm:
                    samples = scaled(samples, 0.6)
                lead.add(samples, t)
                lead.add(scaled(samples, 0.25), t + beat * (1.0 if groove == "waltz" else 0.75))
                if harmony and groove != "waltz":
                    lead.add(note(dur * 0.9, hz(m - (4 if mode == "major" else 3)), "tri", 0.06, release=min(0.08, dur * 0.3)), t)
            t += dur
        t0 += len(chords) * bar
    lead_f = lowpass(list(lead.buf), 0.3 if groove in ("swing", "synth") else 0.6)
    soft_f = lowpass(lowpass(list(soft.buf), 0.08), 0.15)
    save(name, [a + b + c for a, b, c in zip(lead_f, back.buf, soft_f)], gain=gain)


ALT_TRACKS = {
    # Apartment: a sleepy music-box waltz in G.
    "music_apartment_alt": dict(bpm=144, groove="waltz", key=7, mode="major", seed=3, sections={
        "A": ["G", "Em", "C", "D", "G", "Em", "Am", "D"],
        "B": ["C", "D", "Bm", "Em", "C", "Am", "D", "D"],
        "C": ["Em", "C", "G", "D", "Em", "C", "D", "G"]}),
    # Basement: dark, slow synthwave in D minor.
    "music_basement_alt": dict(bpm=96, groove="synth", key=2, mode="minor", seed=5, sections={
        "A": ["Dm", "Bb", "F", "C", "Dm", "Bb", "Gm", "A"],
        "B": ["Gm", "Dm", "Bb", "F", "Gm", "Dm", "A", "A"],
        "C": ["Bb", "C", "Dm", "Dm", "Bb", "C", "A", "A"]}),
    # Garden: lazy sunny reggae in Bb.
    "music_garden_alt": dict(bpm=88, groove="skank", key=10, mode="major", seed=7, sections={
        "A": ["Bb", "Eb", "F", "Bb", "Bb", "Eb", "F", "F"],
        "B": ["Gm", "Eb", "Bb", "F", "Gm", "Eb", "F", "F"],
        "C": ["Eb", "F", "Dm", "Gm", "Eb", "F", "Bb", "Bb"]}),
    # Rooftop: a quick swing in E dorian.
    "music_rooftop_alt": dict(bpm=150, groove="swing", key=4, mode="dorian", seed=11, gain=1.9, sections={
        "A": ["Em7", "A7", "Em7", "A7", "Gmaj7", "C7", "Bm7", "Em7"],
        "B": ["Am7", "D7", "Gmaj7", "Cmaj7", "F#m7", "B7", "Em7", "Em7"],
        "C": ["Cmaj7", "Bm7", "Am7", "D7", "Cmaj7", "Bm7", "Em7", "Em7"]}),
    # Supermarket: lounge "elevator" jazz in C.
    "music_supermarket_alt": dict(bpm=112, groove="swing", key=0, mode="major", seed=13, gain=2.0, sections={
        "A": ["Cmaj7", "Am7", "Dm7", "G7", "Cmaj7", "Am7", "Dm7", "G7"],
        "B": ["Fmaj7", "Em7", "Dm7", "G7", "Em7", "Am7", "D7", "G7"],
        "C": ["Fmaj7", "Fmaj7", "Em7", "Am7", "Dm7", "G7", "Cmaj7", "Cmaj7"]}),
    # Harbor: a rolling sea-shanty waltz in A minor.
    "music_harbor_alt": dict(bpm=138, groove="waltz", key=9, mode="minor", seed=17, sections={
        "A": ["Am", "Am", "G", "G", "F", "F", "E", "E"],
        "B": ["Am", "C", "G", "Am", "F", "G", "E", "Am"],
        "C": ["Dm", "Am", "Dm", "E", "F", "C", "E", "E"]}),
    # Factory: cold industrial synthwave in E minor.
    "music_factory_alt": dict(bpm=124, groove="synth", key=4, mode="minor", seed=19, sections={
        "A": ["Em", "Em", "C", "D", "Em", "Em", "C", "B"],
        "B": ["Am", "C", "Em", "D", "Am", "C", "B", "B"],
        "C": ["C", "D", "Em", "Em", "C", "D", "B", "B"]}),
}


if __name__ == "__main__":
    only = set(sys.argv[1:])
    for track, spec in ALT_TRACKS.items():
        if not only or track in only:
            song2(track, **spec)
    print("written to", OUT)
