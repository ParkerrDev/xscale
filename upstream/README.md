# Upstream

The same change, as each project takes it, rebased on its main branch of
2026-10-18 and built there. None of these three has been submitted yet.

| Order | Project | Where | Patches | Description |
|---|---|---|---|---|
| 1 | wayland-protocols | gitlab.freedesktop.org/wayland/wayland-protocols | [wayland-protocols/](wayland-protocols/) | [MR.md](wayland-protocols/MR.md) |
| 2 | Xwayland | gitlab.freedesktop.org/xorg/xserver | [xserver/](xserver/) | [MR.md](xserver/MR.md) |
| 3 | Hyprland | github.com/hyprwm/Hyprland | [hyprland/](hyprland/) | [PR.md](hyprland/PR.md) |

Omarchy builds its own Hyprland (`pkgbuilds/hyprland` in omacom/omarchy-pkgs),
so the Hyprland half can reach every Omarchy machine without waiting on the
others. [omarchy/xwayland-scale.patch](omarchy/xwayland-scale.patch) is the
change as proposed there in
[omacom/omarchy-pkgs#1757](https://github.com/omacom/omarchy-pkgs/pull/1757):
`patches/hyprland-xwayland-scale.patch` without the `xwayland_shell_v1`
version 2 part. Hyprland lays X11 out at `xwayland:scale` and scales X11
windows and cursors down to their logical size itself, so it works with
Arch's stock Xwayland and changes no protocol. With the version 2 part on top,
an Xwayland that takes the scale shows its windows at their logical size
itself, and Hyprland leaves them as they come.

The protocol goes first: Xwayland and Hyprland both implement its version 2.
The Xwayland MR can be opened at the same time and linked from the protocol
MR, since wayland-protocols wants implementations before it merges. The
Xwayland patches build against wayland-protocols with or without the new
event (it is compiled in when the headers have it), so they do not wait for a
release. Hyprland vendors the version 2 XML until a wayland-protocols release
has it.

## Before submitting

- **Sign-off.** wayland-protocols and the X server take patches under the
  Developer Certificate of Origin: every commit needs a `Signed-off-by:` line
  from its author, with the name the author certifies under. That is a
  statement only the author can make, so the commits here have none:
  `git commit --amend -s` on each (or `git rebase --signoff`) adds it.
- **Accounts.** A freedesktop GitLab account (fork both projects there) and a
  GitHub account for Hyprland.
- **Rebase.** Each project moves quickly. Rebase on the day and build again:
  `build/upstream/` in this repository has the three clones with the commits
  on branches `xwayland-shell-scale`, `xwayland-rootless-scale` and
  `xwayland-scale`.

## What was tested

In a nested Hyprland with a 1.6 monitor and a second at 1, with the probe in
`tools/xprobe.c`, GTK 3 (zenity, Bambu Studio), Qt 6 (qml) and the X11
pointer and cursor; on Xwayland 24.1.14 and on the xserver main branch:

- X11 at 1.6 on the 1.6 monitor: a one-pixel checkerboard comes out exactly
  (0 grey pixels of 1.39 million).
- X11 at 2 on both monitors: windows the same size as the same apps on
  Wayland, linear filtering where downscaled, pointer on the exact X11 pixel,
  cursors the size of Wayland ones.
- Old with new: a stock Hyprland with this Xwayland, and this Hyprland with a
  stock Xwayland, behave exactly as before.
- wayland-protocols: its 197 tests pass. Xwayland: each commit builds with no
  new warnings against both the old and the new protocol. Hyprland: its unit
  tests pass, 5 of them new.

## Earlier attempts

- xserver issue #1318 and MR !733 (2020): a global scale set through an X11
  root window property, `_XWAYLAND_GLOBAL_OUTPUT_SCALE`, applied with
  `wl_surface.set_buffer_scale`. Never merged. Here the scale comes from the
  compositor through the protocol (no X11 client can change it), and viewports
  make fractional scales and windows of any size work.
- sway PR #5090 and wlroots PR #2064: compositor sides of !733.
- Mutter's `xwayland-native-scaling`, KWin's "Apply scaling themselves", and
  Hyprland's `force_zero_scaling`: the compositor lays the X11 screen out in
  output pixels and scales X11 surfaces itself. They work, but each compositor
  carries its own special cases for X11 surfaces, input and cursors, and X11
  cursors come out the wrong size. With the scale event those special cases
  go away.
