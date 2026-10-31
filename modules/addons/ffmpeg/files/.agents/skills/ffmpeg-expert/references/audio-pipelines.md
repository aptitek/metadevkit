# Async `ffprobe` Inspection & Multi-Segment TTS Concatenation

## 1. Probe Audio Metadata (`ffprobe` JSON)
```python
import json
import subprocess
from pathlib import Path


def probe_duration_seconds(audio_path: Path) -> float:
    cmd = [
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "json", str(audio_path),
    ]
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    payload = json.loads(proc.stdout)
    return float(payload["format"]["duration"])
```

## 2. Lossless WAV Concatenation via Concat Demuxer
Write intermediate segment paths to a manifest inside `tempfile.TemporaryDirectory()` and run:
`["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(list_file), "-c", "copy", str(output_wav)]`.
