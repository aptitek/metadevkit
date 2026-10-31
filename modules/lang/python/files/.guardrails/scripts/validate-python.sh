#!/usr/bin/env bash
# =============================================================================
# validate-python.sh — Python 3.12+ AST & Tokenize Quality Gate (lang:python)
# Enforces Geranium Quality Fortress via Python's native `ast` & `tokenize`:
#   1. File length <= 256 lines per .py file
#   2. uv-only dependency management (bans Pipfile, poetry.lock, setup.py)
#   3. Zero linter bypass comments (# noqa, # type: ignore) via `tokenize`
#   4. Zero raw print() calls in src/ via `ast.Call` (with line numbers)
#   5. Zero vague bindings (data, res, temp, info) in src/ (Store, arg,
#      ExceptHandler, MatchAs) with line numbers
#   6. Zero explicit `Any` in src/ (annotations, PEP 695 TypeAlias, cast, imports)
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

# 1. uv-only package management check
for legacy_file in "Pipfile" "Pipfile.lock" "poetry.lock" "setup.py"; do
  if [[ -f "${ROOT_DIR}/${legacy_file}" ]]; then
    echo "❌ [PYTHON GATE] Legacy package manager file '${legacy_file}' detected. Manage all dependencies exclusively with 'uv' (pyproject.toml + uv.lock)." >&2
    ERRORS=$((ERRORS + 1))
  fi
done

# 2. Pure AST + Tokenize analysis across all Python files
if ! python3 -B - "$ROOT_DIR" <<'PYEOF'
import ast
import io
import pathlib
import re
import sys
import tokenize

root = pathlib.Path(sys.argv[1])
PRUNE_DIRS = {
    ".venv",
    "venv",
    "__pycache__",
    ".git",
    ".mypy_cache",
    ".ruff_cache",
    ".pytest_cache",
    ".cache",
    "mutants",
    "build",
    "dist",
    "node_modules",
}
VAGUE_NAMES = {"data", "res", "temp", "info"}
BYPASS_RE = re.compile(r"#\s*(noqa|type:\s*ignore)\b", re.IGNORECASE)


def iter_py_files(base: pathlib.Path) -> list[pathlib.Path]:
    found: list[pathlib.Path] = []
    if not base.exists():
        return found
    for item in sorted(base.rglob("*.py")):
        rel_parts = set(item.relative_to(base).parts)
        if rel_parts & PRUNE_DIRS:
            continue
        if item.is_file():
            found.append(item)
    return found


def check_src_ast(py_file: pathlib.Path, tree: ast.AST) -> int:
    print_lines: list[int] = []
    vague_lines: list[tuple[int, str]] = []
    any_lines: list[int] = []

    for node in ast.walk(tree):
        lineno = getattr(node, "lineno", 0)
        # 1. Raw print() calls
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == "print":
            print_lines.append(lineno)

        # 2. Vague variable / parameter / exception / match bindings
        if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store) and node.id in VAGUE_NAMES:
            vague_lines.append((lineno, node.id))
        elif isinstance(node, ast.arg) and node.arg in VAGUE_NAMES:
            vague_lines.append((lineno, node.arg))
        elif isinstance(node, (ast.ExceptHandler, ast.MatchAs)) and node.name in VAGUE_NAMES:
            vague_lines.append((lineno, node.name))

        # 3. Explicit 'Any' anywhere in src/ (annotations, TypeAlias, cast(Any, ...), Generic[Any], imports)
        if isinstance(node, ast.Name) and node.id == "Any":
            any_lines.append(lineno)
        elif isinstance(node, ast.Attribute) and node.attr == "Any":
            any_lines.append(lineno)
        elif isinstance(node, ast.alias) and (node.name == "Any" or node.asname == "Any"):
            any_lines.append(lineno)

    file_errors = 0
    if print_lines:
        lines_csv = ", ".join(f"L{n}" for n in sorted(set(print_lines)))
        sys.stderr.write(
            f"❌ [PYTHON GATE] {py_file} ({lines_csv}): Raw print() call in src/. "
            "Use logging.getLogger(__name__) instead.\n"
        )
        file_errors += 1
    if vague_lines:
        details = ", ".join(f"'{name}'@L{n}" for n, name in sorted(set(vague_lines)))
        sys.stderr.write(
            f"❌ [PYTHON GATE] {py_file} ({details}): Vague variable name "
            "('data', 'res', 'temp', or 'info') assigned in src/.\n"
        )
        file_errors += 1
    if any_lines:
        lines_csv = ", ".join(f"L{n}" for n in sorted(set(any_lines)))
        sys.stderr.write(
            f"❌ [PYTHON GATE] {py_file} ({lines_csv}): Explicit 'Any' type annotation in src/ is forbidden. "
            "Use concrete types, TypeVar, Protocol, or object.\n"
        )
        file_errors += 1
    return file_errors


total_errors = 0
for py_file in iter_py_files(root):
    source = py_file.read_text(encoding="utf-8", errors="replace")
    line_count = len(source.splitlines())
    if line_count > 256:
        sys.stderr.write(
            f"❌ [PYTHON GATE] {py_file}: File has {line_count} lines (maximum allowed is 256 lines). "
            "Split into smaller, single-responsibility modules.\n"
        )
        total_errors += 1

    try:
        for tok in tokenize.generate_tokens(io.StringIO(source).readline):
            if tok.type == tokenize.COMMENT and BYPASS_RE.search(tok.string):
                sys.stderr.write(
                    f"❌ [PYTHON GATE] {py_file}:{tok.start[0]}: Forbidden linter bypass comment "
                    f"('{tok.string.strip()}') detected via tokenize.\n"
                )
                total_errors += 1
                break
    except tokenize.TokenError:
        pass

    try:
        tree = ast.parse(source, filename=str(py_file))
    except SyntaxError as exc:
        sys.stderr.write(f"❌ [PYTHON GATE] {py_file}:{exc.lineno}: SyntaxError: {exc.msg}\n")
        total_errors += 1
        continue

    rel_str = py_file.as_posix()
    if "/src/" in rel_str or rel_str.startswith("src/"):
        total_errors += check_src_ast(py_file, tree)

sys.exit(1 if total_errors > 0 else 0)
PYEOF
then
  ERRORS=$((ERRORS + 1))
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [PYTHON GATE] Failed with architectural AST violation(s)." >&2
  exit 1
fi

echo "✅ [PYTHON GATE] Python modularity, AST purity & uv architectural gates passed."
