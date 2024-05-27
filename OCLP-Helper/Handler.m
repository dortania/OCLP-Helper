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

-(void)displayPKGInstallPopup {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        NSImage *icon = [NSImage imageNamed:@"AppIcon"];
        [alert setMessageText:@"OpenCore Legacy Patcher"];
        [alert setInformativeText:@"OpenCore Legacy Patcher needs to install additional components to function properly. Please follow the instructions on the screen."];
        [alert addButtonWithTitle:@"OK"];
        [alert setIcon:icon];
        [alert runModal];
    });
}

-(void)postPKGRunApp:(BOOL)isUpdating {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Library/Application Support/Dortania/OpenCore-Patcher.app/Contents/MacOS/OpenCore-Patcher"];

    if (isUpdating) {
        [task setArguments:@[@"--update_installed"]];
    }

    [task launch];

    sleep(5); // Wait for the app to launch
}

-(void)runProcess {
    int exitCode = 0;
    NSLog(@"Starting...");

    BOOL isInstallingPKG = NO;
    BOOL isUpdating = NO;

    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    NSArray *components = [[NSProcessInfo processInfo] arguments];
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:components];

    if ([arguments count] == 1 || [arguments[1] isEqualToString:@"--update_installed"]) {
        isInstallingPKG = YES;
        if ([arguments count] != 1) {
            isUpdating = YES;
        }
    }

    if (isInstallingPKG) {

        if (isUpdating) {
            NSLog(@"Updating OpenCore Legacy Patcher...");
        } else {
            NSLog(@"Installing OpenCore Legacy Patcher...");
        }

        NSString *pkgPath = [[NSBundle mainBundle] pathForResource:@"OpenCore-Patcher" ofType:@"pkg"];
        if (!pkgPath) {
            NSLog(@"OpenCore-Patcher.pkg not found in resources");
            exit(1);
        }
        NSLog(@"Found OpenCore-Patcher.pkg at %@", pkgPath);

        [arguments removeAllObjects];
        [arguments addObject:@"-pkg"];
        [arguments addObject:pkgPath];
        [arguments addObject:@"-target"];
        [arguments addObject:@"/"];

        [privilegedTask setLaunchPath:@"/usr/sbin/installer"];
        [privilegedTask setArguments:arguments];

        [self displayPKGInstallPopup];

    } else {
        NSString *launchPath = arguments[1];
        [arguments removeObjectAtIndex:0]; // Remove Binary Path
        [arguments removeObjectAtIndex:0]; // Remove Launch Path
        [privilegedTask setLaunchPath:launchPath];
        [privilegedTask setArguments:arguments];
        [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    }

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

    // If we install the PKG, launch the app
    if (isInstallingPKG) {
        [self postPKGRunApp:isUpdating];
    }

    exit(exitCode);
}

@end
