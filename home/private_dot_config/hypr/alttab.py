#!/usr/bin/env python3
"""
Alt-Tab switcher for Hyprland using submaps for true Alt-key detection.

init         — first press: snapshot MRU, jump to previous window, enter submap
init_reverse — same but start from the oldest window
next         — called by Tab in submap: advance forward
reverse      — called by Shift+Tab in submap: go backward
"""
import json, os, pickle, socket as _sock, sys, time

LOG = "/tmp/hypr-alttab.log"
def log(msg):
    with open(LOG, "a") as f:
        f.write(f"{time.monotonic():.3f} {msg}\n")

STATE_FILE = "/tmp/hypr-alttab.pkl"

def _sock_path():
    sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    rt  = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
    return f"{rt}/hypr/{sig}/.socket.sock"

def hypr_query(cmd):
    with _sock.socket(_sock.AF_UNIX, _sock.SOCK_STREAM) as s:
        s.connect(_sock_path())
        s.send(cmd.encode())
        return s.recv(65536).decode()

def hypr_dispatch(cmd):
    with _sock.socket(_sock.AF_UNIX, _sock.SOCK_STREAM) as s:
        s.connect(_sock_path())
        s.send(cmd.encode())
        s.recv(1024)

def clients_mru():
    clients = json.loads(hypr_query("j/clients"))
    visible = [c for c in clients
               if c.get("mapped") and not c.get("hidden")
               and c.get("workspace", {}).get("id", 0) > 0]
    visible.sort(key=lambda c: c.get("focusHistoryID", 9999))
    return [c["address"] for c in visible]

def focus(addr):
    hypr_dispatch(f'dispatch hl.dsp.focus({{window="address:{addr}"}})')

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "init"

    if mode in ("init", "init_reverse"):
        addrs = clients_mru()
        if len(addrs) < 2:
            return
        idx = (len(addrs) - 1) if mode == "init_reverse" else 1
        log(f"init  addrs={[a[-4:] for a in addrs]} → focus [{idx}]={addrs[idx][-4:]}")
        focus(addrs[idx])
        with open(STATE_FILE, "wb") as f:
            pickle.dump({"addrs": addrs, "idx": idx}, f)

    elif mode in ("next", "reverse"):
        try:
            with open(STATE_FILE, "rb") as f:
                state = pickle.load(f)
        except Exception:
            log("next/reverse: no state file")
            return
        addrs = state["addrs"]
        step  = -1 if mode == "reverse" else 1
        idx   = (state["idx"] + step) % len(addrs)
        log(f"{mode} addrs={[a[-4:] for a in addrs]} → focus [{idx}]={addrs[idx][-4:]}")
        focus(addrs[idx])
        with open(STATE_FILE, "wb") as f:
            pickle.dump({"addrs": addrs, "idx": idx}, f)

if __name__ == "__main__":
    main()
