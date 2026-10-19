-- xscale: X11 apps as sharp as Wayland ones, at the right size on every
-- monitor (~/Dev/GitHub/xscale).
--
-- X11 has one coordinate space and one DPI for all its clients, so X11 apps
-- render at one scale, the highest monitor's, and each window is shown at its
-- logical size on its own monitor: pixel for pixel where the monitor has that
-- scale, downscaled where it has less, never upscaled. xscale's Xwayland shows
-- the windows at that size itself (xwayland_shell_v1 version 2); with Arch's,
-- Hyprland does.
--
-- It needs xscale's Hyprland (`xscale build`, then `xscale install`), which
-- /usr/share/hypr/xwayland-scale marks: Arch's refuses xwayland.scale, so on it
-- this file only tells X11 toolkits the scale Omarchy's force_zero_scaling
-- gives them.

-- -1: the highest monitor scale rounded up to a whole number, which every
-- toolkit can take (GTK only scales by whole numbers). -2: the highest scale
-- as it is, pixel for pixel on that monitor, but GTK apps then scale only
-- their text. Or a number.
local scale = -1

local function exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

if exists("/usr/share/hypr/xwayland-scale") then
  hl.config({ xwayland = { scale = scale } })
end

-- X11 toolkits learn the scale from the X resources and XSETTINGS, which
-- exist once Xwayland is up: `xscale settings` waits for it
hl.on("hyprland.start", function()
  hl.exec_cmd((os.getenv("HOME") or "") .. "/.local/bin/xscale settings")
end)
