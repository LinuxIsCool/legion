#!/usr/bin/env bash
# recipe-cli-tools.sh — essential CLI utilities (zoxide, fzf, autojump)
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd zoxide && has_cmd fzf && [[ -x "${HOME}/.autojump/bin/autojump" ]]
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

    # autojump — learned directory jumping (`j`).  It is installed in the
    # user's home so a fresh bootstrap needs no privileged AUR installation.
    if [[ ! -x "${HOME}/.autojump/bin/autojump" ]]; then
        local autojump_version="22.5.3"
        local autojump_archive
        local autojump_dir
        autojump_archive="$(mktemp)"
        autojump_dir="$(mktemp -d)"
        log_info "Installing autojump ${autojump_version} to ~/.autojump"
        if curl -fL --retry 3 --output "$autojump_archive" \
            "https://github.com/wting/autojump/archive/refs/tags/release-v${autojump_version}.tar.gz" \
            && tar -xzf "$autojump_archive" -C "$autojump_dir" --strip-components=1 \
            && (cd "$autojump_dir" && python install.py --destdir "${HOME}/.autojump"); then
            log_ok "autojump ${autojump_version}"
        else
            log_fail "autojump could not be installed"
            needs_install=true
        fi
        rm -f "$autojump_archive"
        rm -rf "$autojump_dir"
    else
        log_skip "autojump"
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
