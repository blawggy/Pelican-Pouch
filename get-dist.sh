#!/usr/bin/env bash
# Detect Linux distribution and run remote installer script for that distro.

set -euo pipefail

run_distro_script() {
    local dist=""
    # Detect distro
    for f in /etc/os-release /etc/lsb-release /etc/redhat-release /etc/debian_version; do
        [[ -e "$f" ]] || continue
        case "$f" in
            /etc/os-release)
                # shellcheck disable=SC1091
                . /etc/os-release 2>/dev/null
                dist="${ID:-${NAME:-}}"
                ;;
            /etc/lsb-release)
                # shellcheck disable=SC1091
                . /etc/lsb-release 2>/dev/null
                dist="${DISTRIB_ID:-}"
                ;;
            /etc/redhat-release)
                dist=$(sed 's/ release.*//' /etc/redhat-release | tr '[:upper:]' '[:lower:]')
                ;;
            /etc/debian_version)
                dist="debian"
                ;;
        esac
        [[ -n "$dist" ]] && break
    done

    dist=${dist:-unknown}
    # Normalize: lowercase, strip after first non-alnum
    dist=$(printf '%s' "$dist" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9].*$//')

    local url="https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/${dist}.sh"

    echo "Detected distro: $dist"
    echo "Fetching: $url"

    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl not found." >&2
        return 1
    fi

    # Prefer process substitution with bash; fallback to pipe into sh if something fails.
    if command -v bash >/dev/null 2>&1; then
        if ! bash <(curl -fsSL "$url"); then
            echo "Remote script execution failed (bash). URL: $url" >&2
            return 1
        fi
    else
        echo "bash not found, falling back to sh | pipe"
        if ! curl -fsSL "$url" | sh; then
            echo "Remote script execution failed (sh). URL: $url" >&2
            return 1
        fi
    fi
}

run_distro_script