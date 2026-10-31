#!/usr/bin/env bash
# =============================================================================
# validate-symfony.sh — Symfony 7.x+ Hexagonal Architecture, Twig & Security Gate
# Enforces:
#   1. Locked deptrac.yaml presence & Domain layer purity (zero Doctrine/Symfony
#      imports in src/Domain/)
#   2. Thin Controllers: bans direct EntityManager persist/flush/remove or
#      createQueryBuilder inside src/Controller/
#   3. Dependency Injection Purity: bans $this->container->get() service locator
#   4. Twig XSS & Hygiene: bans '|raw' filter and '{{ dump(' in templates/
#   5. Twig WCAG 2.2 AA Accessibility: bans <img> without alt= and tabindex > 0
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

if [[ ! -f "${ROOT_DIR}/deptrac.yaml" ]]; then
  echo "❌ [SYMFONY GATE] Missing locked deptrac.yaml architecture configuration." >&2
  ERRORS=$((ERRORS + 1))
fi

# 1. Domain Layer Purity (Deptrac rule: Domain -> ~, zero Doctrine/Symfony coupling)
if [[ -d "${ROOT_DIR}/src/Domain" ]]; then
  while IFS= read -r -d '' dom_file; do
    if grep -vE '^[[:space:]]*(//|\*|#)' "${dom_file}" | grep -E -- '^[[:space:]]*use[[:space:]]+(Doctrine|Symfony)\\' >/dev/null 2>&1; then
      echo "❌ [SYMFONY DEPTRAC GATE] ${dom_file}: Domain layer ('src/Domain/') must remain pure PHP and cannot import 'Doctrine\\*' or 'Symfony\\*'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/src/Domain" -type f -name "*.php" -print0)
fi

# 2. Controller Thinness & DI Purity in src/Controller/
if [[ -d "${ROOT_DIR}/src/Controller" ]]; then
  while IFS= read -r -d '' ctrl_file; do
    if grep -vE '^[[:space:]]*(//|\*|#)' "${ctrl_file}" | grep -E -- '->(persist|flush|remove|createQueryBuilder)\s*\(' >/dev/null 2>&1; then
      echo "❌ [SYMFONY GATE] ${ctrl_file}: Direct Doctrine EntityManager write/query (->persist, ->flush, ->remove, ->createQueryBuilder) in Controller is forbidden. Delegate to an Application Service or Messenger Handler." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -vE '^[[:space:]]*(//|\*|#)' "${ctrl_file}" | grep -E -- '\$this->container->get\s*\(' >/dev/null 2>&1; then
      echo "❌ [SYMFONY GATE] ${ctrl_file}: Service locator anti-pattern (\$this->container->get()) is forbidden. Use constructor or action method autowiring." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/src/Controller" -type f -name "*.php" -print0)
fi

# 3. Twig Security (XSS), Hygiene & WCAG 2.2 AA Accessibility in templates/
if [[ -d "${ROOT_DIR}/templates" ]]; then
  while IFS= read -r -d '' twig_file; do
    if grep -E -- '\|\s*raw\b' "${twig_file}" >/dev/null 2>&1; then
      echo "❌ [SYMFONY TWIG SECURITY] ${twig_file}: Unescaped '|raw' filter is forbidden in Twig templates (XSS risk)." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -E -- '\{\{\s*dump\s*\(' "${twig_file}" >/dev/null 2>&1; then
      echo "❌ [SYMFONY TWIG GATE] ${twig_file}: Debug '{{ dump() }}' call is forbidden in Twig templates." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -E -- '<img\b[^>]*>' "${twig_file}" | grep -vE -- '\balt\s*=' >/dev/null 2>&1; then
      echo "❌ [SYMFONY A11Y GATE] ${twig_file}: <img> element missing mandatory 'alt=' attribute in Twig template." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -E -- 'tabindex\s*=\s*"[1-9][0-9]*"' "${twig_file}" >/dev/null 2>&1; then
      echo "❌ [SYMFONY A11Y GATE] ${twig_file}: Positive tabindex (> 0) is forbidden by WCAG 2.2 AA." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/templates" -type f -name "*.twig" -print0)
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [SYMFONY GATE] Failed with ${ERRORS} Symfony architectural/security violation(s)." >&2
  exit 1
fi

echo "✅ [SYMFONY GATE] Symfony 7.x+ Deptrac layers, Twig security & a11y gates passed."
