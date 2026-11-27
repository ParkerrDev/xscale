#!/bin/bash
# omarchy-channel.sh CHANNEL: make this Arch (a build container) take its
# packages as an Omarchy machine on CHANNEL (stable, rc or edge) does: Omarchy's
# snapshot of Arch for that channel, and Omarchy's own repository ahead of it,
# signed by Omarchy's key (pkg/omarchy.asc, checked by its fingerprint). Run as
# root, then pacman -Syyuu.
set -euo pipefail
channel=${1:-}
case $channel in
  stable) mirror=https://stable-mirror.omarchy.org ;;
  rc) mirror=https://rc-mirror.omarchy.org ;;
  edge) mirror=https://mirror.omarchy.org ;;
  *) echo "omarchy-channel.sh: stable, rc or edge" >&2; exit 2 ;;
esac
key=40DFB630FF42BCFFB047046CF0134EE680CAC571
here=$(dirname "$(readlink -f "$0")")

pacman-key --init >/dev/null 2>&1 || true
pacman-key --add "$here/omarchy.asc" >/dev/null
pacman-key --finger "$key" >/dev/null
pacman-key --lsign-key "$key" >/dev/null

echo "Server = $mirror/\$repo/os/\$arch" >/etc/pacman.d/mirrorlist
# [omarchy] goes before [core], as on an Omarchy machine
grep -q '^\[omarchy\]' /etc/pacman.conf ||
  sed -i "0,/^\[core\]/s||[omarchy]\nServer = https://pkgs.omarchy.org/$channel/\$arch\n\n[core]|" /etc/pacman.conf
