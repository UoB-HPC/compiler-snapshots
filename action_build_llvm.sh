#!/usr/bin/env bash

set -eu

set +u # scl_source has unbound vars, disable check
source scl_source enable devtoolset-10 || true
set -u

BUILDS=$1

dry=false

# shellcheck disable=SC2206
builds_array=(${BUILDS//;/ }) # split by ws

git init llvm
cd llvm
git remote add origin https://github.com/llvm/llvm-project.git
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

  # Commits before https://github.com/llvm/llvm-project/commit/7f5fe30a150e will only work with
  # CMake < 3.17 due to a bug in LLVM's ExternalProjectAdd.

  has_tgt_fix=0
  git merge-base --is-ancestor 7f5fe30a150e7e87d3fbe4da4ab0e76ec38b40b9 "$hash" || has_tgt_fix=$?

  if [ "$has_tgt_fix" -ne 0 ]; then
    echo "Commit requires CMake < 3.17, downloading that now..."
    curl -L "https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.sh" -o "cmake-install.sh"
    chmod +x "./cmake-install.sh"
    "./cmake-install.sh" --skip-license --include-subdir
    rm -rf "./cmake-install.sh"
    cmake3() { "$PWD/cmake-3.16.4-Linux-x86_64/bin/cmake" "$@"; }
  else
    echo "Commit does not require CMake < 3.17, continuing..."
  fi

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

    # compiler-rt implements atomic which openmp needs
    time cmake3 -S llvm -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DLLVM_ENABLE_PROJECTS="clang;lld;openmp;polly;pstl" \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_BENCHMARKS=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_BUILD_TESTS=OFF \
      -DLLVM_BUILD_DOCS=OFF \
      -DLLVM_BUILD_EXAMPLES=OFF \
      -DLIBOMP_USE_QUAD_PRECISION=OFF \
      -DCMAKE_INSTALL_PREFIX="$dest_dir/opt/$build" \
      -GNinja

    time cmake3 --build build # Ninja is parallel by default
    time cmake3 --build build --target install

  fi

  XZ_OPT='-T0 -2' tar cfJ "$dest_archive" --checkpoint=.1000 --totals -C "$dest_dir" .
  # zip -r "$dest_archive" "$dest_dir"

  du -sh "$dest_dir"
  du -sh "$dest_archive"

done
