CC = gcc
CFLAGS = -O2 -fPIC


all: CoreFoundation.so libOSXWindowManagement.so libblz_commerce_sdk_plugin.so
.PHONY: all

CoreFoundation.so: CoreFoundation.c
	$(CC) $(CFLAGS) -shared -o CoreFoundation.so CoreFoundation.c

libOSXWindowManagement.so: OSXWindowManagement.c
	$(CC) $(CFLAGS) -shared -o libOSXWindowManagement.so OSXWindowManagement.c

libblz_commerce_sdk_plugin.so: blz_commerce_sdk_plugin.c
	$(CC) $(CFLAGS) -shared -o libblz_commerce_sdk_plugin.so blz_commerce_sdk_plugin.c

clean:
	rm -rf *.so
.PHONY: clean