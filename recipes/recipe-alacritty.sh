#!/usr/bin/env bash
# recipe-alacritty.sh — ensure alacritty terminal is installed
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd alacritty
}

install() {
    install_pacman alacritty || return 1
    log_ok "alacritty"
}

main() {
    if check; then
        log_skip "alacritty"
    else
        install
    fi
}

main "$@"
