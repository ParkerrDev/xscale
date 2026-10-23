# xscale

X11 apps on Hyprland that are as sharp as Wayland apps and the same size,
on every monitor, at any scale, with no per-app settings.

X11 has a single coordinate space and a single DPI for all its clients, so
under Wayland an X11 app cannot be told "this monitor is 1.6 and that one is 1".
Today that leaves two bad choices: X11 apps render at scale 1 and the
compositor blows them up (blurry), or `force_zero_scaling` shows them pixel for
pixel and each toolkit is told the scale by hand (`GDK_SCALE`, `Xft.dpi`,
`--ozone-platform`, `STEAM_FORCE_DESKTOPUI_SCALING`), right on one monitor and
wrong on the others.

xscale fixes it where it is broken: in the protocol between the compositor and
Xwayland, in Xwayland, and in Hyprland. X11 apps render at one scale, the
highest monitor's, and every X11 window is handed to the compositor the way a
HiDPI Wayland window is: at its logical size, with its pixels behind it. So it is
pixel for pixel on a monitor of that scale, downscaled on lower ones, and never
upscaled. The pointer, touch, tablets and cursors follow.

**Status.** Working on one laptop (Omarchy 4, Hyprland 0.56.2, Xwayland
24.1.14), and written to go upstream: see [upstream/](upstream/README.md).

## The three parts

1. **The protocol**: `xwayland_shell_v1` version 2 gains one event, `scale`,
   in which the compositor tells Xwayland the scale its X11 clients render at
   (times 120, as `wp_fractional_scale_v1` has it).
   [protocol/xwayland-shell-v1.xml](protocol/xwayland-shell-v1.xml)
2. **Xwayland** ([patches/xwayland-rootless-scale.patch](patches/xwayland-rootless-scale.patch)),
   in rootless mode, with that scale: lays the X11 screen out at the outputs'
   logical geometry times the scale, shows every surface at its buffer size
   divided by it (`wp_viewport`, so any window size and any fractional scale
   work), maps pointer, touch and tablet coordinates back, shows X11 cursors at
   their size divided by it, and passes XTest input to libei at logical
   coordinates. Without the event, or with a compositor that only knows
   version 1, nothing changes.
3. **Hyprland** ([patches/hyprland-xwayland-scale.patch](patches/hyprland-xwayland-scale.patch)):
   a new option `xwayland:scale`, the one scale every X11 client renders at
   (`-1` the highest monitor scale rounded up to a whole number, `-2` as it is,
   or a number). With an Xwayland that binds version 2 it sends the scale and
   treats X11 surfaces like any other; with an older Xwayland it scales the X11
   windows itself. It also fixes X11 size hints (minimum and maximum sizes),
   which were taken as logical sizes while they are X11 pixels.

   It also has a window rule, `xwayland_unscaled`, for the X11 apps that draw
   at 1x whatever they are told (Steam's updater, old Xlib or SDL programs):
   rendered at the X11 scale they would come out at 1 / scale of their size, so
   such a window is shown at its X11 size in logical pixels instead, its pixels
   enlarged (filtered smoothly), as a HiDPI desktop shows an app that was never
   made for it. Its menus and tooltips follow it, and the pointer lands on the
   X11 pixel it is over. `xwayland:unscaled_windows = false` turns the rule off
   everywhere.

The toolkit side needs no patch: `xscale settings` tells X11 toolkits the scale
through the X resources (`Xft.dpi`, `Xcursor.size`) and XSETTINGS (GTK's scale,
font and icon theme, copied from the Wayland side), and Steam through its own
variable.

## What it looks like

Measured in a nested Hyprland with a 1.6 monitor and a second one at 1:

- X11 at `-2` (1.6) on the 1.6 monitor: a one-pixel checkerboard comes out
  exactly, 0 grey pixels out of 1.39 million (pixel for pixel).
- X11 at `-1` (2), the default: an X11 window on the scale 1 monitor is
  filtered down cleanly (no nearest-neighbour rows dropped), and GTK 3 (zenity,
  Bambu Studio) and Qt 6 windows come out the same size as the same apps on
  Wayland, on both monitors.
- The pointer lands on the same X11 pixel it is over, on either monitor, and
  the X11 cursor is the size of Hyprland's own.
- A 300x200 X11 window drawing at 1x, ruled `xwayland_unscaled`, is 300x200
  logical pixels (480x320 on the 1.6 monitor) instead of 150x100; a popup it
  opens 20,30 X11 pixels inside it sits 20,30 logical pixels inside it, at its
  own size; the pointer lands on the X11 pixel it is over in both. Switching
  the rule on or off keeps the window's X11 size, so the app never sees a
  resize.
- Hyprland's 275 unit tests pass, 5 of them new for this. A stock Hyprland with
  this Xwayland, and this Hyprland with a stock Xwayland, both behave as
  before.

`tools/xprobe.c` is the probe window those numbers come from.

## Use it

Omarchy 4 on Arch. Building needs `base-devel` and the build packages of the
two recipes (`xscale build` names any that are missing).

```sh
git clone <this repository> ~/Dev/GitHub/xscale
cd ~/Dev/GitHub/xscale
./install.sh        # links the command, hypr/xscale.lua and a post-update hook
xscale build        # Arch's recipes for Hyprland and Xwayland, plus the patches
xscale install      # sudo pacman -U; then log out and back in
```

`xscale status` says what is installed and what the session does.
`xscale restore` puts Arch's Hyprland and Xwayland back, and `./uninstall.sh`
takes the links away. The packages carry Arch's release number plus `.1`, so the
next Hyprland or Xwayland release from Arch replaces them; the post-update hook
then says so.

`hypr/xscale.lua` shows Steam's updater ("Updating Steam...") unscaled and
centred, and Super+Alt+X does the same for the focused window, or gives it
back, for any other app that draws itself too small.

The scale is `scale` at the top of `hypr/xscale.lua`. `-1`, the default, suits
every toolkit, because GTK only scales by whole numbers. `-2` is pixel for
pixel on the highest monitor, but GTK apps then scale only their text.

## Files

```
bin/xscale            status, settings, build, install, restore
hypr/xscale.lua       xwayland.scale, the toolkit settings at login, unscaled apps
hooks/post-update.sh  a word when an update brought Arch's packages back
patches/              the Hyprland and Xwayland patches
pkg/                  Arch's recipes with the patches added
protocol/             xwayland-shell-v1.xml, version 2
tools/xprobe.c        an X11 window for measuring sharpness, pointer and cursor
upstream/             the changes as they go to each project
```

## Licence

MIT, see [LICENSE](LICENSE). The patches are offered to each project under its
own licence.
