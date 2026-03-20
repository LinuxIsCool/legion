#!/usr/bin/env bash
# recipe-fnm.sh — install fnm (Fast Node Manager) and default Node.js
source "$(dirname "$0")/../lib/utils.sh"

readonly NODE_VERSION="24"

check() {
    has_cmd fnm && fnm ls 2>/dev/null | grep -q "v${NODE_VERSION}"
}

install() {
    if ! has_cmd fnm; then
        log_info "Installing fnm"
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    fi

    # Ensure fnm is on PATH for this session
    export PATH="${HOME}/.local/share/fnm:${PATH}"

    if ! fnm ls 2>/dev/null | grep -q "v${NODE_VERSION}"; then
        log_info "Installing Node.js v${NODE_VERSION}"
        fnm install "${NODE_VERSION}"
        fnm default "${NODE_VERSION}"
    fi

    log_ok "fnm (Node v${NODE_VERSION})"
}

main() {
    if check; then
        log_skip "fnm"
    else
        install
    fi
}

main "$@"
