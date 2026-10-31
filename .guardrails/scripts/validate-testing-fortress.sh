#!/usr/bin/env bash
# =============================================================================
# validate-testing-fortress.sh — Polyglot Lock 6 Test Assertion Purity Gate
# Enforces across TypeScript, Python, Java, Kotlin, and PHP:
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

# 3. Scan Python test files (tests/**/test_*.py, tests/**/*_test.py)
SKIP_PY_RE='@(pytest\.mark\.skip|unittest\.skip)\b|\b(pytest|unittest)\.skip\s*\('
TAUT_PY_RE='^[[:space:]]*(assert[[:space:]]+(True|False)\b|self\.assert(True|False)\s*\(\s*(True|False)\s*\))'

if [[ -d "${ROOT_DIR}/tests" ]]; then
  while IFS= read -r -d '' py_test; do
    if grep -vE '^[[:space:]]*#' "${py_test}" | grep -E "${SKIP_PY_RE}" >/dev/null 2>&1; then
      echo "❌ [TESTING FORTRESS] ${py_test}: Skipped test (@pytest.mark.skip / unittest.skip) is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -vE '^[[:space:]]*#' "${py_test}" | grep -E "${TAUT_PY_RE}" >/dev/null 2>&1; then
      echo "❌ [TESTING FORTRESS] ${py_test}: Tautological assertion (assert True / assertTrue(True)) is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/tests" \
    -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune \
    -o -type f \( -name "test_*.py" -o -name "*_test.py" \) -print0)
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
