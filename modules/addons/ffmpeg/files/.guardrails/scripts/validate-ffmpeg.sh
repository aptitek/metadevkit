#!/usr/bin/env bash
# =============================================================================
# validate-ffmpeg.sh — FFmpeg / ffprobe Subprocess Security Gate (addon:ffmpeg)
# Enforces zero shell=True and zero os.system() in Python media pipelines.
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' py_file; do
  if [[ "${py_file}" == *"/src/"* || "${py_file}" == "src/"* ]]; then
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- 'shell[[:space:]]*=[[:space:]]*True|\bos\.system\s*\(' >/dev/null 2>&1; then
      echo "❌ [FFMPEG GATE] ${py_file}: 'shell=True' or 'os.system()' is forbidden in media pipelines. Pass an explicit argv list to subprocess.run or asyncio.create_subprocess_exec." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" -o -name ".guardrails" -o -name "modules" \) -prune \
  -o -type f -name "*.py" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [FFMPEG GATE] Failed with ${ERRORS} FFmpeg security violation(s)." >&2
  exit 1
fi

echo "✅ [FFMPEG GATE] FFmpeg subprocess security checks passed."
