//
//  Handler.m
//  MacStreamingPlayer
//
//  Created by Collin Mistr on 1/19/22.
//
//

#import "Handler.h"
#import "STPrivilegedTask.h"


@implementation Handler

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self performSelectorInBackground:@selector(runProcess) withObject:nil];
}

-(void)runProcess {
    int exitCode = 0;
    NSLog(@"Starting...");
    
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
            exit(1);
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
            // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
        }
    }
    
    // Success! Now, read the output file handle for data
    NSFileHandle *readHandle = [privilegedTask outputFileHandle];
    NSData *outputData = [readHandle readDataToEndOfFile]; // Blocking call
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    printf("%s", [outputString UTF8String]);

    exitCode = privilegedTask.terminationStatus;
    NSLog(@"Done");
    exit(exitCode);
}

@end
