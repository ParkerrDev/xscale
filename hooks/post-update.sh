#!/bin/bash
# xscale, after `omarchy update` (install.sh links it into
# ~/.config/omarchy/hooks/post-update.d). When Arch releases a new Hyprland or
# Xwayland, the update replaces xscale's build with Arch's; this puts xscale's
# build of the new release back. That is this repository's prebuilt package, a
# download, with the sudo the update already asked for. When sudo has closed,
# or there is no prebuilt package for that release yet (this repository builds
# each within a day), it says what to run instead. It never fails the update.
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/xscale
xscale=$(dirname "$(dirname "$(readlink -f "$0")")")/bin/xscale

# only where xscale's packages were installed and not restored since
[ -e "$STATE/packages" ] || exit 0

replaced=()
for name in hyprland xorg-xwayland; do
  [[ $(LC_ALL=C pacman -Q "$name" 2>/dev/null) =~ -[0-9]+\.[0-9]+$ ]] || replaced+=("$name")
done
[ "${#replaced[@]}" -eq 0 ] && exit 0

echo "xscale: the update brought Arch's ${replaced[*]} back"
if sudo -n true 2>/dev/null && "$xscale" install --no-build --noconfirm; then
  exit 0
fi
echo "xscale: \`xscale install\` puts xscale's back (and builds it if there is no prebuilt one yet)"
exit 0
