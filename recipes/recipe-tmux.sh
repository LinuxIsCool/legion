#!/usr/bin/env bash
# recipe-tmux.sh — install tmux with TPM
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd tmux && [[ -d "${HOME}/.tmux/plugins/tpm" ]]
}

install() {
    if ! has_cmd tmux; then
        install_pacman tmux || return 1
    fi

    # Install TPM
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
        log_info "Installing TPM (Tmux Plugin Manager)"
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
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
