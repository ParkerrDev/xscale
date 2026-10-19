#!/bin/bash
# xscale: after a system update, say so when it brought back Arch's Hyprland or
# Xwayland (a newer release replaces xscale's builds, whose release number is
# Arch's plus .1). Omarchy runs this from `omarchy update` (install.sh links it
# into ~/.config/omarchy/hooks/post-update.d). It never fails the update.
replaced=()
[ -e /usr/share/hypr/xwayland-scale ] || replaced+=(hyprland)
case $(pacman -Q xorg-xwayland 2>/dev/null) in
  *.1) ;;
  *) replaced+=(xorg-xwayland) ;;
esac
[ "${#replaced[@]}" -eq 0 ] && exit 0

echo "xscale: the update brought Arch's ${replaced[*]} back, so X11 apps are scaled the old way again."
echo "xscale: xscale build && xscale install puts the patched ones back (if the patches still fit this release)."
exit 0
