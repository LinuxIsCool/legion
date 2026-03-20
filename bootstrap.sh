#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/recipe-runner.sh"

usage() {
    cat <<EOF
Usage: ./bootstrap.sh --profile <name> [--dry-run]
       ./bootstrap.sh --list

Options:
  --profile <name>   Run recipes from profiles/<name>.toml
  --list             List available profiles
  --dry-run          Show what would run without executing
  -h, --help         Show this help
EOF
}

main() {
    local profile=""
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile) profile="$2"; shift 2 ;;
            --list) list_profiles "${SCRIPT_DIR}/profiles"; exit 0 ;;
            --dry-run) dry_run=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) log_fail "Unknown argument: $1"; usage; exit 1 ;;
        esac
    done

    if [[ -z "$profile" ]]; then
        log_fail "Missing --profile argument"
        usage
        exit 1
    fi

    local profile_path="${SCRIPT_DIR}/profiles/${profile}.toml"
    if [[ ! -f "$profile_path" ]]; then
        log_fail "Profile not found: ${profile_path}"
        list_profiles "${SCRIPT_DIR}/profiles"
        exit 1
    fi

    log_ok "Legion Bootstrap — profile: ${profile}"
    echo ""

    run_profile "$profile_path" "${SCRIPT_DIR}/recipes" "$dry_run"
}

main "$@"
