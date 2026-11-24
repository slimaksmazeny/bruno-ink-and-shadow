# Generates simple placeholder SFX (22.05 kHz mono 16-bit WAV).
import numpy as np, wave, os, sys
SR = 22050
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(7)
def t(d): return np.linspace(0, d, int(SR*d), endpoint=False)
def env(n, a=0.005, r=None):
    e = np.ones(n); ai = max(1,int(a*SR)); e[:ai] = np.linspace(0,1,ai)
    rr = n-ai if r is None else int(r*SR)
    e[-rr:] *= np.linspace(1,0,rr)**2
    return e
def sweep(f0, f1, d, wave_="sine"):
    tt = t(d); f = np.geomspace(f0, f1, len(tt)); ph = 2*np.pi*np.cumsum(f)/SR
    if wave_ == "square": return np.sign(np.sin(ph))*0.6
    if wave_ == "tri": return 2/np.pi*np.arcsin(np.sin(ph))
    return np.sin(ph)
def noise(d): return rng.uniform(-1,1,int(SR*d))
def lowpass(x, k):
    y = np.zeros_like(x); a = 0.0
    for i,v in enumerate(x): a += k*(v-a); y[i] = a
    return y
def tone(f, d, partials=((1,1),)):
    tt = t(d); return sum(a*np.sin(2*np.pi*f*m*tt) for m,a in partials)
def save(name, x, gain=0.8):
    x = x/ (np.max(np.abs(x))+1e-9) * gain
    data = (x*32767).astype(np.int16)
    with wave.open(os.path.join(out, name+".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
x = sweep(260, 620, 0.13, "tri"); save("jump", x*env(len(x), r=0.08), 0.55)
x = sweep(420, 980, 0.16, "tri"); save("double_jump", x*env(len(x), r=0.1), 0.55)
x = lowpass(noise(0.09), 0.08) + 0.6*sweep(140, 60, 0.09); save("land", x*env(len(x), a=0.001), 0.6)
n = noise(0.16); k = np.linspace(0.05, 0.5, len(n)); y=np.zeros_like(n); a=0
for i,v in enumerate(n): a += k[i]*(v-a); y[i]=a
save("swish", y*np.sin(np.linspace(0,np.pi,len(y))), 0.6)
x = 0.8*sweep(220, 70, 0.12) + 0.6*lowpass(noise(0.12), 0.3); save("hit", x*env(len(x), a=0.001), 0.85)
x = np.concatenate([tone(1320,0.06,((1,1),(2,0.3))), tone(1980,0.12,((1,1),(2,0.3)))]); save("pickup", x*env(len(x), r=0.1), 0.5)
tt=t(0.4); f = 180*(1+0.9*np.exp(-tt*6)*np.sin(2*np.pi*14*tt)) + 220*tt; x = np.sin(2*np.pi*np.cumsum(f)/SR); save("bounce", x*env(len(x), r=0.25), 0.6)
x = lowpass(noise(0.07), 0.4) + sweep(600, 200, 0.07); save("shoot", x*env(len(x), a=0.001), 0.6)
tt=t(1.2); x = sum(a*np.sin(2*np.pi*880*m*tt)*np.exp(-tt*dk) for m,a,dk in ((1,1,3),(2.76,0.5,5),(5.4,0.3,8),(0.5,0.4,2))); save("bell", x*env(len(x),a=0.002,r=0.2), 0.6)
x = sweep(500, 140, 0.28, "square"); save("hurt", x*env(len(x), r=0.15), 0.5)
x = np.concatenate([tone(f,0.09,((1,1),(3,0.2))) for f in (523,659,784,1047)]); save("checkpoint", x*env(len(x), r=0.2), 0.5)
x = tone(700, 0.04); save("ui_move", x*env(len(x), r=0.03), 0.35)
x = np.concatenate([tone(660,0.05), tone(990,0.08)]); save("ui_accept", x*env(len(x), r=0.06), 0.4)
x = np.concatenate([tone(990,0.05), tone(660,0.08)]); save("ui_back", x*env(len(x), r=0.06), 0.4)
x = np.concatenate([tone(1400,0.07,((1,1),(2,.4))), np.zeros(800), tone(1800,0.12,((1,1),(2,.4)))]); save("alert", x*env(len(x), r=0.08), 0.55)
x = sweep(300, 520, 0.3, "tri"); save("suspicious", x*env(len(x), r=0.2), 0.4)
x = lowpass(noise(0.3), 0.25) * np.exp(-t(0.3)*12) + 0.5*sweep(160,50,0.3)*np.exp(-t(0.3)*10); save("crate_break", x, 0.8)
x = lowpass(noise(0.6), 0.05) + 0.4*sweep(90, 60, 0.6); save("gate", x*env(len(x), a=0.05, r=0.3), 0.6)
x = sweep(200, 900, 0.5) * np.exp(-t(0.5)*2) + 0.3*lowpass(noise(0.5),0.1); save("portal", x*env(len(x), a=0.02, r=0.2), 0.5)
x = np.concatenate([tone(392,0.12),tone(330,0.12),tone(262,0.3)]); save("death", x*env(len(x), r=0.25), 0.5)
x = lowpass(noise(0.35), 0.15) * np.sin(np.linspace(0,np.pi,int(SR*0.35)))**2; save("glide", x, 0.35)
x = lowpass(noise(0.05), 0.35) * np.exp(-t(0.05)*60) + 0.3*sweep(220, 120, 0.05)*np.exp(-t(0.05)*50); save("step", x, 0.45)
print("ok", sorted(os.listdir(out)))
