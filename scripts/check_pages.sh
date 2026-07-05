#!/usr/bin/env bash
# Fails loudly if any app directory is missing privacy.html/support.html,
# or if the live GitHub Pages URL for either page doesn't return 200.
# Run this after every app is added AND on every push via CI —
# this is the safety net for the recurring "forgot to publish the legal pages" bug.
set -uo pipefail

BASE_URL="https://shimondeitel.github.io/cool-apps-legal"
FAIL=0
EXCLUDE_DIRS=("scripts" ".github" ".git")

cd "$(dirname "$0")/.."

is_excluded() {
  local slug="$1"
  for ex in "${EXCLUDE_DIRS[@]}"; do
    [ "$slug" = "$ex" ] && return 0
  done
  return 1
}

for dir in */; do
  slug="${dir%/}"
  is_excluded "$slug" && continue
  for page in privacy.html support.html; do
    path="$dir$page"
    if [ ! -f "$path" ]; then
      echo "MISSING FILE: $path"
      FAIL=1
      continue
    fi
    url="$BASE_URL/$slug/$page"
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$code" != "200" ]; then
      echo "NOT LIVE ($code): $url"
      FAIL=1
    else
      echo "ok: $url"
    fi
  done
done

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "One or more legal pages are missing or not live. Fix before considering any app submission-ready."
  exit 1
fi

echo ""
echo "All legal pages present and live."
