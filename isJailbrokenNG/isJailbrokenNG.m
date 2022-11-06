//
//  isJailbrokenNG.c
//  isJailbrokenNG
//
//  Created by Anthony Viriya on 11/6/22.
//

#include "isJailbrokenNG.h"
#include <unistd.h>
#define A(c)            (c) - 0x19
#define HIDE_STR(str)   do { char *p = str;  while (*p) *p++ -= 0x19; } while (0)
#define HIDE_CODE       __asm(\
                        "adr x0, #0xc\n"\
                        "mov x30, x0\n"\
                        "add x30, x30, #0x8\n"\
                        "ret\n"\
                        ".long 12345678\n")

__attribute__((always_inline)) int jailbreak_artifact_exists() {
    HIDE_CODE;
    int return_value = 0;
    char* files[2] = {
        "/bin/bash",
        "/Application/Cydia.app"
    };
    int i;
    for(i=0;i<2;++i) {
        if (access(files[i], F_OK) == 0) {
            return_value = 1;
            break;
        }
    }
    return return_value;
}

__attribute__((always_inline)) int isJailbroken(){
    HIDE_CODE;
    
    int return_value = jailbreak_artifact_exists();
    return return_value;
}
