#!/usr/bin/env bash
# recipe-keyd.sh — generate keyd configuration script (caps→esc/ctrl)
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd keyd && [[ -f /etc/keyd/default.conf ]]
}

install() {
    local sudo_script="${HOME}/.claude/local/scripts/setup-keyd.sh"
    mkdir -p "$(dirname "$sudo_script")"

    cat > "$sudo_script" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Install keyd
sudo pacman -S --noconfirm keyd

# Configure caps lock as escape (tap) / control (hold)
sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf > /dev/null <<EOF
[ids]
*

[main]
capslock = overload(control, esc)
EOF

# Enable and start
sudo systemctl enable keyd
sudo systemctl restart keyd

echo "keyd configured: CapsLock → Esc (tap) / Ctrl (hold)"
SCRIPT
    chmod +x "$sudo_script"

    log_info "keyd requires sudo setup"
    log_info "Run: bash ${sudo_script}"
    log_ok "keyd (script generated)"
}

main() {
    if check; then
        log_skip "keyd"
    else
        install
    fi
}

main "$@"
