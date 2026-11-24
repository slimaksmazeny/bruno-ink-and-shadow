# Original placeholder music: a sneaky swing loop (walking bass, brushed drums, muted
# vibraphone-like chords). Written from scratch for this project; no melody is copied.
import numpy as np, wave, sys
SR = 22050
BPM = 104
beat = 60.0 / BPM
bars = 8
n = int(SR * beat * 4 * bars)
mix = np.zeros(n)
rng = np.random.default_rng(3)
def note(freq, start, dur, vol, kind="bass"):
    i0 = int(start*SR); L = int(dur*SR)
    if i0 >= n: return
    L = min(L, n - i0)
    t = np.arange(L)/SR
    if kind == "bass":
        w = np.sin(2*np.pi*freq*t) + 0.3*np.sin(4*np.pi*freq*t)
        e = np.exp(-t*3.5) * np.minimum(1, t*200)
    elif kind == "vib":
        w = np.sin(2*np.pi*freq*t) + 0.2*np.sin(2*np.pi*freq*4*t)
        e = np.exp(-t*2.2) * np.minimum(1, t*300) * (1 + 0.15*np.sin(2*np.pi*5*t))
    else:
        w = np.sin(2*np.pi*freq*t); e = np.exp(-t*8)
    mix[i0:i0+L] += vol * w * e
def hit(start, dur, vol, lp):
    i0 = int(start*SR); L = min(int(dur*SR), n - i0)
    if L <= 0: return
    x = rng.uniform(-1,1,L); y = np.zeros(L); a = 0
    for i in range(L): a += lp*(x[i]-a); y[i] = a
    t = np.arange(L)/SR
    mix[i0:i0+L] += vol * y * np.exp(-t*25)
def kick(start):
    i0 = int(start*SR); L = min(int(0.18*SR), n - i0)
    t = np.arange(L)/SR; f = 90*np.exp(-t*18)+45
    mix[i0:i0+L] += 0.55*np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*14)
m2f = lambda m: 440*2**((m-69)/12)
# Minor progression (Dm - Gm - A7 - Dm  x2), walking bass written note by note.
prog = [("D", [50,53,57,60]), ("G", [55,58,62,65]), ("A", [57,61,64,67]), ("D", [50,53,57,62])]
walks = {"D":[38,41,43,44], "G":[43,46,48,49], "A":[45,49,52,51], "D2":[38,45,41,37]}
swing = beat*2/3
for bar in range(bars):
    name, chord = prog[bar % 4]
    key = name if not (bar % 4 == 3) else "D2"
    t0 = bar*4*beat
    for i, m in enumerate(walks[key]):
        note(m2f(m), t0 + i*beat, beat*0.9, 0.42, "bass")
    # Comping: chord stabs on the "and" of 2 and 4 (swung).
    for b in (1, 3):
        for m in chord:
            note(m2f(m+12), t0 + b*beat + swing, beat*1.2, 0.07, "vib")
    # Drums: kick on 1 and 3, brushed snare on 2 and 4, swung ride.
    kick(t0); kick(t0 + 2*beat)
    for b in (1, 3): hit(t0 + b*beat, 0.2, 0.22, 0.25)
    for b in range(4):
        hit(t0 + b*beat, 0.06, 0.08, 0.9)
        hit(t0 + b*beat + swing, 0.05, 0.05, 0.9)
    # A few soft "tiptoe" melody notes every other bar (original motif).
    if bar % 2 == 1:
        motif = [74, 77, 76, 72] if bar % 4 == 1 else [74, 72, 69, 70]
        for i, m in enumerate(motif):
            note(m2f(m), t0 + (i*0.75 + 0.5)*beat, beat*0.6, 0.1, "vib")
mix /= np.max(np.abs(mix)) + 1e-9
mix *= 0.7
data = (mix*32767).astype(np.int16)
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("music seconds:", n/SR)
