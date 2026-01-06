#!/usr/bin/env bash
# Detect Linux distribution and run remote installer script for that distro.

set -euo pipefail

run_distro_script() {
    local dist=""
    local version=""
    
    # Detect distro
    if [[ -e /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release 2>/dev/null
        dist="${ID:-}"
        version="${VERSION_ID:-}"
    elif [[ -e /etc/lsb-release ]]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release 2>/dev/null
        dist="${DISTRIB_ID:-}"
        version="${DISTRIB_RELEASE:-}"
    elif [[ -e /etc/redhat-release ]]; then
        dist=$(sed 's/ release.*//' /etc/redhat-release | tr '[:upper:]' '[:lower:]')
        version=$(grep -oP '(?<=release )[0-9]+' /etc/redhat-release 2>/dev/null || echo "")
    elif [[ -e /etc/debian_version ]]; then
        dist="debian"
        version=$(cat /etc/debian_version | cut -d. -f1)
    fi

    dist=${dist:-unknown}
    # Normalize: lowercase, strip spaces and special chars
    dist=$(printf '%s' "$dist" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9].*$//')
    
    # Map distro names to standardized names
    case "$dist" in
        almalinux|alma) dist="almalinux" ;;
        rocky|rockylinux) dist="rocky" ;;
        centos|centosstream) dist="centos" ;;
        ubuntu) dist="ubuntu" ;;
        debian) dist="debian" ;;
    esac

    local url="https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/${dist}.sh"

    echo "Detected distro: $dist${version:+ $version}"
    
    # Warn about limited support versions
    case "$dist" in
        almalinux|rocky)
            if [[ "$version" == "8" ]] || [[ "$version" == "9" ]]; then
                echo "Warning: $dist $version has no SQLite support" >&2
            fi
            ;;
        debian)
            if [[ "$version" == "11" ]]; then
                echo "Warning: Debian 11 has no SQLite support" >&2
            fi
            ;;
    esac
    
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