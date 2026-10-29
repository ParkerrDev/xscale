# >>> xscale: Hyprland with xwayland:scale and the xwayland_unscaled rule.
# Up to 0.56, patches/hyprland-xwayland-scale.patch, which also sends the scale
# to xscale's Xwayland (xwayland_shell_v1 version 2). From 0.57.0, which moved
# X11 windows into a class of their own, patches/hyprland-xwayland-scale-0.57.0.patch,
# the one offered to Omarchy: Hyprland scales X11 windows and cursors itself,
# with any Xwayland. Raise _xscale_release whenever a patch changes, so the
# change is built and installed as a new release.
_xscale_release=6
_xscale_patches="hyprland-xwayland-scale.patch hyprland-xwayland-scale-0.57.0.patch"
if [ "$(vercmp "$pkgver" 0.57.0)" -lt 0 ]; then
  _xscale_patch=hyprland-xwayland-scale.patch
else
  _xscale_patch=hyprland-xwayland-scale-0.57.0.patch
fi
_xscale_dir=hyprland-source
