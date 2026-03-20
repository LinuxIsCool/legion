#!/usr/bin/env bash
# recipe-docker-services.sh — ensure Docker and compose files for hippo + letta
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd docker && docker info &>/dev/null && \
    [[ -f "${HOME}/.config/hippo/compose.yaml" ]] && \
    [[ -f "${HOME}/.config/letta/compose.yaml" ]]
}

install() {
    if ! has_cmd docker; then
        local sudo_script="${HOME}/.claude/local/scripts/install-docker.sh"
        mkdir -p "$(dirname "$sudo_script")"
        cat > "$sudo_script" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
sudo pacman -S --noconfirm docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
echo "Docker installed. Log out and back in for group changes."
SCRIPT
        chmod +x "$sudo_script"
        log_info "Docker needs sudo to install"
        log_info "Run: bash ${sudo_script}"
        return 1
    fi

    if ! docker info &>/dev/null; then
        log_fail "Docker is installed but not running or user not in docker group"
        return 1
    fi

    # Pull images
    log_info "Pulling FalkorDB image"
    docker pull falkordb/falkordb:latest 2>/dev/null || true

    log_info "Pulling Letta images"
    if [[ -f "${HOME}/.config/letta/compose.yaml" ]]; then
        docker compose -f "${HOME}/.config/letta/compose.yaml" pull --quiet 2>/dev/null || true
    fi

    log_ok "docker-services"
}

main() {
    if check; then
        log_skip "docker-services"
    else
        install
    fi
}

main "$@"
