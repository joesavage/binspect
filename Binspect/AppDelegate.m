//
//  AppDelegate.m
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize _mainWindowController;

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [_mainWindowController beginApplication];
    return YES; // The application should indeed handle window reopening
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _mainWindowController = [[MainWindowController alloc] init];
    [_mainWindowController beginApplication];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_mainWindowController release];
    _mainWindowController = nil;
}

@end
