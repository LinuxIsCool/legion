#!/usr/bin/env bash
# recipe-github.sh — ensure gh CLI is installed and authenticated
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd gh && gh auth status &>/dev/null
}

install() {
    if ! has_cmd gh; then
        install_pacman github-cli || return 1
    fi

    if ! gh auth status &>/dev/null; then
        log_info "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
        return 1
    fi

    log_ok "github"
}

main() {
    if check; then
        log_skip "github"
    else
        install
    fi
}

main "$@"
