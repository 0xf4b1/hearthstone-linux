#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BLIZZARD_APP_ID "net.battle"
#define BLIZZARD_LOCALE_PATH "Launch Options/WTCG/LOCALE"
#define BLIZZARD_REGION_PATH "Launch Options/WTCG/REGION"
#define BLIZZARD_WEB_TOKEN_PATH "Launch Options/WTCG/WEB_TOKEN"

#define TYPEID_CF_DATA 0
#define TYPEID_CF_STRING 1

// TODO: read from somewhere?
#define MY_REGION "EU"

typedef struct
{
  unsigned int id;
} CF_TYPE_ID;

typedef struct
{
  unsigned int len;
  unsigned char* ptr;
} buffer_with_size;

typedef struct
{
  CF_TYPE_ID type;
  char* str;
} CFString;

typedef struct
{
  CF_TYPE_ID type;
  buffer_with_size buffer;
} CFData;

buffer_with_size* read_token() {
  #define KEY_LENGTH 0x30

  buffer_with_size* res = malloc(sizeof(buffer_with_size));
  res->len = 0;
  res->ptr = 0;

  FILE *fd = fopen("token", "rb");

  if (fd == 0) {
    return res;
  }

  char *buffer = malloc(KEY_LENGTH);
  fread(buffer, KEY_LENGTH, 1, fd);
  fclose(fd);

  res->len = KEY_LENGTH;
  res->ptr = buffer;
  return res;
}

CFData* cfdata_new() {
  CFData* data = malloc(sizeof(CFData));
  data->type.id = TYPEID_CF_DATA;
  data->buffer.len = 0;
  data->buffer.ptr = 0;
  return data;
}

CFData* cfdata_from_buffer(buffer_with_size* input) {
  CFData* data = cfdata_new();
  data->buffer.len = input->len;
  data->buffer.ptr = input->ptr;
  return data;
}

CFString* cfstring_new() {
  CFString* str = malloc(sizeof(CFString));
  str->type.id = TYPEID_CF_STRING;
  str->str = 0;
  return str;
}

CFString* cfstring_from_char(char* input) {
  CFString* str = cfstring_new();
  str->str = input;
  return str;
}

bool CFPreferencesAppSynchronize(intptr_t applicationID) { return true; }

intptr_t CFPreferencesCopyAppValue(intptr_t key, intptr_t applicationID) {
  char* appStr = ((CFString*)applicationID)->str;

  // Only handle "net.battle" app
  if (strcmp(appStr, BLIZZARD_APP_ID) != 0) {
    return (intptr_t) 0;
  }

  if (key) {
    char* keyStr = ((CFString*)key)->str;
    intptr_t res = 0;

    if (strcmp(keyStr, BLIZZARD_WEB_TOKEN_PATH) == 0) {
      res = (intptr_t) cfdata_from_buffer(read_token());
    } else if (strcmp(keyStr, BLIZZARD_LOCALE_PATH) == 0) {
      res = (intptr_t) cfstring_from_char(MY_REGION);
    } else if (strcmp(keyStr, BLIZZARD_REGION_PATH) == 0) {
      res = (intptr_t) cfstring_from_char(MY_REGION);
    }

    return (intptr_t) res;
  } else {
    return (intptr_t) 0;
  }
}

unsigned int CFPreferencesGetAppIntegerValue(intptr_t key, intptr_t applicationID) {
  return 0;
}

intptr_t __CFStringMakeConstantString(char *str) {
  CFString* my_string = malloc(sizeof(CFString));
  my_string->type.id = TYPEID_CF_STRING;

  if (str) {
    unsigned int len = strlen(str);
    char* copy = malloc(len + 1);
    memset(copy, 0, len + 1);
    memcpy(copy, str, len);
    my_string->str = copy;
  } else {
    my_string->str = 0;
  }

  return (intptr_t) my_string;
}

intptr_t CFDataGetBytePtr(intptr_t data) {
  if (data) {
    return (intptr_t) ((CFData*)data)->buffer.ptr;
  } else {
    return 0;
  }
}

unsigned int CFDataGetLength(intptr_t data) {
  if (data) {
    return ((CFData*)data)->buffer.len;
  } else {
    return 0;
  }
}

int CFDataGetTypeID(intptr_t cf) { return TYPEID_CF_DATA; }

int CFStringGetTypeID() { return TYPEID_CF_STRING; }

int CFStringGetLength(intptr_t str) {
  if (str) {
    return strlen(((CFString*)str)->str);
  } else {
    return 0;
  }
}

bool CFStringGetCString(intptr_t str, unsigned char* outBuffer, unsigned int bufferSize, unsigned int encoding) {
  if (str && outBuffer) {
    unsigned int my_str_len = CFStringGetLength(str);

    if (bufferSize >= my_str_len) {
      memcpy(outBuffer, ((CFString*)str)->str, my_str_len);
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

int CFGetTypeID(intptr_t object) {
  if (object) {
    return ((CF_TYPE_ID*)object)->id;
  } else {
    return 0;
  }
}

void CFRelease(intptr_t cf) {}
