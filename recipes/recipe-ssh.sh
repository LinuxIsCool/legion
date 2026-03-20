#!/usr/bin/env bash
# recipe-ssh.sh — ensure SSH keys are in place
source "$(dirname "$0")/../lib/utils.sh"

check() {
    [[ -f "${HOME}/.ssh/id_rsa" ]] && [[ -f "${HOME}/.ssh/id_rsa.pub" ]]
}

install() {
    ensure_dir "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    # Keys should be deployed by chezmoi (age-encrypted)
    # If they're missing, chezmoi apply didn't work or age key is missing
    if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
        log_fail "SSH private key not found — ensure age key is at ~/.config/chezmoi/key.txt"
        log_info "Then run: chezmoi apply"
        return 1
    fi

    chmod 600 "${HOME}/.ssh/id_rsa"
    chmod 644 "${HOME}/.ssh/id_rsa.pub"
    [[ -f "${HOME}/.ssh/config" ]] && chmod 600 "${HOME}/.ssh/config"

    log_ok "ssh"
}

main() {
    if check; then
        log_skip "ssh"
    else
        install
    fi
}

main "$@"
