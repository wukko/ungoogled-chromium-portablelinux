#!/bin/bash
set -euo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"

_use_zstd=0
if command -v zstd >/dev/null 2>&1; then
    _use_zstd=1
fi

_ext="tar.xz"
_cache_tar="${_base_dir}/.github/cache/build-cache.${_ext}"
if [ "$_use_zstd" -eq 1 ]; then
    _ext="tar.zst"
    _cache_tar="${_base_dir}/.github/cache/build-cache.${_ext}"
fi

pushd "${_base_dir}" >/dev/null

_include_paths=()

# download cache for chromium source tarballs
[ -d "build/_download_cache" ] && _include_paths+=("build/_download_cache")

# chromium source and toolchains
[ -d "build/src/third_party/llvm-build" ] && _include_paths+=("build/src/third_party/llvm-build")
[ -d "build/src/third_party/rust-toolchain" ] && _include_paths+=("build/src/third_party/rust-toolchain")

# GN/Ninja build state
if [ -d "build/src/out/Default" ]; then
    [ -f "build/src/out/Default/.ninja_log" ] && _include_paths+=("build/src/out/Default/.ninja_log")
    [ -f "build/src/out/Default/.ninja_deps" ] && _include_paths+=("build/src/out/Default/.ninja_deps")
    [ -f "build/src/out/Default/args.gn" ] && _include_paths+=("build/src/out/Default/args.gn")
fi

if [ ${#_include_paths[@]} -eq 0 ]; then
    echo "No cache paths found to archive."
    exit 0
fi

echo "Creating cache archive at ${_cache_tar} including: ${_include_paths[*]}"
mkdir -p "$(dirname "${_cache_tar}")"

# create archive via stream to avoid tar flag incompatibilities
if [ "$_use_zstd" -eq 1 ]; then
    tar -cf - "${_include_paths[@]}" | zstd -T0 -3 -o "${_cache_tar}"
else
    tar -cf - "${_include_paths[@]}" | xz -T0 -c > "${_cache_tar}"
fi

echo "Cache archive created: ${_cache_tar}"

popd >/dev/null
