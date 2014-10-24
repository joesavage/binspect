//
//  MainWindowController.h
//  Binspect
//
//  Created by Joe Savage on 24/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController
{
    NSString *_filePath;
    
    IBOutlet NSProgressIndicator *_curvePanelProgressIndicator;
    NSMenu *_menu;
}

- (id)init;
- (void)beginApplication;
- (void)presentOpenDialog:(NSWindow *)window;

@end