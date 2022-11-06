//
//  isJailbrokenNG.c
//  isJailbrokenNG
//
//  Created by Anthony Viriya on 11/6/22.
//

#include "isJailbrokenNG.h"
#include <unistd.h>
#define EXIT            __asm(\
                            "mov x0,#0\n"\
                            "mov x16,#1\n"\
                            "svc #0x80"\
                        )
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <bzlib.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <mach-o/dyld.h>

const int FUNCTION_OFFSET = 513;




__attribute__((always_inline))  int* hide_function_address(int* function) {
    HIDE_CODE;
    return function-FUNCTION_OFFSET;
}

__attribute__((always_inline))  int* get_real_function_address(int* function){
    HIDE_CODE;
    return function+FUNCTION_OFFSET;
}

__attribute__((always_inline)) const char* match(const char* X, const char* Y)
{
    HIDE_CODE;
    if (*Y == '\0')
        return X;
    
    int* fake_strlen = hide_function_address((int*) strlen);
    unsigned long (*real_strlen)(const char*) = (unsigned long(*)(const char*)) get_real_function_address(fake_strlen);
    for (int i = 0; i < real_strlen(X); i++)
    {
        if (*(X + i) == *Y)
        {
            const char* ptr = match(X + i + 1, Y + 1);
            return (ptr) ? ptr - 1 : NULL;
        }
    }

    return NULL;
}

__attribute__((always_inline))  char *randstring(int length) {
    HIDE_CODE;
    char *string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,.-#'?!";
    size_t stringLen = 26*2+10+7;
    char *randomString;

    randomString = malloc(sizeof(char) * (length +1));

    if (!randomString) {
        return (char*)0;
    }

    unsigned int key = 0;

    for (int n = 0;n < length;n++) {
        key = rand() % stringLen;
        randomString[n] = string[key];
    }

    randomString[length] = '\0';

    return randomString;
}

__attribute__((optnone)) void checkPorts(dispatch_queue_t main_queue, bool terminate_if_found){
    HIDE_CODE;
    int* fake_socket = hide_function_address((int*)socket);
    int* fake_memset = hide_function_address((int*)memset);
    int* fake_connect = hide_function_address((int*)connect);
    int* fake_strcmp = hide_function_address((int*)strcmp);

    int(*real_socket)(int, int, int) = (int(*)(int, int, int))get_real_function_address(fake_socket);
    void* (*real_memset)(void*, int, size_t) = (void* (*)(void*, int, size_t))get_real_function_address(fake_memset);
    int(*real_connect)(int, const struct sockaddr*, socklen_t) = (int(*)(int, const struct sockaddr*, socklen_t))get_real_function_address(fake_connect);
    int(*real_strcmp)(const char*, const char*) = (int(*)(const char*, const char*))get_real_function_address(fake_strcmp);

    int* fake_sleep = hide_function_address((int*) sleep);
    int (*real_sleep)(unsigned int) = (int(*)(unsigned int)) get_real_function_address(fake_sleep);
    
    
    int sockfd,flag;
    struct sockaddr_in s;
    unsigned mlen = 0x1000;
    char *cArr = (char *)calloc(mlen,sizeof(char));
    char *recvBuff = (char *)calloc(mlen,sizeof(char));
    BZ2_bzBuffToBuffDecompress(cArr,&mlen,(char *)strzip,sizeof(strzip),0,0);
    char *frida_auth = &cArr[52*64];
    char *frida_reject = &cArr[53*64];
    char *ssh = &cArr[54*64];
    char *lldb_spkt = &cArr[55*64];
    char *lldb_rpkt = &cArr[56*64];
    char *perr = &cArr[57*64];
    int offending_port = -1;
    while(1){
        for(int portNo=1;portNo<=65535;portNo++){
            flag = 0;
            sockfd = real_socket(AF_INET,SOCK_STREAM,0);
            if (sockfd < 0) {
                continue;
            }
            for(int j=0;j<3;j++){
                real_memset(&s,0,sizeof(s));
                real_memset(recvBuff,0,mlen);
                s.sin_family = AF_INET;
                s.sin_addr.s_addr = inet_addr("127.0.0.1");
                s.sin_port = htons(portNo);
                if(!real_connect(sockfd,(struct sockaddr *)&s,sizeof(s))){
                    switch(j){
                        // SSH
                        case 0:
                                read(sockfd,recvBuff,3);
                                if(real_strcmp(ssh,recvBuff) == 0) flag = 1;
                                break;
                                
                        // Frida
                        case 1:
                                write(sockfd,frida_auth,7);
                                read(sockfd,recvBuff,1024);
                                recvBuff[8] = '\0';
                                if(real_strcmp(frida_reject,recvBuff) == 0) flag = 1;
                                break;
                        // lldb
                        case 2:
                                write(sockfd,lldb_spkt,20);
                                read(sockfd,recvBuff,7);
                                if(real_strcmp(lldb_rpkt,recvBuff) == 0) flag = 1;
                                break;
                    }
                    close(sockfd);
                    if(flag || portNo == 8000){
                        offending_port = portNo;
                        goto dirty;
                    }
                }
            }
        }
        real_sleep(60); // avoid resource hogging
    }
dirty:
    if (terminate_if_found) {
        dispatch_async(main_queue, ^{
            printf(perr, offending_port);
        });
        EXIT;
    }
}

__attribute__((optnone))  void antiDebug(){
    HIDE_CODE;
    int* fake_sleep = hide_function_address((int*) sleep);
    int (*real_sleep)(unsigned int) = (int(*)(unsigned int)) get_real_function_address(fake_sleep);
    while(1) {
        __asm(
            "mov x20,x0\n"
            "mov x21,x1\n"
            "mov x22,x2\n"
            "mov x23,x3\n"
            "mov x16,x24\n"

            "mov x16,#0x1a\n"
            "mov x0,#0x1f\n"
            "mov x1,0\n"
            "mov x2,0\n"
            "mov x3,0\n"
            "svc #0x80\n"

            "mov x0,x20\n"
            "mov x1,x21\n"
            "mov x2,x22\n"
            "mov x3,x23\n"
            "mov x16,x24\n"
            "mov x20,#0\n"
            "mov x21,#0\n"
            "mov x22,#0\n"
            "mov x23,#0\n"
            "mov x24,#0\n"
        );
        real_sleep(60);
    }
}

__attribute__((optnone))  int jailbreak_artifact_exists(dispatch_queue_t main_queue, bool terminate_if_exists) {
    HIDE_CODE;
    
    int* fake_stat = hide_function_address((int*)stat);
    int(*real_stat)(const char*, struct stat*) = (int(*)(const char*, struct stat*))get_real_function_address(fake_stat);
    
    int* fake_sleep = hide_function_address((int*) sleep);
    int (*real_sleep)(unsigned int) = (int(*)(unsigned int)) get_real_function_address(fake_sleep);
    
    unsigned mlen = 0x1000;
    char *cArr = (char *)calloc(mlen,sizeof(char));
    BZ2_bzBuffToBuffDecompress(cArr,&mlen,(char *)strzip,sizeof(strzip),0,0);
    while(1) {
        int i;
        for(i=0;i<37;++i) {
            char* file = &cArr[i*64];
            struct stat st;
            if (real_stat(file,&st) == 0) {
#if DEBUG
                NSLog(@"[+] Found file %s\n", file);
#endif
                if (terminate_if_exists) {
                    EXIT;
                }
            }
        }
        real_sleep(60);
    }
}

__attribute__((optnone)) void checkDylib(dispatch_queue_t main_queue, bool terminate_if_exists){
    HIDE_CODE;
    int* fake_dyld_get_image_name = hide_function_address((int*)_dyld_get_image_name);
    const char* (*real_dyld_get_image_name)(uint32_t) = (const char*(*)(uint32_t))get_real_function_address(fake_dyld_get_image_name);
    
    int* fake_match = hide_function_address((int*)match);
    const char (*real_match)(const char*, const char*) = (const char (*)(const char*, const char*))get_real_function_address(fake_match);
    unsigned mlen = 0x1000;
    char *cArr = (char *)calloc(mlen,sizeof(char));
    BZ2_bzBuffToBuffDecompress(cArr,&mlen,(char *)strzip,sizeof(strzip),0,0);
    while(1){
        for(int i=0;;i++){
            const char *name = real_dyld_get_image_name(i);
            if(!name) break;
            else{
                for(int j=38;j<45;j++){
                    char* dylib_name = &cArr[j*64];
                    if(real_match(name, dylib_name) != NULL)
                    {
#if DEBUG
                        NSLog(@"[+] Found dylib %s\n", name);
#endif
                        if (terminate_if_exists) {
                            EXIT;
                        }
                    }
                }
            }
        }
        sleep(60);
    }
}


__attribute__((optnone))  void isJailbroken(bool terminate_if_true){
    HIDE_CODE;
    
    int* fake_dispatch_queue_create = hide_function_address((int*) dispatch_queue_create);
    dispatch_queue_t (*real_dispatch_queue_create)(const char*, dispatch_queue_attr_t) = (dispatch_queue_t (*)(const char*, dispatch_queue_attr_t))get_real_function_address(fake_dispatch_queue_create);
    
    int* fake_dispatch_async = hide_function_address((int*)dispatch_async);
    void(*real_dispatch_async)(dispatch_queue_t, void(^block)(void)) = (void(*)(dispatch_queue_t, void(^block)(void)))get_real_function_address(fake_dispatch_async);
    
    int* fake_antiDebug = hide_function_address((int*) antiDebug);
    void (*real_antiDebug)(void) = (void(*))get_real_function_address(fake_antiDebug);
    
    
    int* fake_jailbreak_artifact_exists = hide_function_address((int*) jailbreak_artifact_exists);
    void(*real_jailbreak_artifact_exists)(dispatch_queue_t, bool) = (void(*)(dispatch_queue_t, bool))get_real_function_address(fake_jailbreak_artifact_exists);
    
    int* fake_checkPorts = hide_function_address((int*) checkPorts);
    void(*real_checkPorts)(dispatch_queue_t, bool) = (void(*)(dispatch_queue_t, bool))get_real_function_address(fake_checkPorts);
    
    int* fake_checkDylib = hide_function_address((int*) checkDylib);
    void(*real_checkDylib)(dispatch_queue_t, bool) = (void(*)(dispatch_queue_t, bool))get_real_function_address(fake_checkDylib);
    
    int* fake_sleep = hide_function_address((int*) sleep);
    int (*real_sleep)(unsigned int) = (int(*)(unsigned int)) get_real_function_address(fake_sleep);
    
    int key_length = (rand() % (10 - 5 + 1)) + 5;
    char* queue_name = randstring(key_length);
    dispatch_queue_t antidebug_thread = real_dispatch_queue_create(queue_name, NULL);
#if DEBUG
    printf("Debug Mode\n");
#else
    real_dispatch_async(antidebug_thread, ^{
        real_antiDebug();
    });
#endif
    key_length += 1;
    queue_name = randstring(key_length);
    dispatch_queue_t artifact_thread = real_dispatch_queue_create(queue_name, NULL);
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    real_dispatch_async(artifact_thread, ^{
        real_jailbreak_artifact_exists(main_queue, terminate_if_true);
    });
    
    key_length+=1;
    queue_name = randstring(key_length);
    dispatch_queue_t dylib_checking_thread = real_dispatch_queue_create(queue_name, NULL);
    real_dispatch_async(dylib_checking_thread, ^{
        real_checkDylib(main_queue, terminate_if_true);
    });
    
    key_length+=1;
    queue_name = randstring(key_length);
    dispatch_queue_t port_checking_thread = real_dispatch_queue_create(queue_name, NULL);
    real_dispatch_async(port_checking_thread, ^{
        real_sleep(2);
        real_checkPorts(main_queue, terminate_if_true);
    });
    
}
