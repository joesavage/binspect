//
//  MainWindowController.h
//  Binspect
//
//  Created by Joe Savage on 24/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CurveView;

@interface WindowController : NSWindowController
{
    NSString *_filePath;
    NSData   *_data;
    
    
    IBOutlet NSSegmentedControl  *_curveTypeSegmentedControl;
    IBOutlet NSSegmentedControl  *_curveColouringSegmentedControl;
    IBOutlet CurveView           *_curveView;
    IBOutlet NSProgressIndicator *_curvePanelProgressIndicator;
    IBOutlet NSTextField         *_fileNameLabel, *_fileSizeLabel, *_fileSizeHexLabel, *_fileEntropyLabel,
                                 *_hoveredMemoryAddressLabel;
}

- (IBAction) segmentedControlClicked:(id)sender;
- (void)initiateWindowAction;
- (void)presentOpenDialog;
- (void)windowWillClose:(NSNotification *)notification;
- (BOOL)openFile:(NSString *)filename;

@end