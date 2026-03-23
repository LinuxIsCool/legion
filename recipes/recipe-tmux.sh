#!/usr/bin/env bash
# recipe-tmux.sh — install tmux with TPM (XDG paths, Wayland clipboard)
source "$(dirname "$0")/../lib/utils.sh"

readonly TPM_DIR="${HOME}/.config/tmux/plugins/tpm"

check() {
    has_cmd tmux && [[ -d "${TPM_DIR}" ]]
}

install() {
    if ! has_cmd tmux; then
        install_pacman tmux || return 1
    fi

    # Wayland clipboard support
    if ! has_cmd wl-copy; then
        install_pacman wl-clipboard || return 1
    fi

    # Install TPM to XDG config path
    if [[ ! -d "${TPM_DIR}" ]]; then
        log_info "Installing TPM (Tmux Plugin Manager)"
        mkdir -p "$(dirname "${TPM_DIR}")"
        git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
    fi

    log_info "Run prefix + I inside tmux to install plugins"
    log_ok "tmux"
}

main() {
    if check; then
        log_skip "tmux"
    else
        install
    fi
}

main "$@"
