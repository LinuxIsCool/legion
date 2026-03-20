#!/usr/bin/env bash
# recipe-fonts.sh — install Nerd Fonts and CachyOS font packages
source "$(dirname "$0")/../lib/utils.sh"

check() {
    # Check for key font packages
    ensure_pacman ttf-jetbrains-mono-nerd 2>/dev/null && ensure_pacman noto-fonts 2>/dev/null
}

install() {
    local packages=(
        ttf-jetbrains-mono-nerd
        ttf-firacode-nerd
        noto-fonts
        noto-fonts-emoji
    )

    local missing=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        local sudo_script="${HOME}/.claude/local/scripts/install-fonts.sh"
        mkdir -p "$(dirname "$sudo_script")"
        cat > "$sudo_script" <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
sudo pacman -S --noconfirm ${missing[*]}
fc-cache -fv
echo "Fonts installed: ${missing[*]}"
SCRIPT
        chmod +x "$sudo_script"
        log_info "Missing fonts: ${missing[*]}"
        log_info "Run: bash ${sudo_script}"
        return 1
    fi

    log_ok "fonts"
}

main() {
    if check; then
        log_skip "fonts"
    else
        install
    fi
}

main "$@"
