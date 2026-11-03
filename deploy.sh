#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
repo_url="${REPO_URL:-https://github.com/Anton-Sergeev-EA/shvirtd-example-python.git}"
install_dir="${INSTALL_DIR:-/opt/shvirtd-example-python}"
command -v git >/dev/null
command -v docker >/dev/null
docker info >/dev/null
version="$(docker compose version --short)"
version="${version#v}"
if [[ "$(printf '%s\n' 2.24.0 "$version" | sort -V | head -n1)" != 2.24.0 ]]; then
    printf 'Docker Compose >= 2.24.0 is required.\n' >&2
    exit 1
fi
if [[ ! -d "$install_dir" ]]; then
    git clone -- "$repo_url" "$install_dir"
elif [[ ! -d "$install_dir/.git" ]]; then
    printf 'Target is not a Git repository: %s\n' "$install_dir" >&2
    exit 1
else
    actual_url="$(git -C "$install_dir" remote get-url origin)"
    [[ "$actual_url" == "$repo_url" ]] || { printf 'Unexpected origin URL.\n' >&2; exit 1; }
    git -C "$install_dir" diff --quiet
    git -C "$install_dir" diff --cached --quiet
    git -C "$install_dir" pull --ff-only
fi
cd "$install_dir"
[[ -f .env ]] || { printf 'Required .env is missing.\n' >&2; exit 1; }
docker compose config --quiet
docker compose up --build --detach --wait --wait-timeout 240
curl --noproxy '*' --fail --show-error --silent --location --retry 20 --retry-connrefused --retry-delay 2 http://127.0.0.1:8090
printf '\n'
