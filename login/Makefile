CC = g++
FLAGS = `pkg-config --cflags --libs gtk+-3.0 $(shell pkg-config --list-package-names | grep webkit2gtk-4. | sort | tail -n1)`

all: login
.PHONY: all

login: login.c
	$(CC) login.c -lcryptopp $(FLAGS) -o login

clean:
	rm -rf login
.PHONY: clean
