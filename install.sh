#!/bin/bash
# Puts xscale in place on Omarchy. It needs no root and is safe to run again.
#
#   ~/.local/bin/xscale                          the command
#   ~/.config/hypr/xscale.lua                    xwayland.scale, and the toolkit
#                                                settings at every login
#   ~/.config/omarchy/hooks/post-update.d/50-xscale.sh
#                                                a word after a system update
#                                                that brought back Arch's
#                                                Hyprland or Xwayland
#
# Everything is a symlink into this folder. The one file it edits is
# ~/.config/hypr/hyprland.lua, which gains a marked block of one line at its end.
#
# Then the patched Hyprland and Xwayland, which need root:
#   xscale build && xscale install
set -euo pipefail

ROOT=$(dirname "$(readlink -f "$0")")
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
HYPRLAND_LUA=$CONFIG/hypr/hyprland.lua

link() {
  local target=$1 name=$2
  mkdir -p "$(dirname "$name")"
  if [ -e "$name" ] && [ ! -L "$name" ]; then
    mv "$name" "$name.pre-xscale"
    echo "kept $name as $name.pre-xscale"
  fi
  ln -sfn "$target" "$name"
}

link "$ROOT/bin/xscale" "$HOME/.local/bin/xscale"
link "$ROOT/hypr/xscale.lua" "$CONFIG/hypr/xscale.lua"
link "$ROOT/hooks/post-update.sh" "$CONFIG/omarchy/hooks/post-update.d/50-xscale.sh"

if [ -f "$HYPRLAND_LUA" ] && ! grep -q '^-- >>> xscale' "$HYPRLAND_LUA"; then
  cat >>"$HYPRLAND_LUA" <<'EOF'

-- >>> xscale (install.sh adds this block, uninstall.sh removes it)
if package.searchpath("hypr.xscale", package.path) then require("hypr.xscale") end
-- <<< xscale
EOF
fi

echo "xscale is linked. The patched Hyprland and Xwayland: xscale build && xscale install"
