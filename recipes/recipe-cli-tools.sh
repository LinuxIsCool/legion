#!/usr/bin/env bash
# recipe-cli-tools.sh — essential CLI utilities (zoxide, fzf, just)
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd zoxide && has_cmd fzf && has_cmd just
}

install() {
    local needs_install=false

    # zoxide — smart directory jumping (z, zi)
    if ! has_cmd zoxide; then
        install_pacman zoxide || needs_install=true
    else
        log_skip "zoxide"
    fi

    # fzf — fuzzy finder (powers zi, tmux-text-macros, etc.)
    if ! has_cmd fzf; then
        install_pacman fzf || needs_install=true
    else
        log_skip "fzf"
    fi

    # just — command runner (justfiles)
    if ! has_cmd just; then
        install_pacman just || needs_install=true
    else
        log_skip "just"
    fi

    if [[ "$needs_install" == "true" ]]; then
        return 1
    fi

    log_ok "cli-tools"
}

main() {
    if check; then
        log_skip "cli-tools"
    else
        install
    fi
}

main "$@"
