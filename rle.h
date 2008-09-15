#include <sys/types.h>

ssize_t RLEEncodeMem(void *dst, const void *src, size_t len);
ssize_t RLEDecodeMem(void *dst, const void *src, size_t len);
ssize_t RLEGetEncodedSize(const void *src, size_t len);
ssize_t RLEGetDecodedSize(const void *src, size_t len);