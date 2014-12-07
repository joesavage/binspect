//
//  SBAppDelegate.m
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//

#import "SBAppDelegate.h"
#import "SBWindowController.h"

@implementation SBAppDelegate

// An application delegate method invoked prior to default re-open behaviour
- (BOOL) applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)hasVisibleWindows {
	// Tell the window controller to initiate an action, and return that the application successfully handled the re-open request
	if (!hasVisibleWindows) [_windowController initiateWindowAction];
	return YES;
}

// An application delegate method invoked when the application has finished launching
- (void) applicationDidFinishLaunching:(NSNotification *)notification {
	// Allocate and initialise an SBWindowController instance, calling 'initiateWindowAction' on it to kick things off
	_windowController = [[SBWindowController alloc] init];
	[_windowController initiateWindowAction];
}

// An application delegate method invoked when the application is about to terminate
- (void) applicationWillTerminate:(NSNotification *)notification {
	// Release the NSNotification instance allocated in 'applicationDidFinishLaunching'
	[_windowController release];
	_windowController = nil;
}

// An application delegate method to handle opening a file with the specified path
- (BOOL) application:(NSApplication *)application openFile:(NSString *)filename {
	return [_windowController openFile:filename];
}

// A method to handle the action sent from the 'Open' command in the menu bar
// (Should be available even when the main window is closed, so defined in this file)
- (IBAction) openDocument:(id)sender {
	[_windowController presentOpenDialog];
}

@end
