#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-$source_dir/build/portal}"
cmake_args=(
  -S "$source_dir" -B "$build_dir" -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_INSTALLER=OFF
  -DBUILD_TESTS=ON
  -DSKIP_BUILD_TESTS=OFF
  -DREQUIRE_PORTAL_CLIPBOARD=ON
)

# Optional prefix containing locally extracted Fedora development RPMs.
# Runtime libraries still come from the installed system packages.
if [[ -n "${PORTAL_DEPS_ROOT:-}" ]]; then
  deps_root="$(cd -- "$PORTAL_DEPS_ROOT" && pwd)"
  export PKG_CONFIG_PATH="$deps_root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  cmake_args+=(
    "-DOPENSSL_ROOT_DIR=$deps_root/usr"
    "-DCMAKE_CXX_FLAGS=-I\"$deps_root/usr/include\""
    "-DCMAKE_EXE_LINKER_FLAGS=-L\"$deps_root/usr/lib64\""
  )
fi

cmake "${cmake_args[@]}"
cmake --build "$build_dir" --parallel "${BUILD_JOBS:-6}"
printf 'Portal-enabled binaries: %s/bin\n' "$build_dir"
