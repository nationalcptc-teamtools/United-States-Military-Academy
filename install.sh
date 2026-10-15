#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
action=install
args=()
for arg in "$@"; do
    case "$arg" in
        --plan) action=plan ;;
        --check) action=check ;;
        *) args+=("$arg") ;;
    esac
done
python_cmd="${CPTC_PYTHON:-python3}"
if ! command -v "$python_cmd" >/dev/null 2>&1; then
    if [[ "$action" != install ]] || ! command -v apt-get >/dev/null 2>&1; then
        printf '%s\n' 'Python 3.10+ is required; preview/check never installs prerequisites.' >&2
        exit 1
    fi
    if [[ "${EUID}" -eq 0 ]]; then
        apt-get update
        env DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv
    else
        sudo apt-get update
        sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv
    fi
fi
exec "$python_cmd" "$repo_dir/tooling/farmkit/install.py" "$action" "${args[@]}"
