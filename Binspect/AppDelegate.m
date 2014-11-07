//
//  AppDelegate.m
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "AppDelegate.h"
#import "WindowController.h"

@implementation AppDelegate

- (BOOL) applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)hasVisibleWindows {
		if (!hasVisibleWindows) [_windowController initiateWindowAction];
		return YES; // The application should indeed handle window reopening
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
		_windowController = [[WindowController alloc] init];
		[_windowController initiateWindowAction];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
		[_windowController release];
		_windowController = nil;
}

- (BOOL) application:(NSApplication *)application openFile:(NSString *)filename {
		return [_windowController openFile:filename];
}

- (IBAction) openDocument:(id)sender {
		[_windowController presentOpenDialog];
}

@end
