//
//  main.m
//  OCLP-Helper
//
//  Created by Mykola Grymalyuk on 2021-12-20.
//

#import <Foundation/Foundation.h>
#import "STPrivilegedTask.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        printf("Starting OCLP-Helper\n");
    }

    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    
    NSArray *components = [[NSProcessInfo processInfo] arguments];
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:components];


    NSString *launchPath = arguments[1];
    [arguments removeObjectAtIndex:0]; // Remove Binary Path
    [arguments removeObjectAtIndex:0]; // Remove Launch Path

    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:arguments];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];

    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
            return 1;
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
            // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
        }
    }
    
    [privilegedTask waitUntilExit];
    
    // Success! Now, read the output file handle for data
    NSFileHandle *readHandle = [privilegedTask outputFileHandle];
    NSData *outputData = [readHandle readDataToEndOfFile]; // Blocking call
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    printf("%s", [outputString UTF8String]);

    return privilegedTask.terminationStatus;
}
