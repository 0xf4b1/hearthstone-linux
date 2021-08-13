CC = g++
CFLAGS = `pkg-config --cflags gtk+-3.0 webkit2gtk-4.0`
LDFLAGS = `pkg-config  --libs gtk+-3.0 webkit2gtk-4.0`

all: login
.PHONY: all

login: login.c
	$(CC) login.c $(LDFLAGS) $(CFLAGS) -o login 

clean:
	rm -rf login
.PHONY: clean
