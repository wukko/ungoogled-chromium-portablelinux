#!/bin/bash
set -euxo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd ../.. && pwd)"
_cache_zst="${_base_dir}/.github/cache/build-cache.tar.zst"
_cache_xz="${_base_dir}/.github/cache/build-cache.tar.xz"

_cache_tar=""
if [ -f "${_cache_zst}" ]; then
    _cache_tar="${_cache_zst}"
elif [ -f "${_cache_xz}" ]; then
    _cache_tar="${_cache_xz}"
fi

if [ -z "${_cache_tar}" ]; then
    echo "No cache archive found to import (${_cache_zst} or ${_cache_xz}). Skipping."
    exit 0
fi

echo "Extracting cache archive ${_cache_tar} into repo root"

mkdir -p "${_base_dir}"
if [[ "${_cache_tar}" == *.tar.zst ]]; then
    zstd -d -c "${_cache_tar}" | tar -xf - -C "${_base_dir}"
else
    xz -d -c "${_cache_tar}" | tar -xf - -C "${_base_dir}"
fi

echo "Cache import done."
