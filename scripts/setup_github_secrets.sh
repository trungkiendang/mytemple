#!/usr/bin/env bash
# Pushes the values in .github/store.env to GitHub repository secrets / variables.
# Usage: scripts/setup_github_secrets.sh [owner/repo]   (requires `gh auth login`)
set -euo pipefail
cd "$(dirname "$0")/.."
ENV_FILE=".github/store.env"
REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE (copy .github/store.env.example and fill it in)"; exit 1; }

while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  value="${value%%  #*}"            # strip trailing "  # comment"
  value="$(echo "$value" | sed -e 's/[[:space:]]*$//')"
  [ -z "$value" ] && { echo "skip  $key (empty)"; continue; }
  # "@path/to/file" → use the file contents (handy for .json / .p8 / base64 of binaries)
  if [[ "$value" == @* ]]; then value="$(cat "${value:1}")"; fi
  case "$key" in
    SECRET_*) printf '%s' "$value" | gh secret set "${key#SECRET_}" --repo "$REPO" && echo "secret   ${key#SECRET_}" ;;
    VAR_*)    gh variable set "${key#VAR_}" --body "$value" --repo "$REPO" && echo "variable ${key#VAR_}" ;;
    *)        echo "ignore $key" ;;
  esac
done < "$ENV_FILE"
