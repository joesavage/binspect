//
//  AppDelegate.h
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	WindowController *_windowController;
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)hasVisibleWindows;
- (void) applicationDidFinishLaunching:(NSNotification *)notification;
- (void) applicationWillTerminate:(NSNotification *)notification;
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (IBAction) openDocument:(id)sender;

@end
