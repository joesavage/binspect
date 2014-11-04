//
//  AppDelegate.m
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "AppDelegate.h"
#import "WindowController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows {
    if (!hasVisibleWindows) [_windowController initiateWindowAction];
    return YES; // The application should indeed handle window reopening
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _windowController = [[WindowController alloc] init];
    [_windowController initiateWindowAction];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_windowController release];
    _windowController = nil;
}

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
    return [_windowController openFile:filename];
}

- (IBAction)openDocument:(id)sender {
    [_windowController presentOpenDialog];
}

@end
