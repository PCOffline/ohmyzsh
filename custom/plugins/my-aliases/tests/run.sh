#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  DOCKER=docker
elif command -v docker.exe >/dev/null 2>&1; then
  DOCKER=docker.exe
else
  echo "Error: no working docker binary found." >&2
  echo "  Install Docker, or enable Docker Desktop's WSL integration." >&2
  exit 1
fi

IMAGE_TAG="my-aliases-test:local"

cleanup() {
  "$DOCKER" image rm "$IMAGE_TAG" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Building image with $DOCKER ..."
"$DOCKER" build \
  -t "$IMAGE_TAG" \
  -f "$SCRIPT_DIR/Dockerfile" \
  "$PLUGIN_ROOT"

echo ""
echo "==> Running tests ..."
"$DOCKER" run --rm "$IMAGE_TAG"
