#!/usr/bin/env bash
# =============================================================================
# validate-testing-fortress.sh — Polyglot Lock 6 Test Assertion Purity Gate
# Enforces across TypeScript, Python (via `ast`), Java, Kotlin, and PHP:
#   1. Zero skipped or focused tests (.skip, .only, @pytest.mark.skip,
#      pytest.skip, @Disabled, xit, xdescribe, ->skip(), ->only())
#   2. Zero tautological or weak assertions (toBeTruthy, toBeFalsy,
#      toMatchSnapshot, vi.mock, assert True, assertTrue(true))
#   3. 1:1 TDD unit test companions for TypeScript modules
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

# 1. Run TypeScript 1:1 TDD companion check when node and TS sources exist
if command -v node >/dev/null 2>&1 && [[ -f "${ROOT_DIR}/.guardrails/scripts/lint-tdd-companions.mjs" ]]; then
  if [[ -d "${ROOT_DIR}/src" ]] && find "${ROOT_DIR}/src" -type f \( -name "*.ts" -o -name "*.tsx" \) -print -quit | grep -q .; then
    (cd "${ROOT_DIR}" && node ./.guardrails/scripts/lint-tdd-companions.mjs) || ERRORS=$((ERRORS + 1))
  fi
fi

# 2. Scan TypeScript / JavaScript test files (*.test.ts*, *.spec.ts*)
SKIP_TS_RE='\b(it|test|describe)\.(skip|only)\s*\('
WEAK_TS_RE='\.(toBeTruthy|toBeFalsy|toMatchSnapshot)\s*\(|\b(vi|jest)\.mock\s*\('

while IFS= read -r -d '' ts_test; do
  if grep -vE '^[[:space:]]*//' "${ts_test}" | grep -E "${SKIP_TS_RE}" >/dev/null 2>&1; then
    echo "❌ [TESTING FORTRESS] ${ts_test}: Skipped (.skip) or focused (.only) test detected." >&2
    ERRORS=$((ERRORS + 1))
  fi
  if grep -vE '^[[:space:]]*//' "${ts_test}" | grep -E "${WEAK_TS_RE}" >/dev/null 2>&1; then
    echo "❌ [TESTING FORTRESS] ${ts_test}: Weak assertion (toBeTruthy/toBeFalsy/toMatchSnapshot) or module mock (vi.mock) detected." >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name "dist" -o -name "build" -o -name ".guardrails" -o -name "modules" \) -prune \
  -o -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -print0)

# 3. AST-based Python Test Purity Analysis (tests/**/test_*.py, tests/**/*_test.py)
if [[ -d "${ROOT_DIR}/tests" ]]; then
  if ! python3 - "${ROOT_DIR}/tests" <<'PYEOF'
import ast
import pathlib
import sys

tests_root = pathlib.Path(sys.argv[1])
SKIP_ATTRS = {"skip", "skipif", "skipTest"}


def is_skip_expr(node: ast.AST) -> bool:
    target = node.func if isinstance(node, ast.Call) else node
    if isinstance(target, ast.Attribute) and target.attr in SKIP_ATTRS:
        return True
    if isinstance(target, ast.Name) and target.id in SKIP_ATTRS:
        return True
    return False


def is_tautological_node(node: ast.AST) -> bool:
    if isinstance(node, ast.Assert):
        if isinstance(node.test, ast.Constant):
            return True
        if (
            isinstance(node.test, ast.Compare)
            and len(node.test.comparators) == 1
            and isinstance(node.test.left, ast.Constant)
            and isinstance(node.test.comparators[0], ast.Constant)
            and node.test.left.value == node.test.comparators[0].value
        ):
            return True
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
        if node.func.attr in ("assertTrue", "assertFalse") and node.args:
            if isinstance(node.args[0], ast.Constant):
                return True
    return False


errors = 0
for py_test in sorted(tests_root.rglob("*.py")):
    if "__pycache__" in py_test.parts or ".pytest_cache" in py_test.parts:
        continue
    if not (py_test.name.startswith("test_") or py_test.name.endswith("_test.py")):
        continue
    try:
        tree = ast.parse(py_test.read_text(encoding="utf-8", errors="replace"), filename=str(py_test))
    except SyntaxError as exc:
        sys.stderr.write(f"❌ [TESTING FORTRESS] {py_test}:{exc.lineno}: SyntaxError: {exc.msg}\n")
        errors += 1
        continue

    has_skip = False
    has_tautology = False
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if any(is_skip_expr(dec) for dec in node.decorator_list):
                has_skip = True
        elif isinstance(node, ast.Call) and is_skip_expr(node):
            has_skip = True
        if is_tautological_node(node):
            has_tautology = True

    if has_skip:
        sys.stderr.write(f"❌ [TESTING FORTRESS] {py_test}: Skipped test (@pytest.mark.skip / unittest.skip) is forbidden.\n")
        errors += 1
    if has_tautology:
        sys.stderr.write(f"❌ [TESTING FORTRESS] {py_test}: Tautological assertion (assert True / assertTrue(True)) is forbidden.\n")
        errors += 1

sys.exit(1 if errors > 0 else 0)
PYEOF
  then
    ERRORS=$((ERRORS + 1))
  fi
fi

# 4. Scan JVM (Java / Kotlin) test files (src/test/**/*.java, src/test/**/*.kt)
SKIP_JVM_RE='@Disabled\b|\b(xit|xdescribe|xcontext)\s*\('
TAUT_JVM_RE='\bassert(True|False)\s*\(\s*(true|false)\s*\)|\bshouldBe\s+true\b.*\btrue\b'

if [[ -d "${ROOT_DIR}/src/test" ]]; then
  while IFS= read -r -d '' jvm_test; do
    if grep -vE '^[[:space:]]*//' "${jvm_test}" | grep -E "${SKIP_JVM_RE}" >/dev/null 2>&1; then
      echo "❌ [TESTING FORTRESS] ${jvm_test}: Disabled/skipped JVM test (@Disabled / xit / xdescribe) is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -vE '^[[:space:]]*//' "${jvm_test}" | grep -E "${TAUT_JVM_RE}" >/dev/null 2>&1; then
      echo "❌ [TESTING FORTRESS] ${jvm_test}: Tautological JVM assertion (assertTrue(true) / assertFalse(false)) is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/src/test" -type f \( -name "*.java" -o -name "*.kt" \) -print0)
fi

# 5. Scan PHP Pest / PHPUnit test files (tests/**/*Test.php)
SKIP_PHP_RE='->(skip|only)\s*\(|\bmarkTestSkipped\s*\('

if [[ -d "${ROOT_DIR}/tests" ]]; then
  while IFS= read -r -d '' php_test; do
    if grep -vE '^[[:space:]]*//' "${php_test}" | grep -E -- "${SKIP_PHP_RE}" >/dev/null 2>&1; then
      echo "❌ [TESTING FORTRESS] ${php_test}: Skipped or focused PHP test (->skip() / ->only() / markTestSkipped) is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/tests" -type f -name "*Test.php" -print0)
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [TESTING FORTRESS] Failed with ${ERRORS} Lock 6 test purity violation(s)." >&2
  exit 1
fi

echo "✅ [TESTING FORTRESS] Polyglot Lock 6 test assertion purity verified."
