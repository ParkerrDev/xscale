/* xprobe: an X11 window for checking how an X11 client is scaled.
 *
 *   xprobe [WIDTH HEIGHT [SECONDS]]
 *
 * The left half is a one-pixel black and white checkerboard: shown 1:1 it stays
 * pure black and white, resampled it turns grey. The right half is a ruler, a
 * line every 10 pixels and a longer one every 100. A cross follows the pointer.
 *
 * Every pointer motion is printed as the X server reports it, both the core
 * event (whole pixels) and the XInput 2 one (fractions of a pixel):
 *
 *   motion core 120 85
 *   motion xi2 120.62 85.25
 *   size 800 600
 *
 * The cursor is the theme's left_ptr at Xcursor.size, so its size and
 * sharpness can be compared with a Wayland client's.
 */
#include <X11/Xcursor/Xcursor.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XInput2.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct {
    Display *dpy;
    Window win;
    GC gc;
    int width, height;
    int pointer_x, pointer_y;
    int xi_opcode;
} Probe;

static void draw(Probe *p) {
    XSetForeground(p->dpy, p->gc, WhitePixel(p->dpy, DefaultScreen(p->dpy)));
    XFillRectangle(p->dpy, p->win, p->gc, 0, 0, (unsigned)p->width, (unsigned)p->height);
    XSetForeground(p->dpy, p->gc, BlackPixel(p->dpy, DefaultScreen(p->dpy)));

    const int half = p->width / 2;
    /* one-pixel checkerboard, as points in rows */
    for (int y = 0; y < p->height; y++) {
        for (int x = y & 1; x < half; x += 2)
            XDrawPoint(p->dpy, p->win, p->gc, x, y);
    }
    /* ruler */
    for (int x = half; x < p->width; x += 10) {
        const int length = (x - half) % 100 == 0 ? p->height : p->height / 4;
        XDrawLine(p->dpy, p->win, p->gc, x, 0, x, length);
    }
    /* the pointer's cross */
    if (p->pointer_x >= 0) {
        XDrawLine(p->dpy, p->win, p->gc, p->pointer_x, 0, p->pointer_x, p->height);
        XDrawLine(p->dpy, p->win, p->gc, 0, p->pointer_y, p->width, p->pointer_y);
    }
    XFlush(p->dpy);
}

static void select_xi2_motion(Probe *p) {
    int event, error;
    if (!XQueryExtension(p->dpy, "XInputExtension", &p->xi_opcode, &event, &error)) {
        p->xi_opcode = -1;
        return;
    }
    unsigned char bits[XIMaskLen(XI_LASTEVENT)] = {0};
    XISetMask(bits, XI_Motion);
    XIEventMask mask = {.deviceid = XIAllMasterDevices, .mask_len = sizeof(bits), .mask = bits};
    XISelectEvents(p->dpy, p->win, &mask, 1);
}

static void handle(Probe *p, XEvent *ev) {
    if (ev->type == Expose && ev->xexpose.count == 0) {
        draw(p);
    } else if (ev->type == ConfigureNotify) {
        if (ev->xconfigure.width != p->width || ev->xconfigure.height != p->height) {
            p->width = ev->xconfigure.width;
            p->height = ev->xconfigure.height;
            printf("size %d %d\n", p->width, p->height);
        }
    } else if (ev->type == MotionNotify) {
        p->pointer_x = ev->xmotion.x;
        p->pointer_y = ev->xmotion.y;
        printf("motion core %d %d\n", p->pointer_x, p->pointer_y);
        draw(p);
    } else if (ev->type == GenericEvent && ev->xcookie.extension == p->xi_opcode && XGetEventData(p->dpy, &ev->xcookie)) {
        if (ev->xcookie.evtype == XI_Motion) {
            const XIDeviceEvent *de = ev->xcookie.data;
            printf("motion xi2 %.2f %.2f\n", de->event_x, de->event_y);
        }
        XFreeEventData(p->dpy, &ev->xcookie);
    }
    fflush(stdout);
}

int main(int argc, char **argv) {
    Probe p = {.width = 400, .height = 300, .pointer_x = -1, .pointer_y = -1};
    int seconds = 60;
    if (argc >= 3) {
        p.width = atoi(argv[1]);
        p.height = atoi(argv[2]);
    }
    if (argc >= 4)
        seconds = atoi(argv[3]);
    if (p.width < 2 || p.height < 2 || seconds < 1) {
        fprintf(stderr, "usage: xprobe [WIDTH HEIGHT [SECONDS]]\n");
        return 2;
    }

    p.dpy = XOpenDisplay(NULL);
    if (!p.dpy) {
        fprintf(stderr, "xprobe: no X display\n");
        return 1;
    }
    const int screen = DefaultScreen(p.dpy);
    p.win = XCreateSimpleWindow(p.dpy, RootWindow(p.dpy, screen), 0, 0, (unsigned)p.width, (unsigned)p.height, 0,
                                BlackPixel(p.dpy, screen), WhitePixel(p.dpy, screen));
    XStoreName(p.dpy, p.win, "xprobe");
    XClassHint class_hint = {.res_name = "xprobe", .res_class = "xprobe"};
    XSetClassHint(p.dpy, p.win, &class_hint);
    XSelectInput(p.dpy, p.win, ExposureMask | StructureNotifyMask | PointerMotionMask);
    select_xi2_motion(&p);
    XDefineCursor(p.dpy, p.win, XcursorLibraryLoadCursor(p.dpy, "left_ptr"));
    p.gc = XCreateGC(p.dpy, p.win, 0, NULL);
    XMapWindow(p.dpy, p.win);

    printf("screen %d %d, cursor size %d\n", DisplayWidth(p.dpy, screen), DisplayHeight(p.dpy, screen),
           XcursorGetDefaultSize(p.dpy));
    fflush(stdout);

    const time_t end = time(NULL) + seconds;
    struct pollfd fd = {.fd = ConnectionNumber(p.dpy), .events = POLLIN};
    /* bounded by the deadline */
    while (time(NULL) < end) {
        while (XPending(p.dpy)) {
            XEvent ev;
            XNextEvent(p.dpy, &ev);
            handle(&p, &ev);
        }
        (void)poll(&fd, 1, 200);
    }
    XCloseDisplay(p.dpy);
    return 0;
}
