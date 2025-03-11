CC = g++
FLAGS = `pkg-config --cflags --libs gtk+-3.0 $(shell (pkg-config --exists webkit2gtk-4.1 && echo webkit2gtk-4.1) || (pkg-config --exists webkit2gtk-4.0 && echo webkit2gtk-4.0))`

all: login
.PHONY: all

login: login.c
	$(CC) login.c -lcryptopp $(FLAGS) -o login

clean:
	rm -rf login
.PHONY: clean
