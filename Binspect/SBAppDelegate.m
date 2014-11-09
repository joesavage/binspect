//
//  SBAppDelegate.m
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "SBAppDelegate.h"
#import "SBWindowController.h"

@implementation SBAppDelegate

- (BOOL) applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)hasVisibleWindows {
		if (!hasVisibleWindows) [_windowController initiateWindowAction];
		return YES; // The application has decided to open in response to this reopen request
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
		_windowController = [[SBWindowController alloc] init];
		[_windowController initiateWindowAction];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
		[_windowController release];
		_windowController = nil;
}

- (BOOL) application:(NSApplication *)application openFile:(NSString *)filename {
		return [_windowController openFile:filename];
}

// A method to handle the action sent from the 'Open' command in the menu bar
// (Should be available even when the main window is closed, so defined in this file)
- (IBAction) openDocument:(id)sender { [_windowController presentOpenDialog]; }

@end
