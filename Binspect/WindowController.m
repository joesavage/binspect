//
//  MainWindowController.m
//  Binspect
//
//  Created by Joe Savage on 24/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "WindowController.h"
#import "CurveView.h"

@implementation WindowController

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
    // Note: Disk errors /could/ occur here. Also, option 'NSMappedRead' might be useful for big files.
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) return NO;
    
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
    _filePath = [filename retain];
    _data = [data retain];
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
        NSString *path = [[selection path] stringByResolvingSymlinksInPath];
        [self openFile:path];
    }
}

- (IBAction) segmentedControlClicked:(id)sender {
    [_curveView setCurveTypeBlank];
    [_curveView redraw];
    
    switch ([_curveTypeSegmentedControl selectedSegment]) {
        case 0:
            [_curveView setCurveTypeHilbert];
            break;
        case 1:
            [_curveView setCurveTypeZigzag];
            break;
    }
    
    switch ([_curveColouringSegmentedControl selectedSegment]) {
        case 0:
            [_curveView setCurveColourModeSimilarity];
            break;
        case 1:
            [_curveView setCurveColourModeEntropy];
            break;
        case 2:
            [_curveView setCurveColourModeStructural];
    }
    
    [_curvePanelProgressIndicator startAnimation:self];
    [_curveView redraw];
    [_curvePanelProgressIndicator stopAnimation:self];
}

- (void)beginApplication {
    if([_filePath length] == 0) {
        [self presentOpenDialog];
    } else {
        // Moves the window to the front of the screen list, within its level, and makes it the key window
        [[self window] makeKeyAndOrderFront:nil];
        [_curvePanelProgressIndicator startAnimation:self];
        [self segmentedControlClicked:nil];
        
        // TODO: Pass the data to a model to get data to draw to the curve view with selected algorithms.
        
        
        [_curvePanelProgressIndicator stopAnimation:self];
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