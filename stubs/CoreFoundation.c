#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define KEY_LENGTH 0x30

bool CFPreferencesAppSynchronize(intptr_t applicationID) { return true; }

intptr_t CFPreferencesCopyAppValue(intptr_t key, intptr_t applicationID) {
  return 1;
}

intptr_t __CFStringMakeConstantString(char *str) { return 0; }

intptr_t CFDataGetBytePtr(intptr_t data) {
  FILE *fd = fopen("token", "rb");

  if (fd == 0) {
    return 0;
  }

  char *buffer = malloc(KEY_LENGTH);
  fread(buffer, KEY_LENGTH, 1, fd);
  fclose(fd);

  return (intptr_t) buffer;
}

unsigned int CFDataGetLength(intptr_t theData) { return KEY_LENGTH; }

int CFDataGetTypeID() { return 0; }

int CFStringGetTypeID() { return 1; }

int CFGetTypeID(intptr_t cf) { return 0; }