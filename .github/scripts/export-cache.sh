#!/bin/bash
set -euxo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"

_use_zstd=0
if command -v zstd >/dev/null 2>&1; then
    _use_zstd=1
fi

_ext="tar.xz"
if [ "$_use_zstd" -eq 1 ]; then
    _ext="tar.zst"
fi
_cache_tar="${_base_dir}/.github/cache/build-cache.${_ext}"

pushd "${_base_dir}" >/dev/null

if [ ! -d "build" ]; then
    echo "ERROR: No build directory found."
    exit 1
fi

mkdir -p "$(dirname "${_cache_tar}")"

# create archive via stream to avoid tar flag incompatibilities
if [ "$_use_zstd" -eq 1 ]; then
    tar -cf - "build" | zstd -f -T0 -3 -o "${_cache_tar}"
else
    tar -cf - "build" | xz -f -T0 -3 -c > "${_cache_tar}"
fi

popd >/dev/null
