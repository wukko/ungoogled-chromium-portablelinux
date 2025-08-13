#!/bin/bash
set -euxo pipefail

. "/repo/scripts/shared.sh"

setup_paths

_prepare_only="${_prepare_only:-0}"
_task_timeout="${_task_timeout:-${TASK_TIMEOUT:-}}"

if [ "${_prepare_only}" = "1" ]; then
    fetch_sources false
    apply_patches
    apply_domsub
    write_gn_args
    fix_tool_downloading
    setup_toolchain
    gn_gen

    echo "Preheat done"
    exit 0
fi

if [ -z "${_task_timeout}" ]; then
    echo "ERROR: _task_timeout (or TASK_TIMEOUT) must be set (seconds)" >&2
    exit 1
fi

# if already built, skip
if [ -x "${_out_dir}/chrome" ] && [ -x "${_out_dir}/chromedriver" ]; then
    echo "Build artifacts already present"
    exit 0
fi

echo "Running ninja with timeout ${_task_timeout}s"
set +e
timeout --preserve-status -s INT "${_task_timeout}"s ninja -C out/Default chrome chromedriver
rc=$?
set -e
if [ "$rc" -eq 124 ]; then
    echo "Task timed out after ${_task_timeout}s; continuing in next run."
    command -v ccache >/dev/null 2>&1 && ccache -s || true
    exit 0
fi
command -v ccache >/dev/null 2>&1 && ccache -s || true
exit "$rc"
