CC = gcc
CFLAGS = -O2 -fPIC


all: CoreFoundation.so libOSXWindowManagement.so
.PHONY: all

CoreFoundation.so: CoreFoundation.c
	$(CC) $(CFLAGS) -shared -o CoreFoundation.so CoreFoundation.c

libOSXWindowManagement.so: OSXWindowManagement.c
	$(CC) $(CFLAGS) -shared -o libOSXWindowManagement.so OSXWindowManagement.c

clean:
	rm -rf *.so
.PHONY: clean