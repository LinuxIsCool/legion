#!/usr/bin/env python3
import re, os

CONFIG = os.path.expanduser("~/.config/hypr/config")

def slurp(path):
    try:
        with open(path) as f: return f.read()
    except: return ""

keybinds = slurp(f"{CONFIG}/keybinds.lua")
defaults = slurp(f"{CONFIG}/defaults.lua")

# Collect string variables from both files
VARS = {}
for src in [defaults, keybinds]:
    for m in re.finditer(r'(?:local\s+)?(\w+)\s*=\s*"([^"]*)"', src):
        VARS[m.group(1)] = m.group(2)

def resolve(expr):
    """Resolve a Lua string expression (literals + .. + known vars) to a plain string."""
    # Split on ' .. ' boundaries only when outside quotes
    tokens, cur, in_q = [], '', False
    i = 0
    while i < len(expr):
        c = expr[i]
        if c == '"' and not in_q:
            in_q = True
        elif c == '"' and in_q:
            in_q = False
        elif not in_q and expr[i:i+2] == '..' and (i == 0 or expr[i-1] != '.') and (i+2 >= len(expr) or expr[i+2] != '.'):
            tokens.append(cur.strip()); cur = ''; i += 2; continue
        cur += c
        i += 1
    tokens.append(cur.strip())

    out = []
    for t in tokens:
        t = t.strip()
        if t.startswith('"') and t.endswith('"'):
            out.append(t[1:-1])
        elif t in VARS:
            out.append(VARS[t])
        else:
            out.append(f'<{t}>')
    return ''.join(out)

def extract_parens(s, keyword):
    """Return content inside keyword(...), respecting nested parens."""
    idx = s.find(keyword + '(')
    if idx == -1: return None
    start = idx + len(keyword) + 1
    depth, i = 1, start
    while i < len(s) and depth > 0:
        if s[i] == '(': depth += 1
        elif s[i] == ')': depth -= 1
        i += 1
    return s[start:i-1]

NOCTALIA = {
    'launcher toggle':                   'Open launcher',
    'launcher emoji':                    'Emoji picker',
    'launcher clipboard':                'Clipboard history',
    'controlCenter toggle':              'Control center',
    'settings toggle':                   'Settings panel',
    'notifications toggleHistory':       'Notification history',
    'volume increase':                   'Volume up',
    'volume decrease':                   'Volume down',
    'volume muteOutput':                 'Mute audio',
    'volume muteInput':                  'Mute mic',
    'media playPause':                   'Play / Pause',
    'media next':                        'Next track',
    'media previous':                    'Previous track',
    'brightness increase':               'Brightness up',
    'brightness decrease':               'Brightness down',
    'lockScreen lock':                   'Lock screen',
    'sessionMenu toggle':                'Session menu',
    'wallpaper toggle':                  'Wallpaper picker',
    'plugin:screen-toolkit colorPicker': 'Color picker',
    'plugin:screen-toolkit annotate':    'Screenshot + annotate',
    'plugin:screen-toolkit annotateWindow': 'Screenshot window',
    'plugin:screen-toolkit toggle':      'Screen toolkit',
}

WS = {
    'e+1': 'Next workspace', 'e-1': 'Prev workspace',
    'r+1': 'Next workspace', 'r-1': 'Prev workspace',
    'empty': 'Go to empty workspace',
}
DIRS = {'r': 'right', 'l': 'left', 'u': 'up', 'd': 'down',
        'right': 'right', 'left': 'left', 'up': 'up', 'down': 'down'}

def describe(action):
    a = action.strip()

    if 'exec_cmd' in a:
        arg = extract_parens(a, 'exec_cmd')
        if arg:
            cmd = resolve(arg) \
                .replace('qs -c noctalia-shell ipc call  ', '') \
                .replace('qs -c noctalia-shell ipc call ', '') \
                .replace('uwsm app -- ', '') \
                .strip()
            if cmd in NOCTALIA:      return NOCTALIA[cmd]
            if 'hyprctl kill' in cmd: return 'Kill window (click to select)'
            if 'hypr-cheatsheet' in cmd: return 'This cheat sheet'
            if 'btop' in cmd:        return 'System monitor (btop)'
            return cmd

    if 'window.close'   in a: return 'Close window'
    if 'float'          in a and 'toggle' in a: return 'Toggle float'
    if 'fullscreen'     in a and 'mode = 1' in a: return 'Maximize'
    if 'fullscreen'     in a: return 'Fullscreen'
    if 'togglesplit'    in a: return 'Toggle split direction'
    if 'window.drag'    in a: return 'Drag window (mouse)'
    if 'window.resize'  in a: return 'Resize window (mouse)'
    if 'cycle_next'     in a: return 'Cycle next window'
    if 'toggle_special' in a: return 'Toggle scratchpad'

    m = re.search(r'focus.*direction\s*=\s*"(\w+)"', a)
    if m: return f'Focus {DIRS.get(m.group(1), m.group(1))}'

    m = re.search(r'\bfocus\b.*workspace\s*=\s*"([^"]+)"', a)
    if m and 'window.move' not in a:
        return WS.get(m.group(1), f'Go to workspace {m.group(1)}')

    m = re.search(r'focus.*workspace\s*=\s*(\d+)', a)
    if m: return f'Go to workspace {m.group(1)}'

    m = re.search(r'window\.move.*direction\s*=\s*"(\w+)"', a)
    if m: return f'Move window {DIRS.get(m.group(1), m.group(1))}'

    m = re.search(r'window\.move.*workspace\s*=\s*"([^"]+)"', a)
    if m:
        label = WS.get(m.group(1), m.group(1))
        follow = 'follow = true' in a
        if m.group(1) == 'special': return 'Send to scratchpad'
        return f'Move window → {label}' + (' (follow)' if follow else '')

    m = re.search(r'window\.move.*workspace\s*=\s*(\d+)', a)
    if m:
        follow = 'follow = true' in a
        return ('Move + follow →' if follow else 'Move window →') + f' workspace {m.group(1)}'

    return a[:60]

# Strip comments and collapse whitespace
text = re.sub(r'--[^\n]*', '', keybinds)
text = re.sub(r'\s+', ' ', text)

# Extract all hl.bind(...) calls using balanced-paren scanning
rows = []
i = 0
while True:
    idx = text.find('hl.bind(', i)
    if idx == -1: break
    start = idx + len('hl.bind(')
    depth, j = 1, start
    while j < len(text) and depth > 0:
        if text[j] == '(': depth += 1
        elif text[j] == ')': depth -= 1
        j += 1
    inner = text[start:j-1].strip()
    i = j

    # Split on top-level commas
    depth, parts, cur = 0, [], ''
    for ch in inner:
        if ch in '({': depth += 1
        elif ch in ')}': depth -= 1
        if ch == ',' and depth == 0:
            parts.append(cur.strip()); cur = ''
        else:
            cur += ch
    if cur.strip(): parts.append(cur.strip())

    if len(parts) < 2: continue

    key = resolve(parts[0])
    if '<' in key: continue  # unresolvable loop variable

    key = (key.replace('SUPER', 'Super').replace('CONTROL', 'Ctrl')
              .replace('SHIFT', 'Shift').replace('ALT', 'Alt'))
    key = re.sub(r'\s*\+\s*', '+', key).strip('+')

    rows.append((key, describe(parts[1])))

# Add loop-generated workspace bindings that can't be parsed statically
rows += [
    ('Super+[0-9]',       'Go to workspace N'),
    ('Super+Shift+[0-9]', 'Move window → workspace N (follow)'),
    ('Super+Alt+[0-9]',   'Move window → workspace N (stay)'),
]

rows.sort(key=lambda x: (
    0 if x[0].startswith('Super') else
    1 if x[0].startswith('Ctrl')  else
    2 if x[0].startswith('Alt')   else 3,
    x[0].upper()
))

col = max(len(r[0]) for r in rows)
print(f"\n  {'BINDING':<{col}}   ACTION")
print(f"  {'─'*col}   {'─'*55}")
for key, action in rows:
    print(f"  {key:<{col}}   {action[:72]}")
print()
