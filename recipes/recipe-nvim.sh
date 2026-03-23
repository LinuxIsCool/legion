#!/usr/bin/env bash
# recipe-nvim.sh — install Neovim + NVChad v2.0 core + custom config
source "$(dirname "$0")/../lib/utils.sh"

readonly NVIM_DIR="${HOME}/.config/nvim"
readonly NVCHAD_CORE="${NVIM_DIR}/lua/core"
readonly NVCHAD_CUSTOM="${NVIM_DIR}/lua/custom"

check() {
    has_cmd nvim && [[ -d "${NVCHAD_CORE}" ]] && [[ -d "${NVCHAD_CUSTOM}" ]]
}

install() {
    # 1. Neovim binary
    if ! has_cmd nvim; then
        install_pacman neovim || return 1
    fi

    # 2. Dependencies for fzf-lua (telescope alternative)
    if ! has_cmd rg; then
        install_pacman ripgrep || return 1
    fi
    if ! has_cmd fd; then
        install_pacman fd || return 1
    fi

    # 3. NVChad v2.0 core
    if [[ ! -d "${NVCHAD_CORE}" ]]; then
        # Clean up bad deployment (nvchadcustom at nvim root instead of lua/custom)
        if [[ -d "${NVIM_DIR}" ]] && [[ ! -d "${NVCHAD_CORE}" ]]; then
            log_info "Removing bad nvim deployment (custom at root, no NVChad core)"
            rm -rf "${NVIM_DIR}"
        fi
        log_info "Cloning NVChad v2.0 core"
        git clone --branch v2.0 --depth 1 https://github.com/NvChad/NvChad "${NVIM_DIR}"
    fi

    # 4. Custom config via chezmoi external
    if [[ ! -d "${NVCHAD_CUSTOM}" ]]; then
        log_info "Applying chezmoi for NVChad custom config"
        chezmoi apply "${HOME}/.config/nvim/lua/custom"
    fi

    log_info "Run nvim to let Lazy.nvim install plugins (1-2 min first launch)"
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
