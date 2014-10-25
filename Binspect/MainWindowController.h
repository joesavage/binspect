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
    NSData   *_data;
    
    IBOutlet NSScrollView *_scrollView;
    IBOutlet NSOpenGLView *_openGLView;
    IBOutlet NSProgressIndicator *_curvePanelProgressIndicator;
}

- (void)beginApplication;
- (void)presentOpenDialog;
- (void)windowWillClose:(NSNotification *)notification;
- (BOOL)openFile:(NSString *)filename;

@end