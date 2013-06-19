//
//  main.m
//  downloader
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Hack.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    int retVal = UIApplicationMain(argc, argv, @"Hack", @"downloaderAppDelegate");
    [pool release];
    return retVal;
}

