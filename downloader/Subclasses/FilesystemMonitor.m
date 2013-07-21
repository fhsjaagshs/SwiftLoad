//
//  FilesystemMonitor.m
//  Swift
//
//  Created by Nathaniel Symer on 7/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FilesystemMonitor.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <fcntl.h>

@interface FilesystemMonitor () {
    int dirFD;
    int kq;
    
    CFFileDescriptorRef dirKQRef;
}

- (void)kqueueFired;

@end

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info) {
    if ([(__bridge id)info isKindOfClass:[FilesystemMonitor class]] && callBackTypes == kCFFileDescriptorReadCallBack) {
        [[FilesystemMonitor sharedMonitor]kqueueFired];
    }
}

@implementation FilesystemMonitor

+ (FilesystemMonitor *)sharedMonitor {
    static FilesystemMonitor *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[FilesystemMonitor alloc]init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    
    dirFD = -1;
    kq = -1;
    dirKQRef = NULL;
    
    return self;
}

- (void)kqueueFired {
    assert(kq >= 0);
    
    struct kevent event;
    struct timespec timeout = {0, 0};
    
    int eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
    
    assert((eventCount >= 0) && (eventCount < 2));
    
    if (_changedHandler) {
        _changedHandler();
    }

    CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
}

- (BOOL)startMonitoringDirectory:(NSString *)dirPath {
    // Double initializing is not going to work...
    if ((dirKQRef == NULL) && (dirFD == -1) && (kq == -1)) {
        // Open the directory we're going to watch
        dirFD = open([dirPath fileSystemRepresentation], O_EVTONLY);
        if (dirFD >= 0) {
            // Create a kqueue for our event messages...
            kq = kqueue();
            if (kq >= 0) {
                struct kevent eventToAdd;
                eventToAdd.ident  = dirFD;
                eventToAdd.filter = EVFILT_VNODE;
                eventToAdd.flags  = EV_ADD | EV_CLEAR;
                eventToAdd.fflags = NOTE_WRITE;
                eventToAdd.data   = 0;
                eventToAdd.udata  = NULL;
                
                int errNum = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
                if (errNum == 0) {
                    CFFileDescriptorContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };

                    // Passing true in the third argument so CFFileDescriptorInvalidate will close kq.
                    dirKQRef = CFFileDescriptorCreate(NULL, kq, true, KQCallback, &context);
                    if (dirKQRef != NULL) {
                        CFRunLoopSourceRef rls = CFFileDescriptorCreateRunLoopSource(NULL, dirKQRef, 0);
                        if (rls != NULL) {
                            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
                            CFRelease(rls);
                            CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
                            
                            // If everything worked, return early and bypass shutting things down
                            return YES;
                        }
                        // Couldn't create a runloop source, invalidate and release the CFFileDescriptorRef
                        CFFileDescriptorInvalidate(dirKQRef);
                        CFRelease(dirKQRef);
                        dirKQRef = NULL;
                    }
                }
                // kq is active, but something failed, close the handle...
                close(kq);
                kq = -1;
            }
            // file handle is open, but something failed, close the handle...
            close(dirFD);
            dirFD = -1;
        }
    }
    return NO;
}

- (void)invalidate {
    if (dirKQRef != NULL) {
        CFFileDescriptorInvalidate(dirKQRef);
        CFRelease(dirKQRef);
        dirKQRef = NULL;
        // We don't need to close the kq, CFFileDescriptorInvalidate closed it instead.
        // Change the value so no one thinks it's still live.
        kq = -1;
    }
    
    if (dirFD != -1) {
        close(dirFD);
        dirFD = -1;
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
