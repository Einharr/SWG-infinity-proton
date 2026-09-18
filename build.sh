#!/usr/bin/env bash
set -euo pipefail

readonly BUILD_NAME="SWG-Proton-1-test1"
readonly BASE_REPO="https://github.com/dawn-winery/dwproton-mirror.git"
readonly BASE_BRANCH="dwproton/11.0-13"
readonly BASE_COMMIT="c3d17566e1bd15aa47537390fc99402782f50e3f"
readonly WINE_COMMIT="299693a0002d839eac479514b4ef44de19bf73a9"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="${SWG_PROTON_WORK_ROOT:-$HOME/.cache/swg-proton-build}"
OUTPUT_DIR="${SWG_PROTON_OUTPUT_DIR:-$SCRIPT_DIR/dist}"
CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
JOBS="${JOBS:-$(nproc)}"
SOURCE_DIR="$WORK_ROOT/dwproton"
BUILD_DIR="$WORK_ROOT/build"
PATCH_FILE="$SCRIPT_DIR/patches/0001-ole32-weak-ref-for-registered-droptarget.patch"

command -v git >/dev/null
command -v "$CONTAINER_ENGINE" >/dev/null
command -v tar >/dev/null
test -f "$PATCH_FILE"
mkdir -p "$WORK_ROOT" "$OUTPUT_DIR"

# Docker Desktop can expose a Windows credential helper to WSL as an .exe.
# Some WSL setups cannot execute that helper, while dwproton only needs public
# images. Use a build-local, credential-free Docker config unless the caller
# explicitly selected one.
if [ "$CONTAINER_ENGINE" = docker ] && [ -z "${DOCKER_CONFIG:-}" ]; then
  export DOCKER_CONFIG="$WORK_ROOT/docker-config"
  mkdir -p "$DOCKER_CONFIG"
  if [ ! -f "$DOCKER_CONFIG/config.json" ]; then
    printf '{"auths":{}}\n' > "$DOCKER_CONFIG/config.json"
  fi
fi

if [ ! -d "$SOURCE_DIR/.git" ]; then
  git clone --filter=blob:none --single-branch --branch "$BASE_BRANCH" \
    "$BASE_REPO" "$SOURCE_DIR"
fi

git -C "$SOURCE_DIR" fetch --depth 1 origin "$BASE_COMMIT"
git -C "$SOURCE_DIR" checkout --detach "$BASE_COMMIT"

actual_base="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
test "$actual_base" = "$BASE_COMMIT"

# dwproton's Makefile automatically applies every *.patch in patches/wine.
mkdir -p "$SOURCE_DIR/patches/wine"
cp "$PATCH_FILE" "$SOURCE_DIR/patches/wine/9999-swg-ole32-weak-droptarget.patch"

# Initialise Wine first and prove that the patch matches the pinned source before
# downloading/building all other components.
git -C "$SOURCE_DIR" submodule update --init --depth 1 wine
actual_wine="$(git -C "$SOURCE_DIR/wine" rev-parse HEAD)"
test "$actual_wine" = "$WINE_COMMIT"
git -C "$SOURCE_DIR/wine" apply --check \
  "$SOURCE_DIR/patches/wine/9999-swg-ole32-weak-droptarget.patch"

git -C "$SOURCE_DIR" submodule update --init --recursive --depth 1

mkdir -p "$BUILD_DIR"
if [ ! -f "$BUILD_DIR/Makefile" ]; then
  (
    cd "$BUILD_DIR"
    "$SOURCE_DIR/configure.sh" \
      --build-name="$BUILD_NAME" \
      --container-engine="$CONTAINER_ENGINE" \
      --enable-ccache \
      --without-tts
  )
fi

upstream_dir="$BUILD_DIR/$BUILD_NAME"
upstream_archive="$BUILD_DIR/$BUILD_NAME.tar.xz"

if [ "${FORCE_REBUILD:-0}" = 1 ] || \
   [ ! -f "$upstream_dir/compatibilitytool.vdf" ] || \
   [ ! -x "$upstream_dir/proton" ] || \
   [ ! -f "$upstream_archive" ]; then
  make -C "$BUILD_DIR" -j"$JOBS" redist
else
  echo "Reusing complete dwproton redist: $upstream_archive"
fi

test -f "$upstream_dir/compatibilitytool.vdf"
test -x "$upstream_dir/proton"
test -f "$upstream_archive"

# The redist target already creates a correctly rooted, reproducible archive.
# Reuse it instead of spending another full xz pass over the 1.6 GiB tree.
archive="$OUTPUT_DIR/$BUILD_NAME.tar.xz"
cp "$upstream_archive" "$archive"
sha256sum "$archive" > "$archive.sha256"

cat > "$OUTPUT_DIR/$BUILD_NAME.build-info.txt" <<EOF
build_name=$BUILD_NAME
dwproton_branch=$BASE_BRANCH
dwproton_commit=$BASE_COMMIT
wine_commit=$WINE_COMMIT
patch=$(sha256sum "$PATCH_FILE" | awk '{print $1}')
archive=$(basename "$archive")
archive_sha256=$(sha256sum "$archive" | awk '{print $1}')
EOF

echo "Built: $archive"
echo "Checksum: $archive.sha256"
