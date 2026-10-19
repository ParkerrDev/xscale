**Title:** xwayland: Honour a rootless scale from xwayland_shell_v1

**Description:**

Implements the `scale` event of `xwayland_shell_v1` version 2
(wayland/wayland-protocols!NNNN): the compositor tells Xwayland the one scale
its X11 clients render at, and Xwayland shows its windows at their logical size
itself, so that compositors no longer need special cases for X11 surfaces.

With a scale in rootless mode (and wp_viewporter, xdg-output and buffer damage
available), Xwayland:

- lays the X11 screen out at the logical geometry of every output times the
  scale, rounding the edges so that adjacent outputs stay adjacent;
- shows every surface it creates at its buffer size divided by the scale,
  through `wp_viewport.set_destination` (windows of any size, fractional
  scales);
- maps input coordinates back through each window's viewport scale, as it
  already does for resolution change emulation, whose viewport now targets the
  output's size in the compositor's coordinates;
- shows X11 cursors at their size divided by the scale, so that toolkits that
  scale their cursors (GTK, Qt, Chromium) match Wayland cursors;
- passes XTest motion to EIS at logical coordinates.

Three commits:

1. `xwayland: Scale surface-local pointer coordinates before rounding them`.
   Independent of the rest: with any viewport (resolution emulation too) the
   pointer moved in steps of the viewport scale, and the enter position was
   not scaled at all.
2. `xwayland: Honour a rootless scale from xwayland_shell_v1`.
3. `xwayland/xtest: Send logical coordinates to EIS`.

The event is compiled in when the wayland-protocols in use has it
(`XWAYLAND_SHELL_V1_SCALE_SINCE_VERSION`), so no version bump of the dependency
is needed; every commit builds against wayland-protocols with and without it.

Tested with Hyprland (hyprwm/Hyprland#NNNN) in a nested session with outputs at
1.6 and 1: a one-pixel checkerboard drawn by an X11 client at a scale of 1.6
comes out exactly on the 1.6 output; at a scale of 2, GTK 3 and Qt 6 X11
windows have the size of the same apps on Wayland on both outputs, the pointer
lands on the X11 pixel under it, and X11 cursors match Wayland ones. A
compositor that only offers version 1 sees no change.

Earlier attempt: !733 (an X11 root property and `wl_surface.set_buffer_scale`).
Here the scale comes from the compositor, and viewports make fractional scales
and any window size work.

CC @ofourdan @daenzer
