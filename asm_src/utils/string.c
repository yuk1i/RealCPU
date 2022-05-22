#include "string.h"

void clear_buf(char * buf, int len) {
    for(register int i=0;i<len; i++) {
        buf[i] = '\0';
    }
}

// append str to buf, write max_len at most
int append(char* buf, char* str, int max_len) {
    register int len = 0;
    while(*str && len < max_len) {
        *buf = *str;
        buf++;
        str++;
        len++;
    }
    *buf = 0;
    return len;
}