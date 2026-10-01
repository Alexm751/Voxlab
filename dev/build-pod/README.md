# Voxlab build pod (Podman)

Rootless Podman image + pod for Linux compiles on the Ubuntu macmini.

**Inside the image:** Rust/Cargo (rustup stable), Go (latest), Node (latest), Bun (latest), Python via `uv` (+ system `python3`), plus Tauri/GTK build deps.

## On macmini

```bash
cd ~/src/Voxlab
git pull
chmod +x dev/build-pod/run.sh

# First time (~few GB download/build; machine is RAM-tight — prefer idle window)
./dev/build-pod/run.sh build
./dev/build-pod/run.sh up
./dev/build-pod/run.sh status

# Interactive
./dev/build-pod/run.sh shell

# One-shot
./dev/build-pod/run.sh exec bash -lc 'cd src-tauri && cargo check --locked'
./dev/build-pod/run.sh exec bash -lc 'bun install --frozen-lockfile'
```

Env overrides: `VOXLAB_HOST_SRC`, `VOXLAB_BUILD_MEMORY` (default `5g`), `VOXLAB_BUILD_IMAGE`, `VOXLAB_BUILD_POD`.

Volumes `voxlab-cargo-registry`, `voxlab-cargo-git`, `voxlab-gopath` keep caches across `down`/`up`.
