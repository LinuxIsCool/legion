#!/usr/bin/env bash
# recipe-kanata.sh — install kanata + config (caps→esc/ctrl, Legion AI button→clean right-Super)
# Supersedes recipe-keyd.sh on the Legion: kanata does the caps overload AND reclaims the
# Copilot/AI button (which hardware-emits lmet+lsft+f23) as a held right-Super via defchordsv2.
# NOTE: the config's linux-dev-names-include + AI-button chord are Legion-specific hardware.
# The e15/travel profile keeps recipe-keyd.sh.
source "$(dirname "$0")/../lib/utils.sh"

check() {
    has_cmd kanata && [[ -f /etc/kanata/kanata.kbd ]]
}

install() {
    local sudo_script="${HOME}/.claude/local/scripts/setup-kanata.sh"
    mkdir -p "$(dirname "$sudo_script")"

    cat > "$sudo_script" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Install kanata from the AUR (paru manages its own sudo escalation — do NOT prefix with sudo)
if ! command -v kanata >/dev/null 2>&1; then
    paru -S --noconfirm kanata-bin
fi

# Keyboard remap config (caps overload + Legion AI-button → clean right-Super)
sudo mkdir -p /etc/kanata
sudo tee /etc/kanata/kanata.kbd > /dev/null <<'KBD'
;; Minimal, SUPER-safe config + reclaimed right-Super from the Legion AI button.
;; kanata remaps caps (tap=esc / hold=lctl) and reclaims the Copilot/AI button.
;; lmet/lsft stay native so SUPER and SHIFT remain reliable held modifiers.
(defcfg
  process-unmapped-keys yes
  concurrent-tap-hold   yes        ;; required by defchordsv2 (also sharpens caps tap-hold)
  chords-v2-min-idle    100        ;; while typing, chord processing is skipped -> native keys stay instant
  linux-dev-names-include (
    "ITE Tech. Inc. ITE Device(8258) Keyboard"
  )
)

(defsrc
  caps
)

(defalias
  caps-key (tap-hold-press 200 200 esc lctl)
)

(deflayer base
  @caps-key
)

;; The Legion Copilot/AI button hardware-emits lmet + lsft + f23 as one chord,
;; SUSTAINED while held (confirmed via wev 2026-07-01: all three stay down ~3s).
;; Recognize exactly that combo and emit a single CLEAN right-Super (rmet), held
;; (all-released) until the button is let go. kanata consumes all three keys, so
;; NO stray left-Super and NO stray Shift leak. Real Super+Shift (no f23) is
;; untouched because f23 is required to trigger the chord.
(defchordsv2
  (lmet lsft f23) rmet 25 all-released ()
)
KBD

# systemd service
sudo tee /etc/systemd/system/kanata.service > /dev/null <<'UNIT'
[Unit]
Description=kanata keyboard remapper
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/kanata --cfg /etc/kanata/kanata.kbd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable kanata
sudo systemctl restart kanata

echo "kanata configured: CapsLock → Esc(tap)/Ctrl(hold), AI button → clean held right-Super"
SCRIPT
    chmod +x "$sudo_script"

    log_info "kanata requires sudo setup (installs AUR kanata-bin + writes /etc config + service)"
    log_info "Run: bash ${sudo_script}"
    log_ok "kanata (script generated)"
}

main() {
    if check; then
        log_skip "kanata"
    else
        install
    fi
}

main "$@"
