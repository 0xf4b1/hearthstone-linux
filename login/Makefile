CC = g++
CFLAGS = `pkg-config --cflags gtk+-3.0 webkit2gtk-4.0`
LDFLAGS = `pkg-config  --libs gtk+-3.0 webkit2gtk-4.0`
INCLUDE=-I/usr/include/webkitgtk-4.0 -I/usr/include/gtk-3.0 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/pango-1.0 -I/usr/include/harfbuzz -I/usr/include/cairo -I/usr/include/at-spi-2.0 -I/usr/include/dbus-1.0 -I/usr/lib/x86_64-linux-gnu/dbus-1.0/include -I/usr/include/gtk-3.0 -I/usr/include/gio-unix-2.0 -I/usr/include/fribidi -I/usr/include/atk-1.0 -I/usr/include/pixman-1 -I/usr/include/uuid -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/libsoup-2.4 -I/usr/include/libxml2 -I/usr/include/libmount -I/usr/include/blkid

all: login
.PHONY: all

login: login.c
	$(CC) login.c $(LDFLAGS) $(CFLAGS) -o login 

clean:
	rm -rf login
.PHONY: clean
