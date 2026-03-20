#!/usr/bin/env bash
# recipe-tailscale.sh — install and connect to Tailscale mesh
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd tailscale && tailscale status &>/dev/null
}

install() {
    if ! has_cmd tailscale; then
        local sudo_script="${HOME}/.claude/local/scripts/install-tailscale.sh"
        mkdir -p "$(dirname "$sudo_script")"
        cat > "$sudo_script" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
sudo pacman -S --noconfirm tailscale
sudo systemctl enable --now tailscaled
tailscale up
SCRIPT
        chmod +x "$sudo_script"
        log_info "Tailscale needs sudo to install and authenticate"
        log_info "Run: bash ${sudo_script}"
        return 1
    fi

    if ! tailscale status &>/dev/null; then
        log_info "Tailscale installed but not connected"
        log_info "Run: tailscale up"
        return 1
    fi

    log_ok "tailscale"
}

main() {
    if check; then
        log_skip "tailscale"
    else
        install
    fi
}

main "$@"
