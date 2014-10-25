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
        _data = nil;
    }
    
    return self;
}

- (void)dealloc {
    [_filePath release];
    [_data release];
    [super dealloc];
}

- (NSString *) windowTitleForDocumentDisplayName: (NSString *) displayName {
    if ([displayName length] == 0) return @"Binspect";
    displayName = [[displayName componentsSeparatedByString:@"/"] lastObject];
    return [NSString stringWithFormat:@"Binspect — %@", displayName];
}

- (BOOL)openFile:(NSString *)filename {
    _filePath = [filename retain];
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:_filePath]];
    [self beginApplication];
    return YES;
}

- (void)presentOpenDialog {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setTitle: @"Select a file for analysis"];
    [openPanel setShowsResizeIndicator: YES];
    [openPanel setShowsHiddenFiles: NO];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setCanCreateDirectories: YES];
    [openPanel setAllowsMultipleSelection: NO];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL *selection = [openPanel.URLs firstObject];
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:selection];
        NSString *path = [[selection path] stringByResolvingSymlinksInPath];
        [self openFile:path];
    }
}

- (void)beginApplication {
    if([_filePath length] == 0) {
        [self presentOpenDialog];
    } else {
        // Moves the window to the front of the screen list, within its level, and makes it the key window
        [[self window] makeKeyAndOrderFront:nil];
        
        {
            [_curvePanelProgressIndicator startAnimation:self];
            _data = [[NSData dataWithContentsOfFile:_filePath] retain]; // Note: Could use option 'NSMappedRead' if file is too large
                                                               // Second Note: Disk errors /could/ occur here theoretically.
        
            // TODO: Pass this data to a model to get data to draw to the curve view with selected algorithms.
            
            //[_curvePanelProgressIndicator stopAnimation:self];
        }
    }
}

- (void)windowDidLoad { // Invoked when this controller's window has been loaded from its nib file
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(windowWillClose:)
                                          name:NSWindowWillCloseNotification
                                          object:[self window]];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self windowTitleForDocumentDisplayName:nil];
    
    [_filePath release];
    _filePath = nil;
    [_data release];
    _data = nil;
}

@end
