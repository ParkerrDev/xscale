# xscale

**X11 apps on Hyprland, as sharp as Wayland apps and the same size, on every monitor.**

X11 has one coordinate space and one DPI for all its clients, so under Wayland an X11 app cannot be told "this monitor is 1.6 and that one is 1". Hyprland leaves two bad choices: X11 apps render at 1 and are enlarged (blurry), or `force_zero_scaling` shows them pixel for pixel (small, as Omarchy ships it) and every toolkit is told a scale by hand (`GDK_SCALE`, `Xft.dpi`, `--ozone-platform`, `STEAM_FORCE_DESKTOPUI_SCALING`), right on one monitor and wrong on the others. xscale fixes it where it breaks: in the protocol between Hyprland and Xwayland, in Xwayland, and in Hyprland. X11 apps render at the highest monitor's scale and each window is shown at its logical size, like a HiDPI Wayland window: pixel for pixel on that monitor, cleanly downscaled on the others, never enlarged.

| X11 apps | On a monitor at 1.6 | On a monitor at 1 |
|---|---|---|
| Omarchy as it ships | small: drawn at 1, shown pixel for pixel | right |
| Hyprland as it ships | blurry: drawn at 1, enlarged | right |
| Omarchy and a scale set per app | sharp, sized by hand for this monitor | too big: the same pixels |
| **xscale** | **sharp, the size of the Wayland app** | **sharp, the size of the Wayland app** |

```bash
curl -fsSL https://raw.githubusercontent.com/ParkerrDev/xscale/master/install.sh | bash
```

> Omarchy 4 (Arch, Hyprland 0.56). It asks for sudo once, to put xscale's Hyprland and Xwayland in place of Arch's: Arch's own packages with one patch each, prebuilt by this repository's CI for the release Arch has. Log out and back in after it.
> `xscale uninstall` puts Arch's back and takes the rest away.

---

<details>
<summary><b>How it works</b></summary>

<br>

### Three parts

1. **The protocol.** `xwayland_shell_v1` version 2 gains one event, `scale`, in which the compositor tells Xwayland the scale its X11 clients render at (times 120, as `wp_fractional_scale_v1` has it). [protocol/xwayland-shell-v1.xml](protocol/xwayland-shell-v1.xml)
2. **Xwayland** ([patches/xwayland-rootless-scale.patch](patches/xwayland-rootless-scale.patch)), rootless, with that scale: lays the X11 screen out at the outputs' logical geometry times the scale, shows every surface at its buffer size divided by it (`wp_viewport`, so any window size and any fractional scale work), maps pointer, touch and tablet coordinates back, shows X11 cursors at their size divided by it, and passes XTest input to libei at logical coordinates. Without the event, or with a compositor that only knows version 1, nothing changes.
3. **Hyprland** ([patches/hyprland-xwayland-scale.patch](patches/hyprland-xwayland-scale.patch)): the option `xwayland:scale`, the one scale every X11 client renders at. With an Xwayland that binds version 2 it sends the scale and treats X11 surfaces like any other; with a stock Xwayland it scales the X11 windows itself. It also fixes X11 size hints (minimum and maximum sizes), which were taken as logical sizes while they are X11 pixels, and adds the window rule `xwayland_unscaled` for apps that draw at 1x whatever they are told.

### The toolkits

No toolkit needs a patch. At every login `xscale settings` tells X11 toolkits the scale through the X resources (`Xft.dpi`, `Xcursor.size`) and XSETTINGS (GTK's scale, font, icon and cursor theme, copied from the Wayland side), and Steam through its own variable, which reaches the whole session through uwsm.

### The packages

`xscale recipe` fetches Arch's own recipe for the version Arch has, from Arch's packaging repository, and lays xscale's patch over it (`pkg/`): the patch goes on after Arch's `prepare()`, and the release number becomes Arch's plus `.N`. Nothing else of Arch's recipe changes, the sources' checksums and Xwayland's signature are checked as Arch checks them, and pacman gives Arch's package back at Arch's next release.

The [packages workflow](.github/workflows/packages.yml) builds both once a day for whatever Arch has, attests them, and releases each as `NAME-VERSION` with a `SHA256SUMS`. `xscale install` downloads the release for the versions on your system and checks it; for a release Arch put out in the last day, before the workflow has run, it builds the package on your machine instead.

</details>

---

<details>
<summary><b>Installation</b></summary>

<br>

### One line

```bash
curl -fsSL https://raw.githubusercontent.com/ParkerrDev/xscale/master/install.sh | bash
```

It:

1. clones xscale into `~/.local/share/xscale`, or updates the copy there;
2. links the command, `hypr/xscale.lua`, the post-update hook and Steam's session variable into your home folder, and adds one marked line to the end of `~/.config/hypr/hyprland.lua`;
3. runs `xscale install`: downloads xscale's Hyprland and Xwayland, checks them against their release's checksums, and installs them and `xsettingsd` with `sudo pacman`.

Log out and back in, and X11 apps are drawn at their monitors' scale.

### By hand

```bash
git clone https://github.com/ParkerrDev/xscale ~/.local/share/xscale
~/.local/share/xscale/install.sh --no-packages   # the links only
xscale install                                   # the packages, when you are ready
```

### Updates

When Arch releases a new Hyprland or Xwayland, `omarchy update` installs Arch's in place of xscale's. The post-update hook then installs xscale's build of the new release, with the sudo the update already asked for. If sudo has closed, or the new release came out too recently to be prebuilt, it says to run `xscale install`, which builds it here if it has to.

Hyprland plugins are built against the installed Hyprland's headers (hyprpm does that), and xscale's Hyprland installs its headers like Arch's.

### Uninstall

```bash
xscale uninstall
```

It puts Arch's Hyprland and Xwayland back, takes the links, the line in `hyprland.lua` and the written settings away, and says how to remove the clone.

</details>

---

<details>
<summary><b>Commands</b></summary>

<br>

```
xscale status              what is installed, and what the running session does
xscale install             xscale's Hyprland and Xwayland in place of Arch's (sudo pacman -U)
          --no-build       only a prebuilt package; never build here
          --noconfirm      ask pacman nothing
xscale restore             Arch's own Hyprland and Xwayland back
xscale uninstall           restore, then take everything else away
xscale settings            tell X11 toolkits the scale (run at every login)
xscale build               build both packages here, install nothing
xscale recipe NAME DIR     Arch's recipe for NAME with xscale's patch, in DIR
```

</details>

---

<details>
<summary><b>Configuration</b></summary>

<br>

The scale is `scale` at the top of `hypr/xscale.lua`:

| `scale` | X11 apps render at | |
|---|---|---|
| `-1` (default) | the highest monitor scale, rounded up | suits every toolkit, because GTK only scales by whole numbers |
| `-2` | the highest monitor scale as it is | pixel for pixel on that monitor, but GTK apps then scale only their text |
| a number | that number | |

Some X11 apps draw at 1x whatever they are told (Steam's updater, old Xlib and SDL programs), and so come out at a fraction of their size. The window rule `xwayland_unscaled` shows such a window at its X11 size instead, its pixels enlarged, as a HiDPI desktop shows an app that was never made for it; its menus and tooltips follow, and the pointer lands on the X11 pixel it is over. `hypr/xscale.lua` gives the rule to Steam's updater, and **Super+Alt+X** gives it to the focused window, or takes it away. `xwayland:unscaled_windows = false` turns the rule off everywhere.

</details>

---

<details>
<summary><b>Results</b></summary>

<br>

Measured in a nested Hyprland with a monitor at 1.6 and a second at 1, with `tools/xprobe.c`, an X11 window for measuring sharpness, the pointer and the cursor:

- X11 at `-2` (1.6) on the 1.6 monitor: a one-pixel checkerboard comes out exactly, 0 grey pixels out of 1.39 million.
- X11 at `-1` (2), the default: an X11 window on the monitor at 1 is filtered down cleanly, with no rows dropped, and GTK 3 (zenity, Bambu Studio) and Qt 6 windows are the same size as the same apps on Wayland, on both monitors.
- The pointer lands on the X11 pixel it is over, on either monitor, and the X11 cursor is the size of Hyprland's own.
- A 300x200 X11 window drawing at 1x, ruled `xwayland_unscaled`, is 300x200 logical pixels instead of 150x100; a popup it opens 20,30 X11 pixels inside it sits 20,30 logical pixels inside it. Switching the rule keeps the window's X11 size, so the app never sees a resize.
- Hyprland's 275 unit tests pass, 5 of them new for this. A stock Hyprland with xscale's Xwayland, and xscale's Hyprland with a stock Xwayland, both behave as before.

</details>

---

<details>
<summary><b>Upstream</b></summary>

<br>

The change is written to go into wayland-protocols, Xwayland and Hyprland, so that one day none of this is needed. [upstream/](upstream/README.md) has each part rebased on its project's main branch and built there, with the text of each merge request. None has been submitted yet.

</details>

---

<details>
<summary><b>Limits</b></summary>

<br>

- **One scale for all X11 apps.** That is X11's own limit. On monitors below the highest scale, X11 windows are downscaled from it: sharp, at some extra GPU work.
- **Arch's releases.** When a new Hyprland or Xwayland changes the code a patch touches, the patch has to be refreshed before that release can be built. The checks workflow tries both patches on Arch's recipes every day, so it shows first here. Until then Arch's packages stay, and X11 apps are scaled the old way.
- **x86_64.** The prebuilt packages are for x86_64; elsewhere `xscale install` builds them.

</details>

---

<details>
<summary><b>Files</b></summary>

<br>

```
bin/xscale            status, install, restore, uninstall, settings, build, recipe
hypr/xscale.lua       xwayland:scale, the toolkit settings at login, unscaled apps
hooks/post-update.sh  xscale's packages back after an update brought Arch's
session/uwsm-env      Steam's scale for the whole session
patches/              the Hyprland and Xwayland patches
pkg/                  the overlay laid over Arch's recipes
protocol/             xwayland-shell-v1.xml, version 2
tools/xprobe.c        an X11 window for measuring sharpness, pointer and cursor
upstream/             the change as each project takes it
```

</details>

---

<details>
<summary><b>License</b></summary>

<br>

MIT, see [LICENSE](LICENSE). The patches are offered to each project under its own license: Hyprland's BSD 3-Clause, and the MIT-style licenses of the X server and wayland-protocols. The recipes the packages are built from are Arch Linux's (0BSD).

</details>
