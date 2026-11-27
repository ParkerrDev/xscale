#!/bin/bash
# `xscale check` and `xscale status` against stand-in pacman and Hyprland:
# which installed packages count as scaling X11 apps.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

# stand-in pacman: -Q/-Qi from $HAVE_* and $PACKAGER, -Si from $SYNC_* and $REPO
cat >"$tmp/bin/pacman" <<'SH'
#!/bin/bash
var() { local n=${2//-/_}; eval "printf '%s' \"\${$1_$n:-}\""; }
case $1 in
  -Q) v=$(var HAVE "$2"); [ -n "$v" ] || exit 1; echo "$2 $v" ;;
  -Qi) v=$(var HAVE "$2"); [ -n "$v" ] || exit 1
       echo "Name            : $2"; echo "Packager        : $(var PACKAGER "$2")" ;;
  -Si) v=$(var SYNC "$2"); [ -n "$v" ] || exit 1
       echo "Repository      : $(var REPO "$2")"; echo "Version         : $v" ;;
  -T) exit 0 ;;
esac
SH
chmod +x "$tmp/bin/pacman"
export PATH="$tmp/bin:$PATH" XDG_STATE_HOME=$tmp/state XDG_CACHE_HOME=$tmp/cache XDG_CONFIG_HOME=$tmp/config
fail=0
status_has() { # status_has TEXT WHAT
  local out
  out=$("$root/bin/xscale" status)
  if grep -qF -- "$1" <<<"$out"; then echo "ok   $2"; else echo "FAIL $2: no '$1' in: $out"; fail=1; fi
}
expect() {
  local want=$1 got
  got=$("$root/bin/xscale" check | tr '\n' ' ' || true)
  if [ "$got" = "$want" ]; then echo "ok   $2"; else echo "FAIL $2: wanted '$want', got '$got'"; fail=1; fi
}
hyprland() { # a Hyprland binary with or without xwayland:scale
  if [ "$1" = yes ]; then echo 'xwayland:unscaled_windows' >"$tmp/bin/Hyprland"; else echo 'xwayland:enabled' >"$tmp/bin/Hyprland"; fi
  chmod +x "$tmp/bin/Hyprland"
}
export HAVE_xorg_xwayland=24.1.14-1.1 SYNC_xorg_xwayland=24.1.14-1 REPO_xorg_xwayland=extra
export PACKAGER_xorg_xwayland="xscale" PACKAGER_hyprland="Omarchy <pkgs@omarchy.org>"

hyprland yes; export HAVE_hyprland=0.56.2-8 SYNC_hyprland=0.56.2-4 REPO_hyprland=extra
expect "" "an Omarchy Hyprland with xwayland:scale, newer than Arch's"
status_has "0.56.2-8 (Omarchy's), with xwayland:scale" "status names it"

export SYNC_hyprland=0.57.2-9 REPO_hyprland=omarchy
expect "hyprland " "an Omarchy Hyprland older than the repositories' one"
status_has "omarchy has 0.57.2-9" "status names the newer one"

hyprland no; export HAVE_hyprland=0.57.2-9
expect "hyprland " "an Omarchy Hyprland without xwayland:scale"

export HAVE_hyprland=0.57.2-9.8 PACKAGER_hyprland="xscale"
expect "" "xscale's Hyprland"

export HAVE_hyprland=0.57.2-2 SYNC_hyprland=0.57.2-2 REPO_hyprland=extra PACKAGER_hyprland="Arch"
hyprland yes
expect "hyprland " "Arch's Hyprland, whatever its binary says"

export HAVE_xorg_xwayland=24.1.14-1 HAVE_hyprland=0.57.2-2.8
expect "xorg-xwayland " "Arch's Xwayland"
exit "$fail"
