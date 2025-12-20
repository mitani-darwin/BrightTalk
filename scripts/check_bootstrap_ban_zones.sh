#!/usr/bin/env bash
set -euo pipefail

pattern='\\b(container|row|col-|btn|card|text-|d-flex|alert|badge|modal|dropdown|collapse|tooltip|toast)\\b'

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

search() {
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@"
  else
    grep -nE "$pattern" "$@"
  fi
}

search() {
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@"
  else
    grep -nE "$pattern" "$@"
  fi
}

files=(
  "$repo_root/app/views/layouts/tailwind.html.erb"
  "$repo_root/app/views/tw/posts/index.html.erb"
  "$repo_root/app/views/tw/posts/_post_card.html.erb"
  "$repo_root/app/views/tw/shared/_empty_state.html.erb"
  "$repo_root/app/views/tw/shared/_pagination.html.erb"
  "$repo_root/app/views/shared/_navigation.html.erb"
  "$repo_root/app/views/shared/_footer.html.erb"
)

found=0
missing=0
for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing file: $file"
    missing=1
    continue
  fi
  if search "$file"; then
    found=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Bootstrap ban zone check failed due to missing files."
  exit 1
fi

if [ "$found" -ne 0 ]; then
  echo "Bootstrap classes/components detected in ban zones."
  exit 1
fi

echo "Bootstrap ban zone check passed."
