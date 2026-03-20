#!/usr/bin/env bash
# recipe-nvim.sh — install Neovim (config via chezmoi externals)
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd nvim
}

install() {
    if ! has_cmd nvim; then
        install_pacman neovim || return 1
    fi

    # NVChad config is pulled by chezmoi externals (.chezmoiexternal.toml)
    # Just ensure chezmoi has been applied
    if [[ ! -d "${HOME}/.config/nvim" ]]; then
        log_info "Running chezmoi apply for nvim config"
        chezmoi apply
    fi

    log_ok "nvim"
}

main() {
    if check; then
        log_skip "nvim"
    else
        install
    fi
}

main "$@"
