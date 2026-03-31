# Audio Analysis Methods

Three approaches for analyzing a track before building choreography.

## Option A: ffmpeg (fast, works on any machine)

```bash
# Get track duration
ffprobe -v error -show_entries format=duration -of csv=p=0 track.wav

# Generate a waveform image — the single most useful visual reference
# Width of 3000px means ~1px per 100ms for a 5min track
ffmpeg -i track.wav -filter_complex "showwavespic=s=3000x200:colors=white" -frames:v 1 waveform.png

# Generate RMS energy over time (one value per audio frame)
ffmpeg -i track.wav -af astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level -f null - 2>&1 | grep RMS_level > energy.txt

# Generate a spectrogram — shows frequency content over time
# Useful for distinguishing builds (rising freq) from drops (full spectrum)
ffmpeg -i track.wav -lavfi showspectrumpic=s=3000x400 spectrogram.png
```

Open `waveform.png` and `spectrogram.png` side by side. The waveform shows you
**when** energy changes. The spectrogram shows you **what kind** of energy changes
(bass drop vs. hi-hat entrance vs. pad swell).

## Option B: Web Audio OfflineAudioContext (programmatic)

```javascript
async function analyzeTrack(file) {
  const arrayBuffer = await file.arrayBuffer();
  const audioCtx = new AudioContext();
  const buffer = await audioCtx.decodeAudioData(arrayBuffer);
  const samples = buffer.getChannelData(0); // mono or left channel
  const sampleRate = buffer.sampleRate;

  const hopSize = Math.floor(sampleRate * 0.1); // 100ms windows
  const events = [];

  for (let i = 0; i < samples.length; i += hopSize) {
    const end = Math.min(i + hopSize, samples.length);
    let rms = 0, peak = 0, zeroCrossings = 0;

    for (let j = i; j < end; j++) {
      const s = Math.abs(samples[j]);
      rms += samples[j] * samples[j];
      if (s > peak) peak = s;
      if (j > i && (samples[j] >= 0) !== (samples[j-1] >= 0)) zeroCrossings++;
    }

    rms = Math.sqrt(rms / (end - i));
    const brightness = zeroCrossings / (end - i); // proxy for spectral centroid

    events.push({
      time: i / sampleRate,
      rms,           // overall loudness
      peak,          // transient detection
      brightness     // high = hi-hats/cymbals, low = bass/pads
    });
  }

  audioCtx.close();
  return { events, duration: buffer.duration, sampleRate };
}
```

## Option C: Python with librosa (most precise)

```bash
pip install librosa numpy
```

```python
import librosa
import numpy as np

y, sr = librosa.load('track.wav', sr=22050, mono=True)
duration = librosa.get_duration(y=y, sr=sr)

# Onset detection — finds percussive hits
onset_frames = librosa.onset.onset_detect(y=y, sr=sr, units='frames')
onset_times = librosa.frames_to_time(onset_frames, sr=sr)

# Beat tracking
tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
beat_times = librosa.frames_to_time(beat_frames, sr=sr)

# RMS energy over time
rms = librosa.feature.rms(y=y, frame_length=2048, hop_length=512)[0]
rms_times = librosa.frames_to_time(range(len(rms)), sr=sr, hop_length=512)

# Spectral centroid (brightness)
centroid = librosa.feature.spectral_centroid(y=y, sr=sr, hop_length=512)[0]

# Chromagram (harmonic content — useful for detecting key changes)
chroma = librosa.feature.chroma_stft(y=y, sr=sr, hop_length=512)

print(f"Duration: {duration:.1f}s")
print(f"BPM: {tempo:.1f}")
print(f"Beats: {len(beat_times)}")
print(f"Onsets: {len(onset_times)}")
print(f"\nFirst 20 onset times:")
for t in onset_times[:20]:
    print(f"  {t:.2f}s")
```

## BPM Detection and Beat Grid

If the track has a steady beat, snapping phase boundaries to bar lines makes
choreography feel musical rather than arbitrary.

```javascript
function detectBPM(events, minBPM = 60, maxBPM = 180) {
  const energies = events.map(e => e.rms);
  const dt = events[1].time - events[0].time;
  const minLag = Math.floor(60 / (maxBPM * dt));
  const maxLag = Math.floor(60 / (minBPM * dt));

  let bestLag = minLag, bestCorr = -1;
  for (let lag = minLag; lag <= maxLag; lag++) {
    let corr = 0;
    for (let i = 0; i < energies.length - lag; i++) {
      corr += energies[i] * energies[i + lag];
    }
    if (corr > bestCorr) { bestCorr = corr; bestLag = lag; }
  }
  return 60 / (bestLag * dt);
}
```

### Bar grid reference

```
BPM: 128 → 1 beat = 0.469s, 1 bar (4/4) = 1.875s
BPM: 80  → 1 beat = 0.750s, 1 bar (4/4) = 3.000s
BPM: 140 → 1 beat = 0.429s, 1 bar (4/4) = 1.714s

Common section lengths:
  4 bars  = intro/outro, breakdown
  8 bars  = verse, build
  16 bars = chorus, main section
  32 bars = extended section
```

Snap section boundaries to the nearest bar line. Drops almost always land on
beat 1 of a bar. Phase transitions sound best on bar boundaries.

## Baked Energy Envelope (Optional, for Tight Sync)

For demos where choreography must perfectly track audio energy — beyond what
real-time FFT can provide — bake the energy envelope into a 1D texture:

```javascript
const energyData = new Uint8Array(events.map(e => Math.min(255, e.rms * 512)));
const energyTex = gl.createTexture();
gl.bindTexture(gl.TEXTURE_2D, energyTex);
gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, energyData.length, 1, 0,
              gl.RED, gl.UNSIGNED_BYTE, energyData);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
```

Sample in the shader:

```glsl
uniform sampler2D energyTex;
uniform float trackDuration;
float bakedEnergy = texture(energyTex, vec2(t / trackDuration, 0.5)).r;
```

This is deterministic and frame-rate independent — no FFT latency, no device
variance. Use it for geometry and camera (must be rock-solid). Layer real-time FFT
on top for materials (benefits from organic variance).

Pack bass/mid/treble/overall into RGBA for a full 4-band deterministic energy texture.
