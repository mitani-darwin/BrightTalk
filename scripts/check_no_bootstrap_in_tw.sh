#!/usr/bin/env bash
set -euo pipefail

# Bootstrap-only tokens that have no equivalent in this project's Tailwind
# component layer (app/views/shared/_tailwind_styles.html.erb intentionally
# keeps .btn/.btn-*/.card/.badge/.form-control/.form-select/.nav-link/.pill/
# .text-muted/.bg-primary|secondary|info|warning|danger as real Tailwind
# @apply rules, so those are deliberately excluded from this list).
tokens='container|container-fluid|row'
tokens="$tokens|col-[0-9]+|col-(sm|md|lg|xl)-[0-9]+|offset-[0-9]+"
tokens="$tokens|d-flex|d-none|d-block|d-inline|d-inline-block|d-grid"
tokens="$tokens|justify-content-[a-z]+|align-items-[a-z]+"
tokens="$tokens|navbar|navbar-brand|navbar-nav"
tokens="$tokens|dropdown-menu|dropdown-toggle|dropdown-item"
tokens="$tokens|modal|modal-dialog|modal-content|modal-header|modal-body|modal-footer"
tokens="$tokens|collapse|tooltip|popover"
tokens="$tokens|alert-dismissible|alert-heading"
tokens="$tokens|form-check|form-check-input|form-check-label"
tokens="$tokens|list-group|list-group-item|input-group"
tokens="$tokens|table-striped|table-bordered"
tokens="$tokens|card-body|card-header|card-footer|card-title|card-text"
tokens="$tokens|text-primary|text-danger|text-info|text-light|text-dark"
tokens="$tokens|bg-light|bg-dark"
tokens="$tokens|btn-group"
tokens="$tokens|data-bs-|data-toggle="

# Only look inside class="..."/class: "..." (or '...') attribute values, and
# require a non-alphanumeric/hyphen boundary around the token, so a token like
# "row" doesn't match inside an unrelated Tailwind class like "flex-row", and
# a token like "collapse" doesn't match plain CSS/JS text such as
# "border-collapse" or a `container` JS variable name outside of a class attribute.
pattern="class[[:space:]]*[:=][[:space:]]*[\"']([^\"']*[^A-Za-z0-9_-])?(${tokens})([^A-Za-z0-9_-][^\"']*)?[\"']"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
views_root="$repo_root/app/views"

search() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -e "$pattern" "$@"
  else
    grep -nRE "$pattern" "$@"
  fi
}

if [ ! -d "$views_root" ]; then
  echo "Missing directory: $views_root"
  exit 1
fi

if search "$views_root"; then
  echo "Bootstrap classes/components detected under app/views."
  exit 1
fi

echo "app/views is free of Bootstrap classes."
