#!/usr/bin/env bash
set -euo pipefail

REPO="Polyfrost/OneLauncher"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(readlink -f "$0")")"
PACKAGE_FILE="$REPO_ROOT/package.nix"

if [[ ! -f "$PACKAGE_FILE" ]]; then
  echo "Error: $PACKAGE_FILE not found." >&2
  exit 1
fi

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

echo "Checking latest release from $REPO..."

# Public release asset: S3 redirect'te 400 hatası almamak için Authorization header gönderilmez
RESPONSE=$(curl -sL "https://github.com/$REPO/releases/latest/download/latest.json" 2>/dev/null || true)
LATEST_VERSION=""

parse_json_version() {
  local json="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r '.version // empty' 2>/dev/null || true
  else
    echo "$json" | grep -oP '"version":\s*"\K[^"]+' || true
  fi
}

parse_json_tag() {
  local json="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r '.tag_name // empty' 2>/dev/null || true
  else
    echo "$json" | grep -oP '"tag_name":\s*"\K[^"]+' || true
  fi
}

parse_json_hash() {
  local json="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r '.hash // empty' 2>/dev/null || true
  else
    echo "$json" | grep -oP '"hash":\s*"\K[^"]+' || true
  fi
}

if [[ -n "$RESPONSE" ]]; then
  LATEST_VERSION=$(parse_json_version "$RESPONSE")
fi

# Fallback: GitHub API (Rate limit durumunda AUTH_HEADER kullanılır)
if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "null" ]]; then
  API_RESPONSE=$(curl -sL "${AUTH_HEADER[@]}" "https://api.github.com/repos/$REPO/releases/latest")
  LATEST_TAG=$(parse_json_tag "$API_RESPONSE")
  if [[ -n "$LATEST_TAG" && "$LATEST_TAG" != "null" ]]; then
    LATEST_VERSION="${LATEST_TAG#oneclient-}"
    LATEST_VERSION="${LATEST_VERSION#v}"
  else
    API_MSG=$(echo "$API_RESPONSE" | grep -oP '"message":\s*"\K[^"]+' || true)
    if [[ -n "$API_MSG" ]]; then
      echo "Error from GitHub API: $API_MSG"
    else
      echo "Error: Failed to fetch latest release."
    fi
    exit 1
  fi
fi

CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$PACKAGE_FILE")

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
  echo "Already up-to-date."
  exit 0
fi

echo "New version available: $LATEST_VERSION. Prefetching hash..."
URL="https://github.com/$REPO/releases/download/oneclient-${LATEST_VERSION}/OneClient_${LATEST_VERSION}_linux_x86_64.AppImage"
PREFETCH_OUT=$(nix store prefetch-file "$URL" --json)
NEW_HASH=$(parse_json_hash "$PREFETCH_OUT")

if [[ -z "$NEW_HASH" || "$NEW_HASH" == "null" ]]; then
  echo "Error: Failed to prefetch hash for $URL"
  exit 1
fi

echo "Fetched hash: $NEW_HASH"
echo "Updating $PACKAGE_FILE..."

# Update version
sed -i -E "s/version = \"[^\"]+\";/version = \"$LATEST_VERSION\";/" "$PACKAGE_FILE"
# Update hash
sed -i -E "s|hash = \"[^\"]+\";|hash = \"$NEW_HASH\";|" "$PACKAGE_FILE"

echo "Testing build..."
if nix build --no-link "$REPO_ROOT#oneclient"; then
  echo "Build succeeded! Updated to $LATEST_VERSION."
else
  echo "Build failed! Reverting $PACKAGE_FILE..."
  git checkout -- "$PACKAGE_FILE"
  exit 1
fi
