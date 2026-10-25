-- xscale: X11 apps as sharp as Wayland ones, at the right size on every
-- monitor (https://github.com/ParkerrDev/xscale).
--
-- X11 has one coordinate space and one DPI for all its clients, so X11 apps
-- render at one scale, the highest monitor's, and each window is shown at its
-- logical size on its own monitor: pixel for pixel where the monitor has that
-- scale, downscaled where it has less, never upscaled. xscale's Xwayland shows
-- the windows at that size itself (xwayland_shell_v1 version 2); with Arch's,
-- Hyprland does.
--
-- It needs xscale's Hyprland (`xscale install`): Arch's has no
-- xwayland.scale, so on it this file only tells X11 toolkits the scale
-- Omarchy's force_zero_scaling gives them. Super+Alt+X enlarges an X11 app
-- that draws itself too small.

-- -1: the highest monitor scale rounded up to a whole number, which every
-- toolkit can take (GTK only scales by whole numbers). -2: the highest scale
-- as it is, pixel for pixel on that monitor, but GTK apps then scale only
-- their text. Or a number.
local scale = -1

-- Asked of the running Hyprland, not of the installed one: between installing
-- and the next login they differ, and an unknown option is a config error
if hl.get_config("xwayland:scale") ~= nil then
  hl.config({ xwayland = { scale = scale } })
end

-- An X11 app that draws at 1x whatever it is told comes out at 1 / scale of
-- its size. The rule xwayland_unscaled shows such a window at its X11 size
-- instead, its pixels enlarged, as a HiDPI desktop shows an app that was never
-- made for it (its menus and tooltips follow). Asked of the running Hyprland
-- again: an older xscale build has no such rule and would call it an error.
if hl.get_config("xwayland:unscaled_windows") ~= nil then
  -- Steam's updater ("Updating Steam..."), which the bootstrapper draws by
  -- itself before the client, with no class; centred again, as it centred
  -- itself at its old size
  hl.window_rule({ match = { class = "^$", title = "^Steam$", xwayland = true }, xwayland_unscaled = true, center = true })

  -- any other app that draws too small: this key enlarges the focused window,
  -- and gives it back
  hl.bind("SUPER + ALT + X", hl.dsp.window.set_prop({ prop = "xwayland_unscaled", value = "toggle" }), {
    description = "Enlarge an X11 app drawn too small (or give it back)",
  })
end

-- X11 toolkits learn the scale from the X resources and XSETTINGS, which
-- exist once Xwayland is up: `xscale settings` waits for it
hl.on("hyprland.start", function()
  hl.exec_cmd((os.getenv("HOME") or "") .. "/.local/bin/xscale settings")
end)
