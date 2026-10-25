#!/bin/bash
# Puts xscale in place on Omarchy 4:
#
#   curl -fsSL https://raw.githubusercontent.com/ParkerrDev/xscale/master/install.sh | bash
#   ./install.sh                  the same, from a clone
#   ./install.sh --no-packages    the links only; `xscale install` later
#
# It links, with no root (each a symlink into this folder):
#
#   ~/.local/bin/xscale                          the command
#   ~/.config/hypr/xscale.lua                    xwayland.scale, and the toolkit
#                                                settings at every login
#   ~/.config/uwsm/env.d/50-xscale               Steam's scale for the whole
#                                                session, from its start
#   ~/.config/omarchy/hooks/post-update.d/50-xscale.sh
#                                                xscale's packages back after an
#                                                update brought Arch's
#
# and adds a marked block of one line to the end of ~/.config/hypr/hyprland.lua.
# Then `xscale install` puts xscale's Hyprland and Xwayland in place of Arch's
# (sudo pacman -U). Log out and back in after it. It is safe to run again, and
# `xscale uninstall` takes all of it back.
set -euo pipefail

# From a pipe there is no folder beside this script: xscale is cloned first,
# and its installer reads the terminal, where pacman asks its questions.
if [ ! -f "$(dirname "$(readlink -f "$0")")/bin/xscale" ]; then
  dest=${XSCALE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/xscale}
  command -v git >/dev/null || { echo "xscale needs git" >&2; exit 1; }
  if [ -d "$dest/.git" ]; then
    echo "Updating $dest"
    git -C "$dest" pull --quiet --ff-only
  else
    echo "Fetching xscale into $dest"
    git clone --quiet https://github.com/ParkerrDev/xscale "$dest"
  fi
  if (exec </dev/tty) 2>/dev/null; then
    exec "$dest/install.sh" "$@" </dev/tty
  fi
  exec "$dest/install.sh" "$@" </dev/null
fi

ROOT=$(dirname "$(readlink -f "$0")")
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
HYPRLAND_LUA=$CONFIG/hypr/hyprland.lua

packages=yes
case ${1:-} in
  --no-packages) packages=no ;;
  "") ;;
  *)
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2
    exit 2
    ;;
esac

if ! command -v hyprctl >/dev/null || ! command -v pacman >/dev/null; then
  echo "xscale is for Hyprland on Arch (Omarchy 4)" >&2
  exit 1
fi

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
link "$ROOT/session/uwsm-env" "$CONFIG/uwsm/env.d/50-xscale"

if [ -f "$HYPRLAND_LUA" ] && ! grep -q '^-- >>> xscale' "$HYPRLAND_LUA"; then
  cat >>"$HYPRLAND_LUA" <<'LUA'

-- >>> xscale (install.sh adds this block, uninstall.sh removes it)
if package.searchpath("hypr.xscale", package.path) then require("hypr.xscale") end
-- <<< xscale
LUA
fi
echo "xscale is linked."

if [ "$packages" = yes ]; then
  "$ROOT/bin/xscale" install
else
  echo "xscale's Hyprland and Xwayland: xscale install"
fi
