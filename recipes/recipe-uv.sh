#!/usr/bin/env bash
# recipe-uv.sh — install uv Python package manager
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd uv
}

install() {
    log_info "Installing uv via official installer"
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Verify
    if has_cmd uv || [[ -f "${HOME}/.local/bin/uv" ]]; then
        log_ok "uv"
    else
        log_fail "uv installation failed"
        return 1
    fi
}

main() {
    if check; then
        log_skip "uv"
    else
        install
    fi
}

main "$@"
