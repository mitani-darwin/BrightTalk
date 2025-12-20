#!/usr/bin/env bash
set -euo pipefail

pattern='\b(container|row|col-|btn|card|text-|d-flex|alert|badge|modal|dropdown|collapse|tooltip|toast)\b'

files=(
  app/views/layouts/tailwind.html.erb
  app/views/posts/index.html.erb
  app/views/posts/_post_card.html.erb
  app/views/shared/_empty_state.html.erb
  app/views/shared/_pagination.html.erb
  app/views/shared/_navigation.html.erb
  app/views/shared/_footer.html.erb
)

found=0
for file in "${files[@]}"; do
  if rg -n "$pattern" "$file"; then
    found=1
  fi
done

if [ "$found" -ne 0 ]; then
  echo "Bootstrap classes/components detected in ban zones."
  exit 1
fi

echo "Bootstrap ban zone check passed."
