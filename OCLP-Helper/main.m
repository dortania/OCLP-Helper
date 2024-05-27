//
//  main.m
//  Test
//
//  Created by Collin Mistr on 1/19/22.
//
//

#import <Cocoa/Cocoa.h>
#import "Handler.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Ensure we don't exit on parent process exit
        setpgid(0, 0);

        NSApplication * app = [NSApplication sharedApplication];
        Handler *h = [[Handler alloc] init];
        [app setDelegate:h];
        [app run];
    }
    return 0;
}
