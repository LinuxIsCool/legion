#!/usr/bin/env bash
# recipe-nvim.sh — install Neovim + the NVChad v2.5 config (LinuxIsCool/legion-nvim).
# In v2.5 the whole ~/.config/nvim is a single repo (cloned by the chezmoi external),
# not the old NVChad-base + lua/custom split.
source "$(dirname "$0")/../lib/utils.sh"

readonly NVIM_DIR="${HOME}/.config/nvim"

check() {
    has_cmd nvim && [[ -f "${NVIM_DIR}/init.lua" ]] && [[ -d "${NVIM_DIR}/lua/configs" ]]
}

install() {
    # 1. Neovim binary (>= 0.11 required for the vim.lsp.config / vim.lsp.enable API)
    if ! has_cmd nvim; then
        install_pacman neovim || return 1
    fi

    # 2. Search deps for fzf-lua
    if ! has_cmd rg; then
        install_pacman ripgrep || return 1
    fi
    if ! has_cmd fd; then
        install_pacman fd || return 1
    fi

    # 3. Config via chezmoi external (clones LinuxIsCool/legion-nvim -> ~/.config/nvim).
    #    LSP servers, formatters and the tree-sitter CLI are auto-installed on first
    #    launch by mason-tool-installer; treesitter parsers compile via that CLI.
    if [[ ! -f "${NVIM_DIR}/init.lua" ]]; then
        log_info "Applying chezmoi external for legion-nvim config"
        chezmoi apply "${NVIM_DIR}"
    fi

    log_info "Run nvim once to let lazy.nvim install plugins + mason tools (first launch ~2-3 min)"
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
