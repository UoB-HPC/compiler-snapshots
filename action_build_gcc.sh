#!/usr/bin/env bash

set -eu

set +u # scl_source has unbound vars, disable check
source scl_source enable gcc-toolset-14 || true
set -u

BUILDS=$1

dry=false

# shellcheck disable=SC2206
builds_array=(${BUILDS//;/ }) # split by ws

git init gcc
cd gcc
git remote add origin https://github.com/gcc-mirror/gcc.git
git config --local gc.auto 0

for build in "${builds_array[@]}"; do

  dest_dir="/tmp/$build"
  dest_archive="/host/$build.tar.xz"

  hash=$(jq -r ".\"$build\" | .hash" "/host/builds.json")

  echo "Build   : $build"
  echo "Commit  : $hash"

  git -c protocol.version=2 fetch \
    --quiet \
    --no-tags \
    --prune \
    --progress \
    --no-recurse-submodules \
    --depth=1 \
    origin "$hash"

  git reset
  git checkout FETCH_HEAD

  echo "Source cloned, starting build step..."

  if $dry; then
    echo "Dry run, creating dummy artefact..."
    mkdir -p "$dest_dir"
    echo "$build" >"$dest_dir/data.txt"
  else

    pwd
    ls -lah

    rm -rf build
    mkdir -p build

    time ./contrib/download_prerequisites --no-isl --no-verify
    (
      cd build
      ../configure \
      CFLAGS=-Wno-error=incompatible-pointer-types \
      --prefix="/opt/$build" --enable-languages=c,c++,fortran --disable-bootstrap --disable-multilib --disable-libvtv --without-isl
    )
    time make -C build -j "$(nproc)"
    time make -C build -j "$(nproc)" install DESTDIR="$dest_dir"

  fi

  XZ_OPT='-T0 -2' tar cfJ "$dest_archive" --checkpoint=.1000 --totals -C "$dest_dir" .
  # zip -r "$dest_archive" "$dest_dir"

  du -sh "$dest_dir"
  du -sh "$dest_archive"

done
