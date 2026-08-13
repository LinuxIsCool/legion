# Hyprland navigation model: workspace-local hjkl, split reorientation, fullscreen-safe focus

**Date:** 2026-08-13
**Status:** design, awaiting approval
**Target:** `~/.config/hypr` (chezmoi-managed at `home/private_dot_config/hypr`)

## Conclusion first

Three navigation defects share one root cause: keys that are supposed to move you
*within* a workspace are allowed to leave it, and keys that move between workspaces
are allowed to land on nothing. This spec replaces the ad-hoc bindings with a single
model built on three laws, and adds one genuinely new capability (reorienting a split
by pushing a window against its edge).

After this change, every navigation keystroke leaves exactly one visible window
focused, or does nothing at all. There is no third outcome.

## The three laws

1. **Focus always lands on a visible window.** Never on a window hidden behind a
   fullscreen peer, never on an empty workspace. This law is directly assertable:
   `hyprctl -j activewindow` reports a `visible` boolean, so every test can check it
   rather than infer it.
2. **`hjkl` never changes workspace. Workspace keys never rearrange a split.** The
   two axes of navigation do not leak into each other.
3. **A key either does something meaningful or nothing at all.** No surprising
   third behavior at the edges.

## Notation

Used throughout the algorithms below. All geometry is read from
`hyprctl -j activewindow`, which reports `at: [x, y]` and `size: [w, h]`.

| Symbol | Meaning | Units |
|---|---|---|
| `geom0` | `(x0, y0, w0, h0)` of the focused window before an operation | px |
| `geom1` | the same window after `togglesplit` | px |
| `axis(d)` | the size component along direction `d`: `h` for up/down, `w` for left/right | px |
| `lead(d)` | the position component along direction `d`: `y` for up/down, `x` for left/right | px |
| `EPS` | tolerance absorbing gap rounding when comparing `lead` values | 2 px |
| `n` | count of workspaces with `windows > 0 and id > 0` | count |

## Current state

Hyprland 0.55.4, `general:layout = dwindle`, `dwindle:preserve_split = true`,
`binds:movefocus_cycles_fullscreen = false`.

Dwindle models each workspace as a binary tree. Every window is a leaf. Every
internal node is a split with an orientation, either side-by-side or stacked.
Hyprland does not expose this tree through `hyprctl`, which constrains the
implementation (see Part A).

Bindings as they stand today, after the two changes already shipped this session:

| Key | Current behavior |
|---|---|
| `Super+hjkl` | focus within workspace, wraps at edge (`super-nav.sh nav`) |
| `Super+Shift+hjkl` | move window within the split (native `movewindow`) |
| `Super+N/P` | `focus({workspace = "e+1"/"e-1"})` |
| `Super+Shift+N/P` | `window.move({workspace = "e+1"/"e-1", follow = true})` |
| `Super+←/→` | `focus({workspace = "e+1"/"e-1"})` |
| `Super+Shift+←/→` | `window.move({workspace = "e+1"/"e-1", follow = true})` |
| `Super+↑/↓` | cycle focus within workspace (`super-nav.sh cycle`) |
| `Super+Ctrl+J` | `focus({workspace = "empty"})` |
| `Super+[0-9]` | jump to workspace N directly |
| `Super+backslash` | `layout("togglesplit")` |

## Part A: reorienting a split by pushing against its edge

### Problem

`Super+Shift+<dir>` currently swaps the focused window with its neighbour in that
direction. At a true edge it does nothing, which wastes the keystroke and leaves
split reorientation stranded on a separate key (`Super+backslash`).

### Rule

`Super+Shift+<dir>` resolves in three cases, checked in order:

1. **A window exists in `<dir>`:** swap with it. (Unchanged from today.)
2. **Else, the parent split runs perpendicular to `<dir>`:** flip that split's
   orientation, and land the focused window at the `<dir>` end of it.
3. **Else:** do nothing. You are already at that end of your split.

Case 2 is the new capability. A side-by-side pair pushed upward becomes a stacked
pair with you on top. A stacked pair pushed left becomes a side-by-side pair with
you on the left.

**Scope: fully general.** Case 2 fires at any depth in the tree, including when the
split's other child is a whole subtree rather than a single window. This was chosen
deliberately over a "simple pairs only" variant: consistency of the rule matters more
than limiting how many windows can move at once. `Super+<dir>` is always able to move
you in `<dir>` if any arrangement permits it.

### Why case 2 is implementable without the tree

Hyprland exposes no dwindle tree, so the parent split's orientation must be inferred.
`togglesplit` is itself the probe.

Before the flip, the focused window spans its parent's **entire extent along the axis
perpendicular to the parent's split**. Two consequences follow, and both are readable
from the focused window's own geometry:

**Orientation test.** Flip the split, then compare `axis(d)`:

- `axis1 < axis0` means the window became constrained along `d`. The parent was
  **perpendicular** to `d`, and the flip was the right move. Keep it.
- `axis1 >= axis0` means the window grew along `d`. The parent was **parallel** to `d`,
  so the flip moved the window sideways. Revert with a second `togglesplit`, and the
  operation resolves to case 3.

Flipping a split always halves or doubles the focused window along `d`, so the two
outcomes differ by roughly a factor of two and a plain inequality is robust to gap
arithmetic. Exact equality cannot arise from a real flip; it is folded into the revert
branch so that any unforeseen degenerate case fails safe as a no-op rather than
committing a flip whose direction is unknown.

**Order test.** Before the flip, the window's `lead(d)` equals the parent's leading
edge, because it spanned the parent fully along that axis. After the flip:

- `|lead1 - lead0| <= EPS` means the window is the **first** child (top, or left).
- `lead1 > lead0 + EPS` means the window is the **second** child (bottom, or right).

`up` and `left` want the first child. `down` and `right` want the second. On a
mismatch, dispatch `swapsplit`.

Every quantity here comes from the focused window alone, which is exactly why the
algorithm generalizes to any depth without ever naming a node.

### Algorithm

New mode `push <left|right|up|down>` in `super-nav.sh`:

Note that fullscreen is *not* handled here. The Part C preamble runs before this
algorithm and has already returned the window to state 0, so `push` never sees a
fullscreen window.

```
guard: window is floating, or workspace has < 2 windows
       -> plain movewindow <dir>, exit

geom0 = geometry of active window

movewindow <dir>
  geometry changed?            -> CASE 1, swapped with a neighbour. exit.

togglesplit
geom1 = geometry of active window

  axis1 >= axis0?              -> CASE 3, parent was parallel.
                                  togglesplit again to revert. exit.

                                  CASE 2, parent was perpendicular. flip stands.
  |lead1 - lead0| <= EPS       -> window is the first child
  else                         -> window is the second child

  d in (up, left)  wants first child
  d in (down, right) wants second child
  mismatch?                    -> swapsplit
```

### Worked example

Monitor 2560x1440, gaps 10. Two windows side by side on the workspace:

```
A: at = (10, 40)    size = (1265, 1390)
B: at = (1285, 40)  size = (1265, 1390)
```

**A focused, `Super+Shift+K` (up):**

1. `movewindow u` does nothing. Nothing sits above A. Case 1 declined.
2. `togglesplit`. Now `A: at = (10, 40) size = (2540, 685)`.
3. `axis(up) = h`. `h1 = 685 < h0 = 1390`, so the parent was perpendicular. Flip stands.
4. `lead(up) = y`. `y1 = 40`, `y0 = 40`, difference 0 <= EPS, so A is the first child (top).
5. `up` wants the first child. Match, no `swapsplit`.

Result: stacked pair, A on top. A moved up, as asked.

**Same layout, A focused, `Super+Shift+J` (down):** steps 1 through 4 are identical,
but `down` wants the second child while A is the first. `swapsplit` fires, and A lands
at `(10, 735)`, the bottom. Correct.

**Nested case, three windows.** A on the left spanning full height, B and C stacked on
the right. A focused, `Super+Shift+J`:

```
BEFORE                    AFTER
┌─────┬─────┐            ┌───────────┐
│     │  B  │            │     B     │  quarter
│  A  ├─────┤    ──►     ├───────────┤
│     │  C  │            │     C     │  quarter
│     │     │            ├───────────┤
└─────┴─────┘            │     A     │  half
                         └───────────┘
```

A's sibling is the `{B, C}` subtree. The root split flips, `{B, C}` keeps its own
internal stacked orientation, and `swapsplit` puts A at the bottom. A moved down as
asked, and B and C moved as a consequence. This is the accepted cost of the fully
general scope.

### Reversibility

Case 2 is reversible with the perpendicular key. From `[A|B]` with A focused,
`Shift+Up` gives `[A/B]` with A on top; `Shift+Left` from there flips straight back to
`[A|B]` with A on the left. An accidental flip is always one keystroke from undone.

Note that `Shift+Down` then `Shift+Up` is *not* an identity: the second press finds a
window above and resolves as case 1, swapping within the new orientation. This is
correct behavior, not a defect. The orientation change persists; only the position
within it is undone.

## Part B: workspace travel skips empties and wraps

### Problem

`Super+N/P` and `Super+←/→` dispatch `workspace e+1` / `e-1`. The `e` variant
*includes empty workspaces*. With ws1 through ws4 populated, pressing `Super+→` on
ws4 creates and lands on an empty ws5, leaving no window focused. This violates law 1.

### Rule

Workspace travel visits only workspaces that currently hold windows, and wraps at
both ends, exactly like `next-window` in a tmux session.

### Algorithm

Two new modes in `super-nav.sh`, both reusing the existing `target_ws()` logic that
is currently only reachable from the edge-crossing path:

```
ws <next|prev>:
  build wss = workspaces with (windows > 0 and id > 0), sorted by id
  n = len(wss)
  n <= 1  -> exit
  i = index of current workspace in wss
  i not found (we are on an empty workspace) -> focus wss[0] for next, wss[n-1] for prev
  focus wss[(i +/- 1) mod n]

ws-move <next|prev>:
  compute the target workspace FIRST, using the rule above
  then window.move({workspace = target, follow = true})
```

Computing the target before moving matters: moving the last window off a workspace
makes that workspace vanish from the list, so a target computed afterward would be
wrong.

### Reaching a fresh workspace is preserved

Skipping empties in `N/P` and the arrows is only safe because two other routes to an
empty workspace remain, and both are kept unchanged:

- `Super+Ctrl+J` dispatches `workspace empty`
- `Super+[0-9]` jumps directly to a workspace by number, creating it if absent
- `Super+Shift+[0-9]` sends the window to workspace N, creating it if absent

## Part C: navigating away from a fullscreen window

### Problem

With `binds:movefocus_cycles_fullscreen = false`, dispatching `movefocus` while a
window is fullscreen finds the next window in the *tiled layout underneath* and
focuses it. The fullscreen window stays painted on top. Focus has genuinely moved,
onto a window that cannot be seen, and keystrokes go somewhere invisible. This is the
"no windows selected" symptom, and it violates law 1.

### Rule

Navigating away from a fullscreen window drops fullscreen first, then moves. This
matches tmux, where `select-pane` on a zoomed window unzooms and reveals the layout
with the new pane focused.

### Algorithm

A preamble shared by the `nav`, `cycle`, and `push` modes:

```
fs = fullscreen state of active window   (hyprctl -j activewindow .fullscreen)
fs != 0 -> dispatch the toggle matching the CURRENT mode, so the window
           returns to state 0 rather than switching between maximize and
           fullscreen
then proceed with the requested operation
```

The state field is confirmed present on 0.55.4: `hyprctl -j activewindow` reports
`fullscreen` as an integer alongside a separate `fullscreenClient`, and reads `0` on a
normal tiled window.

`Super+D` sets maximize and `Super+F` sets fullscreen, so the preamble must read the
current mode and toggle *that* mode off. Naively dispatching `fullscreen()` against a
maximized window risks promoting it to true fullscreen instead of exiting. Which
dispatcher cleanly returns a window to state 0 from each mode is the one open
implementation question in this spec, and it is resolved empirically by test case 15
before anything else is trusted.

## Bindings after this change

| Key | Behavior | Mode |
|---|---|---|
| `Super+hjkl` | focus within workspace, wraps at edge | `nav` |
| `Super+Shift+hjkl` | swap with neighbour, else reorient the split, else nothing | `push` (new) |
| `Super+N/P` | next/prev **populated** workspace, wraps | `ws` (new) |
| `Super+Shift+N/P` | send window to next/prev populated workspace, follow | `ws-move` (new) |
| `Super+←/→` | next/prev **populated** workspace, wraps | `ws` (new) |
| `Super+Shift+←/→` | send window to next/prev populated workspace, follow | `ws-move` (new) |
| `Super+↑/↓` | cycle focus within workspace | `cycle` (unchanged) |
| `Super+Ctrl+J` | first empty workspace | unchanged |
| `Super+[0-9]` | jump to workspace N, creating it | unchanged |
| `Super+backslash` | manual `togglesplit` escape hatch | unchanged |

`super-nav.sh`'s `focus` mode is retained: `Super+U` (the focus-unstick nudge) still
uses it. The `move` mode becomes unreferenced and is removed as part of this change.

## Files touched

| File | Change |
|---|---|
| `~/.config/hypr/super-nav.sh` | add `push`, `ws`, `ws-move`; add the fullscreen preamble; remove `move` |
| `~/.config/hypr/config/keybinds.lua` | rebind `Super+Shift+hjkl`, `Super+N/P`, `Super+Shift+N/P`, `Super+←/→`, `Super+Shift+←/→` |
| `~/.config/hypr/tests/nav-test.sh` | new: geometry-asserting harness |
| `home/private_dot_config/hypr/**` | re-add via `chezmoi add`, commit |

## Testing

The visible property is final geometry and final focus, so assertions are made
against those, never against intermediate dispatch state.

### Harness

`~/.config/hypr/tests/nav-test.sh` spawns throwaway kitty windows on a scratch
workspace (6 through 10 are free), drives one mode, asserts, and tears down.

Two harness constraints that will silently corrupt results if ignored:

- **`misc:enable_swallow = true` with `swallow_regex` matching kitty.** Spawning test
  kitties as children of the invoking kitty will cause the parent to be swallowed and
  disappear from `hyprctl clients`. Spawn detached via `hyprctl dispatch exec` so no
  parent-child relationship exists.
- **Animations make geometry reads racy.** Assertions must poll until geometry is
  stable across two consecutive reads, never `sleep` a fixed interval.

### Cases

| # | Setup | Action | Expected |
|---|---|---|---|
| 1 | two side by side, left focused | `push up` | stacked, focused on top |
| 2 | two side by side, left focused | `push down` | stacked, focused on bottom |
| 3 | two stacked, top focused | `push left` | side by side, focused left |
| 4 | two stacked, top focused | `push right` | side by side, focused right |
| 5 | two side by side, left focused | `push left` | unchanged (case 3 no-op) |
| 6 | two side by side, left focused | `push right` | plain swap (case 1) |
| 7 | three nested `[A \| B/C]`, A focused | `push down` | root flips, A at bottom half |
| 8 | one window | `push` any direction | unchanged, no crash |
| 9 | floating window | `push` any direction | falls back to `movewindow`, no crash |
| 10 | two side by side, left focused | `push up` then `push left` | original layout restored |
| 11 | ws6 and ws8 populated, on ws8 | `ws next` | lands on ws6 (wrapped, ws7 skipped) |
| 12 | only ws6 populated, on ws6 | `ws next` | no-op, still ws6, window still focused |
| 13 | ws6 has 1 window, ws8 populated | `ws-move next` | window lands on ws8, focus follows |
| 14 | fullscreen window, two on workspace | `nav right` | fullscreen dropped, other window focused, `.visible == true` |
| 15 | maximized window (`Super+D` mode) | `nav right` | `.fullscreen == 0` afterward, not promoted to the other mode |

Every case additionally asserts law 1 as a postcondition: after the operation,
`hyprctl -j activewindow` reports a non-empty address with `.visible == true`. Cases
5, 8, and 9 are no-ops, so for those the assertion is that focus is unchanged *and*
still visible.

### Mutation tests

Each proves the corresponding assertion can actually fail:

| Mutation | Must break |
|---|---|
| invert the `axis1 > axis0` comparison | cases 1-4 (flip kept when it should revert) |
| drop the `swapsplit` step entirely | cases 2 and 4 (lands at the wrong end) |
| widen `EPS` to half the workspace height | cases 2 and 4 (every window reads as first child) |
| compute `ws-move` target after the move | case 13 |
| remove the fullscreen preamble | cases 14 and 15 |
| use `e+1` instead of the populated-workspace list | case 11 |

## Risks and accepted costs

**Case 3 flickers.** The revert path flips and immediately flips back, which
animations will render as a visible twitch on a keystroke that ends up doing nothing.
Accepted for now: shipping it flickering and living with it is cheaper than a separate
pre-check, and the decision can be revisited once it has been felt in real use.

**Fully general scope moves unrelated windows.** Case 2 at a high tree node relocates
a whole subtree, as in the three-window worked example. Accepted deliberately in
exchange for a rule with no exceptions.

**Fullscreen exit dispatcher.** The `fullscreen` state field is confirmed on 0.55.4,
but which dispatcher returns a window to state 0 from each mode is not. Test case 15
resolves it. If no single dispatcher works cleanly for both modes, the fallback is
`fullscreenstate` with an explicit target state rather than a toggle.

## Rollback

Everything is chezmoi-managed and committed, so rollback is `git revert <sha>` in
`~/legion-machine` followed by `chezmoi apply`. The Hyprland Lua config hot-reloads on
write, so no session restart is needed. Pre-change `.bak-*` snapshots of
`super-nav.sh` and `keybinds.lua` also remain in `~/.config/hypr`, excluded from
chezmoi by `.chezmoiignore`.
