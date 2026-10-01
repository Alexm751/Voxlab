#!/usr/bin/env bash
set -euo pipefail

# Build Flatpak for Handy
# Usage: ./scripts/build-flatpak.sh [path-to-deb]
#
# If no .deb path is provided, the app is built from source inside the Flatpak SDK
# to ensure glibc compatibility with the runtime. This avoids the mismatch that
# occurs when building on newer host systems (e.g. with local glibc vs the GNOME flatpak's runtime glibc).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLATPAK_DIR="$PROJECT_ROOT/src-tauri/flatpak"
BUILD_DIR="$PROJECT_ROOT/flatpak-build"
REPO_DIR="$PROJECT_ROOT/flatpak-repo"

APP_ID="com.pais.handy"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for required tools
check_dependencies() {
    local missing=()

    if ! command -v flatpak &> /dev/null; then
        missing+=("flatpak")
    fi

    if ! command -v flatpak-builder &> /dev/null; then
        missing+=("flatpak-builder")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        echo ""
        echo "Install them with:"
        echo "  Debian/Ubuntu: sudo apt install flatpak flatpak-builder"
        echo "  Arch:          sudo pacman -S flatpak flatpak-builder"
        echo "  Fedora:        sudo dnf install flatpak flatpak-builder"
        exit 1
    fi
}

# Check for required Flatpak runtimes
check_runtime() {
    local runtimes=(
        "org.gnome.Platform//48"
        "org.gnome.Sdk//48"
    )

    for ref in "${runtimes[@]}"; do
        if ! flatpak info "$ref" &> /dev/null; then
            log_info "Installing $ref..."
            flatpak install -y --user flathub "$ref"
        fi
    done
}

# Check for SDK extensions needed only when building from source.
# Note: rust-stable//24.08 ships rustc 1.89, but tauri 2.12 / muda 0.20 need
# ≥1.90 — so Rust comes from rustup inside build_in_sdk, not this extension.
check_sdk_extensions() {
    local extensions=(
        "org.freedesktop.Sdk.Extension.llvm19//24.08"
    )

    for ref in "${extensions[@]}"; do
        if ! flatpak info "$ref" &> /dev/null; then
            log_info "Installing $ref..."
            flatpak install -y --user flathub "$ref"
        fi
    done
}

# Build the Tauri app inside the Flatpak SDK so the binary links against the
# runtime's glibc instead of the (potentially newer) host glibc.
# Produces a minimal .deb-like archive that the Flatpak manifest can consume.
build_in_sdk() {
    local build_missing=()
    if ! command -v bun &> /dev/null; then
        build_missing+=("bun")
    fi
    if ! command -v ar &> /dev/null; then
        build_missing+=("ar (binutils)")
    fi
    if [ ${#build_missing[@]} -ne 0 ]; then
        log_error "Missing tools required for source build: ${build_missing[*]}"
        exit 1
    fi

    log_info "Building Handy inside Flatpak SDK (ensures glibc compatibility)..."

    local bun_path
    bun_path="$(which bun)"

    local sdk_prefix="$PROJECT_ROOT/.flatpak-sdk-prefix"

    flatpak run \
        --share=network \
        --filesystem=home \
        --env=PATH=/usr/lib/sdk/llvm19/bin:/usr/bin:/bin \
        --env=LIBCLANG_PATH=/usr/lib/sdk/llvm19/lib \
        --env=WHISPER_NO_AVX=ON \
        --env=WHISPER_NO_AVX2=ON \
        --env=HOME="$HOME" \
        --env=CARGO_HOME="$HOME/.cargo" \
        --env=RUSTUP_HOME="$HOME/.rustup" \
        --env=SDK_PREFIX="$sdk_prefix" \
        --env=SDK_PROJECT_ROOT="$PROJECT_ROOT" \
        --env=SDK_BUN_PATH="$bun_path" \
        --command=bash \
        org.gnome.Sdk//48 \
        -c '
            set -euo pipefail

            export PKG_CONFIG_PATH="$SDK_PREFIX/lib/pkgconfig:$SDK_PREFIX/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"
            export LD_LIBRARY_PATH="$SDK_PREFIX/lib:$SDK_PREFIX/lib64:${LD_LIBRARY_PATH:-}"

            # SDK rust-stable//24.08 is rustc 1.89; locked deps need ≥1.90.
            export PATH="$CARGO_HOME/bin:$PATH"
            if ! command -v rustc >/dev/null 2>&1 || ! rustc --version 2>/dev/null | grep -qE "rustc 1\.(9[0-9]|[1-9][0-9]{2})\."; then
                echo "Installing rustup stable (≥1.90 required by tauri 2.12)..."
                curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable
            fi
            rustc --version

            # Build gtk-layer-shell if not already cached
            if ! pkg-config --exists gtk-layer-shell-0 2>/dev/null; then
                echo "Building gtk-layer-shell..."
                cd /tmp
                curl -sL https://github.com/wmww/gtk-layer-shell/archive/refs/tags/v0.10.0.tar.gz | tar xz
                cd gtk-layer-shell-0.10.0
                meson setup build --prefix="$SDK_PREFIX" -Dexamples=false -Ddocs=false -Dtests=false
                ninja -C build install
            fi

            # Build SPIRV-Headers for transcribe-cpp Vulkan backend
            if [ ! -f "$SDK_PREFIX/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake" ]; then
                echo "Building SPIRV-Headers..."
                cd /tmp
                curl -sL https://github.com/KhronosGroup/SPIRV-Headers/archive/refs/tags/vulkan-sdk-1.4.309.0.tar.gz | tar xz
                cd SPIRV-Headers-vulkan-sdk-1.4.309.0
                cmake -B build -DCMAKE_INSTALL_PREFIX="$SDK_PREFIX" -DSPIRV_HEADERS_SKIP_EXAMPLES=ON
                cmake --install build --prefix "$SDK_PREFIX"
            fi

            export CMAKE_PREFIX_PATH="$SDK_PREFIX:$SDK_PREFIX/lib/cmake:${CMAKE_PREFIX_PATH:-}"
            export CPATH="$SDK_PREFIX/include:${CPATH:-}"
            export CPLUS_INCLUDE_PATH="$SDK_PREFIX/include:${CPLUS_INCLUDE_PATH:-}"
            export CMAKE_INCLUDE_PATH="$SDK_PREFIX/include"

            cd "$SDK_PROJECT_ROOT"

            # Build frontend and Rust binary via Tauri (--no-bundle skips
            # the deb/appimage bundling step that requires appindicator)
            "$SDK_BUN_PATH" install --frozen-lockfile
            "$SDK_BUN_PATH" run tauri build --no-bundle
        '

    if [ ! -f "$PROJECT_ROOT/src-tauri/target/release/handy" ]; then
        log_error "SDK build failed — binary not found at src-tauri/target/release/handy"
        exit 1
    fi

    # Assemble a minimal .deb-like archive from the build output for the Flatpak manifest
    log_info "Assembling .deb from build output..."

    local staging="$PROJECT_ROOT/src-tauri/target/release/flatpak-deb-staging"
    rm -rf "$staging"

    # Binary
    install -Dm755 "$PROJECT_ROOT/src-tauri/target/release/handy" "$staging/data/usr/bin/handy"

    # Resources + transcribe runtime libs share /usr/lib/Handy — matching the
    # Tauri deb layout and the binary rpath ($ORIGIN/../lib/Handy).
    mkdir -p "$staging/data/usr/lib/Handy"
    cp -r "$PROJECT_ROOT/src-tauri/resources" "$staging/data/usr/lib/Handy/resources"
    stage_transcribe_into_handy_lib "$staging/data/usr/lib/Handy"

    # Desktop file
    mkdir -p "$staging/data/usr/share/applications"
    cat > "$staging/data/usr/share/applications/Handy.desktop" << 'DESKTOP'
[Desktop Entry]
Categories=Audio;Utility;Accessibility;
Comment=Handy
GenericName=Speech to Text
Exec=handy
StartupWMClass=handy
Icon=handy
Name=Handy
Terminal=false
Type=Application
DESKTOP

    # Icons
    install -Dm644 "$PROJECT_ROOT/src-tauri/icons/32x32.png" "$staging/data/usr/share/icons/hicolor/32x32/apps/handy.png"
    install -Dm644 "$PROJECT_ROOT/src-tauri/icons/64x64.png" "$staging/data/usr/share/icons/hicolor/64x64/apps/handy.png"
    install -Dm644 "$PROJECT_ROOT/src-tauri/icons/128x128.png" "$staging/data/usr/share/icons/hicolor/128x128/apps/handy.png"
    install -Dm644 "$PROJECT_ROOT/src-tauri/icons/128x128@2x.png" "$staging/data/usr/share/icons/hicolor/256x256@2x/apps/handy.png" || true

    # Create data.tar.gz
    tar -C "$staging/data" -czf "$staging/data.tar.gz" .

    # Create minimal control
    mkdir -p "$staging/control"
    echo "Package: handy" > "$staging/control/control"
    tar -C "$staging/control" -czf "$staging/control.tar.gz" .

    # Create debian-binary
    echo "2.0" > "$staging/debian-binary"

    # Assemble .deb (ar archive)
    local deb_output="$PROJECT_ROOT/src-tauri/target/release/handy-flatpak.deb"
    ar rc "$deb_output" "$staging/debian-binary" "$staging/control.tar.gz" "$staging/data.tar.gz"

    rm -rf "$staging"
    verify_deb_has_transcribe_libs "$deb_output"
    log_info "SDK build produced: $deb_output"
}

# Copy libtranscribe + ggml backends into dest (must be .../usr/lib/Handy).
# Prefer build.rs staging (src-tauri/transcribe-libs); fall back to the
# transcribe-cpp-sys CMake install dir via stage-transcribe-libs.sh.
stage_transcribe_into_handy_lib() {
    local dest="${1:?stage_transcribe_into_handy_lib: dest dir required}"
    mkdir -p "$dest"

    local staged="$PROJECT_ROOT/src-tauri/transcribe-libs"
    if ls "$staged"/libtranscribe.so* >/dev/null 2>&1; then
        log_info "Bundling transcribe runtime libs from $staged"
        cp -a "$staged"/libtranscribe.so* "$dest"/
        cp -a "$staged"/libggml*.so* "$dest"/ 2>/dev/null || true
    else
        log_warn "transcribe-libs/ empty or missing; falling back to cmake out dir"
        local libdir=""
        # Prefer the dir that contains transcribe-link.json (newest match).
        local newest
        newest="$(find "$PROJECT_ROOT/src-tauri/target/release/build" \
            -type f -name transcribe-link.json -path '*transcribe-cpp-sys*/out/lib*' 2>/dev/null \
            | while read -r f; do
                printf '%s\t%s\n' "$(stat -c '%Y' "$f" 2>/dev/null || echo 0)" "$f"
              done | sort -rn | head -1 | cut -f2- || true)"
        if [ -n "$newest" ]; then
            libdir="$(dirname "$newest")"
        else
            local out_dir
            out_dir="$(find "$PROJECT_ROOT/src-tauri/target/release/build" \
                -maxdepth 3 -type d -name out -path '*/transcribe-cpp-sys-*' 2>/dev/null | head -1 || true)"
            if [ -n "$out_dir" ] && [ -d "$out_dir/lib" ]; then
                libdir="$out_dir/lib"
            elif [ -n "$out_dir" ] && [ -d "$out_dir/lib64" ]; then
                libdir="$out_dir/lib64"
            fi
        fi
        if [ -z "$libdir" ] || [ ! -d "$libdir" ]; then
            log_error "Could not locate transcribe-cpp runtime libraries"
            find "$PROJECT_ROOT/src-tauri/target" \( -name 'libtranscribe*' -o -name 'libggml*' \) 2>/dev/null | head -50 || true
            exit 1
        fi
        bash "$SCRIPT_DIR/ci/stage-transcribe-libs.sh" "$libdir" "$dest"
    fi

    if ! ls "$dest"/libtranscribe.so* >/dev/null 2>&1; then
        log_error "libtranscribe.so* missing from $dest after staging"
        ls -la "$dest" >&2 || true
        exit 1
    fi
    if ! ls "$dest"/libggml-cpu*.so* >/dev/null 2>&1; then
        log_error "libggml-cpu*.so* missing from $dest after staging"
        ls -la "$dest" >&2 || true
        exit 1
    fi
    log_info "Staged transcribe libs into $dest:"
    ls -la "$dest" | grep -E 'libtranscribe|libggml' || true
}

# Fail if a .deb (synthetic or Tauri-built) lacks the SONAME the loader needs.
verify_deb_has_transcribe_libs() {
    local deb="${1:?verify_deb_has_transcribe_libs: .deb path required}"
    local listing
    listing="$(mktemp)"
    if command -v dpkg-deb >/dev/null 2>&1; then
        dpkg-deb -c "$deb" > "$listing"
    else
        local tmp
        tmp="$(mktemp -d)"
        (cd "$tmp" && ar x "$deb")
        if [ -f "$tmp/data.tar.gz" ]; then
            tar -tzf "$tmp/data.tar.gz" > "$listing"
        elif [ -f "$tmp/data.tar.xz" ]; then
            tar -tJf "$tmp/data.tar.xz" > "$listing"
        elif [ -f "$tmp/data.tar.zst" ]; then
            tar --zstd -tf "$tmp/data.tar.zst" > "$listing"
        else
            log_error "Could not list contents of $deb"
            rm -rf "$tmp" "$listing"
            exit 1
        fi
        rm -rf "$tmp"
    fi

    if ! grep -Eq 'usr/lib/Handy/libtranscribe\.so(\.[0-9]+)+' "$listing"; then
        log_error "Deb missing usr/lib/Handy/libtranscribe.so* (SONAME): $deb"
        grep -E 'libtranscribe|libggml|usr/lib' "$listing" | head -40 >&2 || true
        rm -f "$listing"
        exit 1
    fi
    if ! grep -Eq 'usr/lib/Handy/libggml-cpu' "$listing"; then
        log_error "Deb missing usr/lib/Handy/libggml-cpu*.so: $deb"
        grep -E 'libggml' "$listing" | head -40 >&2 || true
        rm -f "$listing"
        exit 1
    fi
    log_info "Deb contains libtranscribe + ggml CPU backends under usr/lib/Handy"
    rm -f "$listing"
}

# After flatpak-builder, confirm the sandbox resolves libtranscribe via rpath.
verify_flatpak_resolves_transcribe() {
    local build_dir="${1:?verify_flatpak_resolves_transcribe: build dir required}"
    log_info "Verifying libtranscribe resolves inside Flatpak build..."
    local ldd_out
    if ! ldd_out="$(flatpak-builder --run "$build_dir" "$FLATPAK_DIR/$APP_ID.yaml" \
        sh -c 'ldd /app/bin/handy' 2>&1)"; then
        log_error "flatpak-builder --run ldd failed"
        echo "$ldd_out" >&2
        exit 1
    fi
    if echo "$ldd_out" | grep -q 'libtranscribe.*not found'; then
        log_error "libtranscribe reported as not found:"
        echo "$ldd_out" | grep -E 'transcribe|not found' >&2
        exit 1
    fi
    if ! echo "$ldd_out" | grep -E 'libtranscribe\.so' | grep -v 'not found' | grep -q .; then
        log_error "libtranscribe not resolved by ldd inside Flatpak:"
        echo "$ldd_out" | grep -E 'transcribe|ggml|not found' >&2 || echo "$ldd_out" >&2
        exit 1
    fi
    log_info "libtranscribe resolves inside Flatpak:"
    echo "$ldd_out" | grep -E 'libtranscribe|libggml' || true
}

main() {
    local deb_input="${1:-}"

    log_info "Handy Flatpak Builder"
    echo ""

    # Check dependencies
    check_dependencies

    # Check runtime
    check_runtime

    # Initialize submodules (shared-modules for libayatana-appindicator)
    if [ ! -f "$FLATPAK_DIR/shared-modules/libayatana-appindicator/libayatana-appindicator-gtk3.json" ]; then
        log_info "Initializing git submodules..."
        git -C "$PROJECT_ROOT" submodule update --init --recursive
    fi

    # Get or build .deb
    local deb_path
    if [ -n "$deb_input" ] && [ -f "$deb_input" ]; then
        deb_path="$deb_input"
        log_info "Using provided .deb: $deb_path"
        verify_deb_has_transcribe_libs "$deb_path"
    else
        check_sdk_extensions
        build_in_sdk
        deb_path="$PROJECT_ROOT/src-tauri/target/release/handy-flatpak.deb"
    fi

    # Clean previous builds
    rm -rf "$BUILD_DIR" "$REPO_DIR"
    mkdir -p "$BUILD_DIR"

    # Copy .deb to flatpak directory with expected name
    trap 'rm -f "$FLATPAK_DIR/handy.deb"' EXIT
    cp "$deb_path" "$FLATPAK_DIR/handy.deb"
    log_info "Copied .deb to flatpak build directory"

    # Build the Flatpak
    log_info "Building Flatpak..."
    cd "$FLATPAK_DIR"

    flatpak-builder \
        --force-clean \
        --user \
        --disable-cache \
        --disable-rofiles-fuse \
        --repo="$REPO_DIR" \
        "$BUILD_DIR" \
        "$APP_ID.yaml"

    verify_flatpak_resolves_transcribe "$BUILD_DIR"

    # Create single-file bundle
    local version
    version=$(grep -o '"version": "[^"]*"' "$PROJECT_ROOT/src-tauri/tauri.conf.json" | cut -d'"' -f4)
    local arch
    arch=$(flatpak --default-arch)
    local bundle_name="handy_${version}_${arch}.flatpak"

    log_info "Creating Flatpak bundle..."
    flatpak build-bundle \
        "$REPO_DIR" \
        "$PROJECT_ROOT/$bundle_name" \
        "$APP_ID"

    echo ""
    log_info "Flatpak bundle created: $PROJECT_ROOT/$bundle_name"
    echo ""
    echo "To install locally:"
    echo "  flatpak install --user $bundle_name"
    echo ""
    echo "To run:"
    echo "  flatpak run $APP_ID"
    echo ""
    echo "To toggle transcription via signal (useful for Wayland):"
    echo "  pkill -SIGUSR2 -f 'flatpak.*handy' || flatpak kill --signal=USR2 $APP_ID"
}

main "$@"
