#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <wchar.h>
#endif
#include "moonbit.h"

MOONBIT_FFI_EXPORT moonbit_bytes_t moonseis_read_file_bytes(moonbit_string_t path) {
  FILE *file = NULL;
#ifdef _WIN32
  file = _wfopen((const wchar_t *)path, L"rb");
#else
  int32_t length = Moonbit_array_length(path);
  char *utf8 = (char *)malloc((size_t)length + 1);
  if (utf8 == NULL) return moonbit_make_bytes(0, 0);
  for (int32_t i = 0; i < length; i++) {
    uint16_t c = path[i];
    utf8[i] = c < 128 ? (char)c : '?';
  }
  utf8[length] = '\0';
  file = fopen(utf8, "rb");
  free(utf8);
#endif
  if (file == NULL) return moonbit_make_bytes(0, 0);
  if (fseek(file, 0, SEEK_END) != 0) { fclose(file); return moonbit_make_bytes(0, 0); }
  long size = ftell(file);
  if (size <= 0 || size > INT32_MAX) { fclose(file); return moonbit_make_bytes(0, 0); }
  rewind(file);
  moonbit_bytes_t data = moonbit_make_bytes((int32_t)size, 0);
  size_t read = fread(data, 1, (size_t)size, file);
  fclose(file);
  if (read != (size_t)size) return moonbit_make_bytes(0, 0);
  return data;
}

MOONBIT_FFI_EXPORT void moonseis_exit_process(int32_t code) {
  exit(code);
}
