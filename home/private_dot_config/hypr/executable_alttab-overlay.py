#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gtk4LayerShell', '1.0')
from gi.repository import Gtk, Gtk4LayerShell, GLib, Gdk

import json
import os
import socket as _sock
import threading
import sys

DAEMON_SOCK = "/tmp/hypr-alttab.sock"
ICON_SIZE   = 48
TITLE_MAX   = 22

def _hypr_sock():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    rt  = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
    return f"{rt}/hypr/{sig}/.socket.sock"

def hypr_cmd(cmd):
    with _sock.socket(_sock.AF_UNIX, _sock.SOCK_STREAM) as s:
        s.connect(_hypr_sock())
        s.sendall(cmd.encode())
        chunks = []
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            chunks.append(chunk)
    return b"".join(chunks).decode()

def clients_mru():
    try:
        clients = json.loads(hypr_cmd("j/clients"))
        visible = [c for c in clients
                   if c.get("mapped") and not c.get("hidden")
                   and c.get("workspace", {}).get("id", 0) > 0]
        visible.sort(key=lambda c: c.get("focusHistoryID", 9999))
        return visible
    except Exception:
        return []

def focus_window(address):
    try:
        hypr_cmd(f'dispatch hl.dsp.focus({{window="address:{address}"}})')
    except Exception:
        pass

def resolve_icon(class_name):
    theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
    candidates = [
        class_name,
        class_name.lower(),
        class_name.split(".")[-1].lower(),
        class_name.split(".")[0].lower(),
    ]
    for name in candidates:
        if name:
            try:
                if theme.has_icon(name):
                    return name
            except Exception:
                pass
    return "application-x-executable"

CSS = b"""
window { background: transparent; }
.switcher-bg {
    background-color: rgba(16, 16, 26, 0.90);
    border-radius: 16px;
    border: 1px solid rgba(255,255,255,0.10);
}
.card {
    border-radius: 10px;
    padding: 10px 14px;
    min-width: 90px;
}
.card-selected {
    background-color: rgba(100,140,255,0.28);
    border-radius: 10px;
    border: 2px solid rgba(130,170,255,0.85);
    padding: 10px 14px;
    min-width: 90px;
}
.card-title {
    color: rgba(235,235,255,0.92);
    font-size: 11px;
}
.card-workspace {
    color: rgba(160,190,255,0.60);
    font-size: 10px;
}
"""

class OverlayWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_decorated(False)
        self.set_resizable(False)

        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.BOTTOM, True)
        Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.BOTTOM, 80)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.NONE)

        css = Gtk.CssProvider()
        css.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        # Key controller — active only when overlay is visible (EXCLUSIVE mode)
        self._key_ctrl = Gtk.EventControllerKey()
        self._key_ctrl.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        self._key_ctrl.connect("key-pressed",  self._on_key_pressed)
        self._key_ctrl.connect("key-released", self._on_key_released)
        self.add_controller(self._key_ctrl)

        self.windows = []
        self.idx     = 0
        self._build_skeleton()
        self.set_visible(False)

    def _build_skeleton(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        outer.set_halign(Gtk.Align.CENTER)
        outer.set_valign(Gtk.Align.CENTER)
        outer.add_css_class("switcher-bg")

        self.cards_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.cards_box.set_margin_top(14)
        self.cards_box.set_margin_bottom(14)
        self.cards_box.set_margin_start(18)
        self.cards_box.set_margin_end(18)
        outer.append(self.cards_box)
        self.set_child(outer)

    def _clear_cards(self):
        child = self.cards_box.get_first_child()
        while child:
            nxt = child.get_next_sibling()
            self.cards_box.remove(child)
            child = nxt

    def _make_card(self, client, selected):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.set_halign(Gtk.Align.CENTER)
        box.add_css_class("card-selected" if selected else "card")

        img = Gtk.Image()
        img.set_pixel_size(ICON_SIZE)
        img.set_from_icon_name(resolve_icon(client.get("class", "")))
        box.append(img)

        title = client.get("title", "") or "(no title)"
        if len(title) > TITLE_MAX:
            title = title[:TITLE_MAX - 1] + "…"
        lbl = Gtk.Label(label=title)
        lbl.add_css_class("card-title")
        lbl.set_halign(Gtk.Align.CENTER)
        box.append(lbl)

        ws      = client.get("workspace", {})
        ws_name = ws.get("name", str(ws.get("id", "?")))
        ws_lbl  = Gtk.Label(label=f"[{ws_name}]")
        ws_lbl.add_css_class("card-workspace")
        ws_lbl.set_halign(Gtk.Align.CENTER)
        box.append(ws_lbl)

        return box

    def _rebuild(self):
        self._clear_cards()
        for i, c in enumerate(self.windows):
            self.cards_box.append(self._make_card(c, i == self.idx))

    def _focus_current(self):
        if self.windows:
            focus_window(self.windows[self.idx].get("address", ""))

    def _on_key_pressed(self, ctrl, keyval, keycode, state):
        shift = bool(state & Gdk.ModifierType.SHIFT_MASK)
        if keyval in (Gdk.KEY_Tab, Gdk.KEY_ISO_Left_Tab):
            self._step(-1 if (shift or keyval == Gdk.KEY_ISO_Left_Tab) else 1)
            return True
        if keyval == Gdk.KEY_Escape:
            self._cancel()
            return True
        return False

    def _on_key_released(self, ctrl, keyval, keycode, state):
        if keyval in (Gdk.KEY_Alt_L, Gdk.KEY_Alt_R):
            self._hide()
            return True
        return False

    def _step(self, direction):
        if not self.windows:
            return
        self.idx = (self.idx + direction) % len(self.windows)
        self._rebuild()

    def _cancel(self):
        if self.windows:
            focus_window(self.windows[0].get("address", ""))
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.NONE)
        self.set_visible(False)

    def _hide(self):
        self._focus_current()
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.NONE)
        self.set_visible(False)

    # Commands from daemon socket (run on GTK main thread via idle_add)

    def cmd_open(self, reverse=False):
        self.windows = clients_mru()
        if len(self.windows) < 2:
            return
        self.idx = (len(self.windows) - 1) if reverse else 1
        self._rebuild()
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.EXCLUSIVE)
        self.set_visible(True)
        self.present()

    def cmd_close(self):
        self._hide()


class AltTabApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="com.hyprland.alttab")
        self.win = None

    def do_activate(self):
        self.win = OverlayWindow(self)
        threading.Thread(target=self._serve, daemon=True).start()

    def _serve(self):
        if os.path.exists(DAEMON_SOCK):
            os.unlink(DAEMON_SOCK)
        srv = _sock.socket(_sock.AF_UNIX, _sock.SOCK_STREAM)
        srv.bind(DAEMON_SOCK)
        srv.listen(8)
        try:
            while True:
                conn, _ = srv.accept()
                with conn:
                    data = conn.recv(256).decode().strip()
                if data:
                    GLib.idle_add(self._dispatch, data)
        finally:
            srv.close()
            try:
                os.unlink(DAEMON_SOCK)
            except OSError:
                pass

    def _dispatch(self, cmd):
        if   cmd == "open":    self.win.cmd_open()
        elif cmd == "prev":    self.win.cmd_open(reverse=True)
        elif cmd == "close":   self.win.cmd_close()
        elif cmd == "quit":    self.quit()
        return False


if __name__ == "__main__":
    app = AltTabApp()
    sys.exit(app.run(sys.argv))
