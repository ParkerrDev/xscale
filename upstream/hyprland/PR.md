**Title:** xwayland: one scale for X11 clients on every monitor (xwayland:scale)

**Description:**

X11 has a single coordinate space and a single DPI for all its clients, so an
X11 client cannot be given the scale of the monitor it is on. Today X11 apps
either render at 1 and are upscaled (blurry) or, with `force_zero_scaling`,
render at each monitor's pixels and need every toolkit told the scale by hand,
which is right on one monitor and wrong on the others (#6281, discussion
#10427).

This adds `xwayland:scale`: the one scale every X11 client renders at, on every
monitor. `-1` is the highest monitor scale rounded up to a whole number (the
default of Mutter's xwayland-native-scaling; GTK only scales by whole numbers),
`-2` the highest monitor scale as it is, or a number. `0`, the default, changes
nothing.

- With an Xwayland that binds `xwayland_shell_v1` version 2
  (wayland/wayland-protocols!NNNN, xorg/xserver!NNNN), Hyprland sends it the
  scale and gives it the logical layout; Xwayland shows each window at its
  logical size through `wp_viewport`, so X11 surfaces need no special
  handling: `surfaceScale()` is 1 and nothing else changes.
- With an older Xwayland, Hyprland lays the X11 screen out at the scale and
  scales the X11 windows itself, as `force_zero_scaling` does per monitor.

Either way, an X11 window is pixel for pixel on a monitor of that scale and
downscaled on lower ones (with linear filtering there, since nearest neighbour
would drop rows), and never upscaled.

Changes:

- `CX11Backend` separates the X11 scale (`clientScale`, X11 pixels per logical
  pixel, used for geometry, size hints and configures) from the scale its
  surfaces come in at (`surfaceScale`, 1 when Xwayland scales them itself).
  `reportedSize()` is in the surface's coordinates.
- `CMonitorPositionController::arrange` computes the scale and the X11 layout;
  `CXWaylandShellProtocol` advertises version 2, sends the scale, and the
  monitors are arranged again when an Xwayland that takes it binds.
- `xdg_output` gives such an Xwayland the logical layout.
- X11 windows are configured again after the monitors are rearranged.
- Tests for the arrangement (5 new).

`protocols/xwayland-shell-v1.xml` is version 2, vendored until a
wayland-protocols release has it.

Tested in a nested session with monitors at 1.6 and 1, with both a patched and
a stock Xwayland: X11 GTK 3 and Qt 6 apps the size of the same apps on Wayland
on both monitors, a one-pixel checkerboard exact at `-2` on the 1.6 monitor,
the pointer on the right X11 pixel across monitors, X11 cursors the size of
Wayland ones (with the patched Xwayland).
