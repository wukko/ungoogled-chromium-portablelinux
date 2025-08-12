#!/bin/bash
set -euo pipefail

_base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && cd .. && pwd)"
_git_submodule="ungoogled-chromium"

_image="chromium-builder:trixie-slim"

echo "building docker image '${_image}'"
if ! docker image inspect "${_image}" >/dev/null 2>&1; then
(
    cd "${_base_dir}/docker" && docker buildx build --load -t "${_image}" -f ./build.Dockerfile .
)
fi

# choose entrypoint: CI or local
_entrypoint="/repo/scripts/build.sh"
if [ -n "${_task_timeout:-${TASK_TIMEOUT:-}}" ] || [ -n "${_prepare_only:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
    _entrypoint="/repo/.github/scripts/build.sh"
fi

# forward relevant envs when set
_extra_env=()
[ -n "${_task_timeout:-}" ] && _extra_env+=(-e "_task_timeout")
[ -n "${TASK_TIMEOUT:-}" ] && _extra_env+=(-e "TASK_TIMEOUT")
[ -n "${_prepare_only:-}" ] && _extra_env+=(-e "_prepare_only")

# match host user to avoid permission issues on bind mount
_user_uidgid="$(id -u):$(id -g)"

_build_start=$(date)
echo "docker build start at ${_build_start}"

cd "${_base_dir}" && docker run --rm -i \
    -u "${_user_uidgid}" \
    -v "${_base_dir}:/repo" \
    "${_extra_env[@]}" "${_image}" bash "${_entrypoint}" "$@"

_build_end=$(date)
echo -e "docker build start at ${_build_start}, end at ${_build_end}"
