#!/usr/bin/env bash
# super-nav.sh — window navigation for Hyprland (Lua/non-legacy parser → hl.dsp.*).
#   focus <left|right>  native spatial movefocus within the workspace; if it can't move
#                       (true edge), cross to the adjacent workspace-with-windows, wrap.
#   move  <left|right>  move the active window in that direction; at the edge, hop it to
#                       the adjacent workspace, wrap.
#   cycle <next|prev>   scroll focus through the CURRENT workspace's windows only (wraps).
#   nav <left|right|up|down>
#                       directional focus that NEVER leaves the workspace: native spatial
#                       step first; at a true edge, wrap to the far window on that same
#                       axis (tmux-pane style). Bound to SUPER+hjkl.
#   DRY=1 ...           print dispatch(es) instead of executing.
#
# NOTE: raw `hyprctl dispatch movefocus r` does NOT work here (Lua parser); dispatch must go
# through hl.dsp.* objects (see hd()).
set -euo pipefail
mode="${1:?usage: super-nav.sh <focus|move|cycle> <left|right|next|prev>}"
dir="${2:?usage: super-nav.sh <focus|move|cycle> <left|right|next|prev>}"

hd(){ if [ -n "${DRY:-}" ]; then echo "DRY: $1"; else hyprctl dispatch "$1" >/dev/null; fi; }

clients=$(hyprctl -j clients)
addr=$(hyprctl -j activewindow | jq -r '.address // empty')
ws=$(hyprctl -j activewindow | jq -r '.workspace.id // empty')
ws_q(){ jq --argjson w "${ws:-0}" "[.[]|select(.workspace.id==\$w)]|$1" <<<"$clients"; }

# ---- cycle: stay within the current workspace, wrap (by left->right, top->bottom order) ----
if [ "$mode" = cycle ]; then
  mapfile -t wins < <(jq -r --argjson w "${ws:-0}" '[.[]|select(.workspace.id==$w)]|sort_by(.at[0],.at[1])|.[].address' <<<"$clients")
  m=${#wins[@]}; [ "$m" -le 1 ] && exit 0
  idx=0; for i in "${!wins[@]}"; do [ "${wins[$i]}" = "$addr" ] && idx=$i; done
  case "$dir" in next) cs=1 ;; prev) cs=-1 ;; *) echo "cycle dir must be next|prev" >&2; exit 1 ;; esac
  hd "hl.dsp.focus({window=\"address:${wins[$(( (idx+cs+m)%m ))]}\"})"
  exit 0
fi

# ---- nav: directional focus confined to the current workspace, wraps at the edge ----
if [ "$mode" = nav ]; then
  case "$dir" in
    left)  word=left;  ax=0; far='max_by(.at[0])' ;;
    right) word=right; ax=0; far='min_by(.at[0])' ;;
    up)    word=up;    ax=1; far='max_by(.at[1])' ;;
    down)  word=down;  ax=1; far='min_by(.at[1])' ;;
    *) echo "nav dir must be left|right|up|down" >&2; exit 1 ;;
  esac

  # Windows on this workspace that sit at a DIFFERENT coordinate on the travel axis.
  # The filter is what stops "up" from jumping sideways when everything is in one row.
  wrap_target(){
    local cur; cur=$(jq -r --arg a "$addr" --argjson x "$ax" \
      '[.[]|select(.address==$a)][0].at[$x] // empty' <<<"$clients")
    [ -z "$cur" ] && return
    jq -r --argjson w "${ws:-0}" --argjson x "$ax" --argjson c "$cur" \
      "[.[]|select(.workspace.id==\$w and .at[\$x]!=\$c)]|$far|.address // empty" <<<"$clients"
  }

  [ -z "$addr" ] && exit 0
  if [ -n "${DRY:-}" ]; then
    echo "DRY: hl.dsp.focus({direction=\"$word\"})"
    echo "DRY: (if that didn't move, or left ws $ws) wrap to $(wrap_target)"
    exit 0
  fi

  hd "hl.dsp.focus({direction=\"$word\"})"
  read -r new new_ws < <(hyprctl -j activewindow | jq -r '"\(.address // "") \(.workspace.id // "")"')
  if [ "$new" = "$addr" ] || [ "$new_ws" != "$ws" ]; then
    # Either we hit a true edge, or the native step escaped onto another monitor's
    # workspace. Put focus back and wrap within this workspace instead.
    [ "$new" != "$addr" ] && hd "hl.dsp.focus({window=\"address:$addr\"})"
    tgt=$(wrap_target)
    [ -n "$tgt" ] && [ "$tgt" != null ] && hd "hl.dsp.focus({window=\"address:$tgt\"})"
  fi
  exit 0
fi

# ---- focus / move: left/right ----
case "$dir" in
  right) word=right; mw=r; enter='min_by(.at[0])'; edge='max_by(.at[0])'; step=1 ;;
  left)  word=left;  mw=l; enter='max_by(.at[0])'; edge='min_by(.at[0])'; step=-1 ;;
  *) echo "dir must be left|right" >&2; exit 1 ;;
esac

mapfile -t wss < <(hyprctl -j workspaces | jq -r '[.[]|select(.windows>0 and .id>0)]|sort_by(.id)|.[].id')
n=${#wss[@]}
target_ws(){ local ci=-1 i; for i in "${!wss[@]}"; do [ "${wss[$i]}" = "$ws" ] && ci=$i; done
             if [ "$ci" -lt 0 ]; then echo "${wss[0]}"; else echo "${wss[$(( (ci+step+n)%n ))]}"; fi; }

cross(){
  [ "$n" -eq 0 ] && return
  local t; t=$(target_ws)
  if [ "$mode" = focus ]; then
    local tgt; tgt=$(jq -r --argjson w "$t" "[.[]|select(.workspace.id==\$w)]|$enter|.address" <<<"$clients")
    [ -n "$tgt" ] && [ "$tgt" != null ] && hd "hl.dsp.focus({window=\"address:$tgt\"})"
  else
    [ "$n" -le 1 ] && return
    hd "hl.dsp.window.move({workspace=$t, follow=true})"
  fi
}

[ -z "$addr" ] && { cross; exit 0; }

if [ "$mode" = focus ]; then
  hd "hl.dsp.focus({direction=\"$word\"})"                 # native spatial step
  [ -n "${DRY:-}" ] && { echo "DRY: (if it didn't move) cross to ws $(target_ws)"; exit 0; }
  [ "$(hyprctl -j activewindow | jq -r '.address // empty')" = "$addr" ] && cross   # edge → cross
else  # move
  edge_addr=$(jq -r --argjson w "${ws:-0}" "[.[]|select(.workspace.id==\$w)]|$edge|.address" <<<"$clients")
  if [ "$addr" = "$edge_addr" ] || [ "$(ws_q length)" -le 1 ]; then
    cross
  else
    hd "hl.dsp.window.move({direction=\"$mw\"})"
  fi
fi
