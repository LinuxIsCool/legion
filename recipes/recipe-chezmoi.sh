#!/usr/bin/env bash
# recipe-chezmoi.sh — install chezmoi and initialize from local source
source "$(dirname "$0")/../lib/utils.sh"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

check() {
    has_cmd chezmoi && [[ -d "${HOME}/.local/share/chezmoi" ]]
}

install() {
    if ! has_cmd chezmoi; then
        install_pacman chezmoi || return 1
    fi

    log_info "Initializing chezmoi from ${REPO_DIR}/home"
    chezmoi init --source "${REPO_DIR}/home" --apply=false

    log_info "Running chezmoi apply"
    chezmoi apply

    log_ok "chezmoi"
}

main() {
    if check; then
        log_skip "chezmoi"
    else
        install
    fi
}

main "$@"
