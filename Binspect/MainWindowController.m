//
//  MainWindowController.m
//  Binspect
//
//  Created by Joe Savage on 24/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "MainWindowController.h"

@interface MainWindowController ()

@end

@implementation MainWindowController

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
        _filePath = nil;
        
    }
    
    return self;
}

- (void)dealloc {
    [_filePath release];
    [super dealloc];
}

- (void)presentOpenDialog:(NSWindow *)window {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    openPanel.title = @"Select a file for analysis";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    
    [openPanel beginSheetModalForWindow:window
                      completionHandler:^(NSInteger result) {
                          if (result == NSModalResponseOK) {
                              NSURL *selection = openPanel.URLs[0];
                              NSString *path = [selection.path stringByResolvingSymlinksInPath];
                              _filePath = [path retain];
                              [self beginApplication];
                          }
                      }
     ];
}

- (void)beginApplication {
    if([_filePath length] == 0) {
        [self presentOpenDialog:nil];
    } else {
        // Moves the window to the front of the screen list, within its level, and makes it the key window
        [[self window] makeKeyAndOrderFront:nil];
        [_curvePanelProgressIndicator startAnimation:self];
        
        // TODO: Pass the file path to a model class to deal with, then stop the spinning indicator.
    }
}

- (void)windowDidLoad { // Invoked when this controller's window has been loaded from its nib file
    [super windowDidLoad];
}

@end
