//
//  AppDelegate.h
//  Binspect
//
//  Created by Joe Savage on 18/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu *_menu;
}

@property (retain) MainWindowController *_mainWindowController;

@end

