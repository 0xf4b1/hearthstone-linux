CC = g++
FLAGS = `pkg-config --cflags --libs gtk+-3.0 libcrypto++ $(shell pkg-config --list-package-names | grep webkit2gtk-4.)`

all: login
.PHONY: all

login: login.c
	$(CC) login.c $(FLAGS) -o login

clean:
	rm -rf login
.PHONY: clean
