#!/usr/bin/env bash
# recipe-fish.sh — ensure fish shell is installed and set as default
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd fish && [[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" == "fish" ]]
}

install() {
    if ! has_cmd fish; then
        install_pacman fish || return 1
    fi

    # Check if fish is the default shell
    local current_shell
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$(basename "$current_shell")" != "fish" ]]; then
        local fish_path
        fish_path="$(which fish)"
        log_info "Fish is installed but not the default shell"
        log_info "Run: chsh -s ${fish_path}"

        local sudo_script="${HOME}/.claude/local/scripts/set-fish-default.sh"
        mkdir -p "$(dirname "$sudo_script")"
        cat > "$sudo_script" <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
chsh -s $(which fish) ${USER}
echo "Default shell set to fish"
SCRIPT
        chmod +x "$sudo_script"
        log_info "Run: bash ${sudo_script}"
    fi

    # Install fisher if not present
    if [[ ! -f "${HOME}/.config/fish/functions/fisher.fish" ]]; then
        log_info "Installing fisher plugin manager"
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
    fi

    log_ok "fish"
}

main() {
    if check; then
        log_skip "fish"
    else
        install
    fi
}

main "$@"
