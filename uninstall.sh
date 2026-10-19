#!/bin/bash
# Takes xscale's links and its block in hyprland.lua away again. The packages
# stay as they are: `xscale restore` puts Arch's Hyprland and Xwayland back.
set -euo pipefail

ROOT=$(dirname "$(readlink -f "$0")")
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
HYPRLAND_LUA=$CONFIG/hypr/hyprland.lua

unlink_ours() {
  local name=$1
  if [ -L "$name" ] && [[ "$(readlink "$name")" == "$ROOT"/* ]]; then
    rm "$name"
    [ -e "$name.pre-xscale" ] && mv "$name.pre-xscale" "$name"
  fi
  return 0
}

unlink_ours "$HOME/.local/bin/xscale"
unlink_ours "$CONFIG/hypr/xscale.lua"
unlink_ours "$CONFIG/omarchy/hooks/post-update.d/50-xscale.sh"

if [ -f "$HYPRLAND_LUA" ] && grep -q '^-- >>> xscale' "$HYPRLAND_LUA"; then
  # the block, and the empty line install.sh put before it
  awk '/^-- >>> xscale/ { if (held_set && held != "") print held; held_set = 0; skip = 1; next }
       skip { if (/^-- <<< xscale/) skip = 0; next }
       { if (held_set) print held; held = $0; held_set = 1 }
       END { if (held_set) print held }' "$HYPRLAND_LUA" >"$HYPRLAND_LUA.xscale-tmp"
  mv "$HYPRLAND_LUA.xscale-tmp" "$HYPRLAND_LUA"
fi

echo "xscale is unlinked. Arch's Hyprland and Xwayland: xscale restore (before this, or run bin/xscale restore)"
