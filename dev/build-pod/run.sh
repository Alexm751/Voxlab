#!/usr/bin/env bash
# Build + enter the Voxlab build pod on macmini (rootless Podman).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE="${VOXLAB_BUILD_IMAGE:-localhost/voxlab-build:latest}"
POD="${VOXLAB_BUILD_POD:-voxlab-build}"
CTR="${VOXLAB_BUILD_CTR:-voxlab-build}"
# Host path to mount (default: this repo)
HOST_SRC="${VOXLAB_HOST_SRC:-$REPO_ROOT}"
# Persist cargo/go caches across rebuilds of the container
VOL_CARGO_REG="${VOXLAB_CARGO_REG_VOL:-voxlab-cargo-registry}"
VOL_CARGO_GIT="${VOXLAB_CARGO_GIT_VOL:-voxlab-cargo-git}"
VOL_GO="${VOXLAB_GO_VOL:-voxlab-gopath}"
# Soft memory cap — macmini is ~7Gi and already busy
MEMORY="${VOXLAB_BUILD_MEMORY:-5g}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <build|up|shell|exec|down|status> [args...]

  build   podman build the image
  up      create pod + container (idempotent)
  shell   interactive bash in the container
  exec    run a command: ./run.sh exec cargo check --locked
  down    stop/remove container + pod (keeps volumes + image)
  status  show pod/container/tool versions
EOF
}

cmd_build() {
  echo "[build] $IMAGE from $SCRIPT_DIR/Containerfile"
  podman build -t "$IMAGE" -f "$SCRIPT_DIR/Containerfile" "$SCRIPT_DIR"
}

ensure_volumes() {
  podman volume exists "$VOL_CARGO_REG" 2>/dev/null || podman volume create "$VOL_CARGO_REG"
  podman volume exists "$VOL_CARGO_GIT" 2>/dev/null || podman volume create "$VOL_CARGO_GIT"
  podman volume exists "$VOL_GO" 2>/dev/null || podman volume create "$VOL_GO"
}

cmd_up() {
  ensure_volumes
  if ! podman pod exists "$POD" 2>/dev/null; then
    podman pod create --name "$POD"
  fi
  if podman container exists "$CTR" 2>/dev/null; then
    local state
    state="$(podman inspect -f '{{.State.Status}}' "$CTR")"
    if [ "$state" != "running" ]; then
      podman start "$CTR"
    fi
    echo "[up] container $CTR already present ($state)"
    return 0
  fi
  podman run -d \
    --pod "$POD" \
    --name "$CTR" \
    --memory "$MEMORY" \
    --memory-swap "$MEMORY" \
    -v "$HOST_SRC:/workspace:rw" \
    -v "$VOL_CARGO_REG:/opt/cargo/registry:rw" \
    -v "$VOL_CARGO_GIT:/opt/cargo/git:rw" \
    -v "$VOL_GO:/opt/go:rw" \
    -w /workspace \
    "$IMAGE" \
    sleep infinity
  echo "[up] pod=$POD container=$CTR mount=$HOST_SRC memory=$MEMORY"
}

cmd_shell() {
  cmd_up
  podman exec -it "$CTR" bash -l
}

cmd_exec() {
  cmd_up
  podman exec -it "$CTR" "$@"
}

cmd_down() {
  podman rm -f "$CTR" 2>/dev/null || true
  podman pod rm -f "$POD" 2>/dev/null || true
  echo "[down] removed container/pod (volumes + image kept)"
}

cmd_status() {
  echo "=== pod ==="
  podman pod ps --filter "name=$POD" || true
  echo "=== container ==="
  podman ps -a --filter "name=$CTR" || true
  if podman container exists "$CTR" 2>/dev/null; then
    echo "=== toolchains ==="
    podman exec "$CTR" bash -lc 'rustc --version; cargo --version; go version; node --version; bun --version; uv --version; python3 --version; uv run python --version 2>/dev/null || true'
  fi
}

main() {
  local op="${1:-}"
  shift || true
  case "$op" in
    build)  cmd_build "$@" ;;
    up)     cmd_up "$@" ;;
    shell)  cmd_shell "$@" ;;
    exec)   cmd_exec "$@" ;;
    down)   cmd_down "$@" ;;
    status) cmd_status "$@" ;;
    -h|--help|help|"") usage; exit 0 ;;
    *) echo "unknown: $op"; usage; exit 1 ;;
  esac
}

main "$@"
