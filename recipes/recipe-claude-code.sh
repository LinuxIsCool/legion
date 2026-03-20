#!/usr/bin/env bash
# recipe-claude-code.sh — install Claude Code CLI, clone legion-plugins, deploy settings
source "$(dirname "$0")/../lib/utils.sh"

readonly PLUGINS_DIR="${HOME}/.claude/plugins/local/legion-plugins"

check() {
    has_cmd claude && [[ -d "${PLUGINS_DIR}/.git" ]] && [[ -f "${HOME}/.claude/settings.json" ]]
}

install() {
    # Install Claude Code CLI
    if ! has_cmd claude; then
        log_info "Installing Claude Code CLI"
        if has_cmd npm; then
            npm install -g @anthropic-ai/claude-code
        elif [[ -f "${HOME}/.local/share/fnm/node-versions/v24.14.0/installation/bin/npm" ]]; then
            "${HOME}/.local/share/fnm/node-versions/v24.14.0/installation/bin/npm" install -g @anthropic-ai/claude-code
        else
            log_fail "npm not found — run recipe-fnm first"
            return 1
        fi
    fi

    # Clone legion-plugins
    if [[ ! -d "${PLUGINS_DIR}/.git" ]]; then
        log_info "Cloning legion-plugins"
        ensure_dir "${HOME}/.claude/plugins/local"
        git clone git@github.com:LinuxIsCool/legion-plugins.git "${PLUGINS_DIR}"
    fi

    # settings.json is deployed by chezmoi
    if [[ ! -f "${HOME}/.claude/settings.json" ]]; then
        log_info "settings.json missing — running chezmoi apply"
        chezmoi apply
    fi

    log_ok "claude-code"
}

main() {
    if check; then
        log_skip "claude-code"
    else
        install
    fi
}

main "$@"
