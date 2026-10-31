---
name: ffmpeg-expert
description: "Run safe, non-blocking FFmpeg/ffprobe audio and TTS post-processing pipelines in Python (zero shell=True, -16 LUFS loudnorm)."
---

# FFmpeg & Audio Post-Processing (`ffmpeg-expert`)

## 1. Hard Media Pipeline Rules
| Gate | Requirement |
| :--- | :--- |
| **Subprocess Safety** | Always pass an explicit `list[str]` to `subprocess.run(..., check=True)` or `asyncio.create_subprocess_exec`. **`shell=True` is strictly forbidden** (Ruff `S602`). |
| **Event-Loop Safety** | In async UIs (Flet/NiceGUI), run FFmpeg via `asyncio.create_subprocess_exec` or `run.io_bound`—never block the main event loop. |
| **Loudness Standard** | Normalize synthesized TTS/podcast audio to `-16 LUFS` (`-af loudnorm=I=-16:TP=-1.5:LRA=11`). |
| **Temp File Hygiene** | Use `tempfile.TemporaryDirectory()` for intermediate `.wav` chunks so cleanup is guaranteed on error. |

## 2. Canonical Loudness Normalization
```python
import subprocess
from pathlib import Path


def normalize_lufs(src: Path, dst: Path) -> None:
    cmd = ["ffmpeg", "-y", "-i", str(src), "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-ar", "48000", str(dst)]
    subprocess.run(cmd, check=True, capture_output=True)
```

## 3. Deep References (Load On-Demand Only)
- Async `ffprobe` JSON metadata inspection and multi-clip TTS concat demuxer: [references/audio-pipelines.md](./references/audio-pipelines.md)
