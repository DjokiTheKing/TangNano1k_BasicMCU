#ifndef STRING_H
#define STRING_H

#include <defines.h>

uint32_t strlen(const char* string) {
    uint32_t len_counter = 0;
    while(string[len_counter]) len_counter++;
    return len_counter;
}

#endif // STRING_H