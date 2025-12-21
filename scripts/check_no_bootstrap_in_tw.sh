#!/usr/bin/env bash
set -euo pipefail

pattern='\\b(container|row|col-|btn|card|text-|d-flex|alert|badge|modal|dropdown|collapse|tooltip|toast)\\b'

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tw_root="$repo_root/app/views/tw"

search() {
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@"
  else
    grep -nRE "$pattern" "$@"
  fi
}

if [ ! -d "$tw_root" ]; then
  echo "Missing directory: $tw_root"
  exit 1
fi

if search "$tw_root"; then
  echo "Bootstrap classes/components detected in Tailwind-only views."
  exit 1
fi

echo "Tailwind-only views are free of Bootstrap classes."
