#!/usr/bin/env bash
# lib/utils.sh — shared utilities for Legion bootstrap

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_ok() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_skip() {
    echo -e "${YELLOW}[—]${NC} $1 (already satisfied)"
}

log_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[·]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}━━━${NC} $1 ${BLUE}━━━${NC}"
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Ensure a pacman package is installed (non-sudo — just checks)
ensure_pacman() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Install package via pacman (writes to sudo script if needed)
install_pacman() {
    local pkg="$1"
    local sudo_script="${HOME}/.claude/local/scripts/install-${pkg}.sh"
    if pacman -Qi "$pkg" &>/dev/null; then
        log_skip "pacman: ${pkg}"
        return 0
    fi
    log_info "Package ${pkg} needs sudo to install"
    mkdir -p "$(dirname "$sudo_script")"
    cat > "$sudo_script" <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
sudo pacman -S --noconfirm ${pkg}
echo "Installed ${pkg}"
SCRIPT
    chmod +x "$sudo_script"
    log_fail "${pkg} not installed — run: bash ${sudo_script}"
    return 1
}

# Check OS is CachyOS/Arch
check_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "cachyos" || "$ID_LIKE" == *"arch"* ]]; then
            return 0
        fi
    fi
    log_fail "This system doesn't appear to be CachyOS/Arch"
    return 1
}

# Get hostname
get_hostname() {
    hostname
}

# Ensure directory exists
ensure_dir() {
    mkdir -p "$1"
}

# Create symlink idempotently
ensure_symlink() {
    local target="$1"
    local link_path="$2"

    if [[ -L "$link_path" ]]; then
        local current_target
        current_target="$(readlink "$link_path")"
        if [[ "$current_target" == "$target" ]]; then
            return 0
        fi
        rm "$link_path"
    elif [[ -e "$link_path" ]]; then
        log_fail "Cannot create symlink — ${link_path} exists and is not a symlink"
        return 1
    fi

    ln -s "$target" "$link_path"
}

list_profiles() {
    local profiles_dir="$1"
    echo "Available profiles:"
    for f in "${profiles_dir}"/*.toml; do
        [[ -f "$f" ]] || continue
        local name
        name="$(basename "$f" .toml)"
        local desc
        desc="$(grep '^description' "$f" | head -1 | sed 's/description *= *"//' | sed 's/"$//')"
        echo "  ${name}: ${desc}"
    done
}
