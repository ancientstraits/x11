#include <stdio.h>
#include <stdlib.h>

#include <X11/X.h>
#include <X11/Xutil.h>

int main() {
	Display* dpy = XOpenDisplay(NULL);
	if (!dpy) {
		return 1;
	}

	int scr = DefaultScreen(dpy);

	Window win = XCreateSimpleWindow(dpy, RootWindow(dpy, scr), 10, 10, 100, 100, 1, BlackPixel(dpy, scr), WhitePixel(dpy, scr));

	Atom del_win = XInternAtom(dpy, "WM_DELETE_WINDOW", 0);
	XSetWMProtocols(dpy, win, &del_win, 1);

	XSelectInput(dpy, win, ExposureMask | KeyPressMask);

	XMapWindow(dpy, win);

	XEvent ev;
	int open = 1;
	while (open) {
		XNextEvent(dpy, &ev);
		switch (ev.type) {
			case KeyPress:
				// fallthrough
			case ClientMessage:
				open = 0;
				break;
			case Expose:
				XFillRectangle(dpy, win, DefaultGC(dpy, scr), 20, 20, 10, 10);
		}
	}

	XDestroyWindow(dpy, win);
	XCloseDisplay(dpy);

    return 0;
}
