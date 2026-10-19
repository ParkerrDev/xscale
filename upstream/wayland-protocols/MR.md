**Title:** xwayland-shell: add a scale event

**Description:**

An X11 screen has a single coordinate space and a single DPI for all its
clients, so rootless Xwayland cannot give an X11 client the scale of the output
it is on. Compositors work around this by laying the X11 screen out in output
pixels and scaling X11 surfaces themselves (Mutter's xwayland-native-scaling,
KWin, Hyprland's force_zero_scaling), each with its own special cases for X11
surface sizes, input coordinates and cursors.

This adds version 2 of `xwayland_shell_v1` with one event, `scale`: the
compositor tells Xwayland the one scale its X11 clients render at, typically
that of its highest-density output, in 120ths as `wp_fractional_scale_v1` has
it. Xwayland then lays the X11 screen out at the logical output geometry times
the scale and shows every surface at its buffer size divided by it through
`wp_viewport`, mapping input coordinates and cursors back. To the compositor,
X11 surfaces become ordinary HiDPI surfaces: pixel for pixel on outputs of that
scale, downscaled on lower ones, never upscaled, with no special case for them.

Viewports rather than `wl_surface.set_buffer_scale` because X11 windows can have
any size (a buffer scale requires the buffer size to be a multiple of it) and
because fractional scales should work.

Implementations:

- Xwayland: xorg/xserver!NNNN (link once opened)
- Hyprland: hyprwm/Hyprland#NNNN (link once opened)

A scale of 120, or a compositor that never sends the event, is the behaviour of
version 1, and an Xwayland that binds version 1 never sees it, so either side
can be updated first.

CC @frog (protocol maintainer)
