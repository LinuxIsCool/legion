# Default interactive tmux to the socket that survives a compositor crash.
#
# On 2026-08-11 at 13:47:08 a global OOM made Hyprland segfault. Under uwsm that
# stops graphical-session.target, which stops app-graphical.slice, which reaps
# every tmux-spawn-*.scope inside it. Twenty-one Claude Code sessions went with
# it. tmux had daemonized; that never mattered, because cgroup placement decides
# survival, not fork behaviour.
#
# tmux-persist.service runs a server on the "persist" socket inside app.slice,
# which has no PartOf and no BoundBy, so nothing propagates a stop to it.
# Linger is on, so it also survives logout.
#
# These are abbreviations, not functions or aliases, on purpose: fish expands
# them in place so you always SEE the command you are about to run, and nothing
# is shadowed for scripts, systemd units, or `command tmux`.

if status is-interactive
    # `tm` — attach to the durable main session, creating it if absent.
    abbr -a tm 'tmux -L persist new -A -s main'
    # `tmux` — same server for everything else (ls, kill-session, attach ...).
    abbr -a tmux 'tmux -L persist'
    # Escape hatch, for when you really do want the fragile default socket.
    abbr -a tmux-default 'command tmux'
end
