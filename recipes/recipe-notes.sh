#!/usr/bin/env bash
# recipe-notes.sh — clone legion-brain and create symlinks
source "$(dirname "$0")/../lib/utils.sh"

readonly BRAIN_DIR="${HOME}/legion-brain"
readonly CLAUDE_LOCAL="${HOME}/.claude/local"

check() {
    [[ -d "${BRAIN_DIR}/.git" ]] && [[ -L "${CLAUDE_LOCAL}/journal" ]]
}

install() {
    # Clone legion-brain if missing
    if [[ ! -d "${BRAIN_DIR}/.git" ]]; then
        log_info "Cloning legion-brain"
        git clone git@github.com:LinuxIsCool/legion-brain.git "${BRAIN_DIR}"
    fi

    ensure_dir "${CLAUDE_LOCAL}"

    # Create symlinks
    local -A links=(
        ["${HOME}/CLAUDE.md"]="${BRAIN_DIR}/CLAUDE.md"
        ["${CLAUDE_LOCAL}/backlog"]="${BRAIN_DIR}/local/backlog"
        ["${CLAUDE_LOCAL}/claudematrix"]="${BRAIN_DIR}/local/claudematrix"
        ["${CLAUDE_LOCAL}/days"]="${BRAIN_DIR}/local/days"
        ["${CLAUDE_LOCAL}/dreams"]="${BRAIN_DIR}/local/dreams"
        ["${CLAUDE_LOCAL}/ground"]="${BRAIN_DIR}/local/ground"
        ["${CLAUDE_LOCAL}/inventory"]="${BRAIN_DIR}/local/inventory"
        ["${CLAUDE_LOCAL}/journal"]="${BRAIN_DIR}/local/journal"
        ["${CLAUDE_LOCAL}/marimo"]="${BRAIN_DIR}/local/marimo"
        ["${CLAUDE_LOCAL}/research"]="${BRAIN_DIR}/local/research"
        ["${CLAUDE_LOCAL}/scripts"]="${BRAIN_DIR}/scripts"
        ["${CLAUDE_LOCAL}/ventures"]="${BRAIN_DIR}/local/ventures"
    )

    for link_path in "${!links[@]}"; do
        local target="${links[$link_path]}"
        if ensure_symlink "$target" "$link_path"; then
            log_info "Linked: ${link_path} → ${target}"
        fi
    done

    log_ok "notes (legion-brain + 12 symlinks)"
}

main() {
    if check; then
        log_skip "notes"
    else
        install
    fi
}

main "$@"
