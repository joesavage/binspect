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

// TODO: Possibly move this and some other things into their own file (static class or whatever)
+ (CGFloat) calculateShannonEntropy:(NSData*)data fromIndex:(long)index forBlockSize:(long)blocksize {
	if ([data length] < blocksize) blocksize = [data length];
	
	const unsigned char *bytes = (const unsigned char*)[data bytes];
	long halfBlockSize = (blocksize / 2),
	startIndex    = index - halfBlockSize;
	
	if (index < halfBlockSize) startIndex = 0;
	else if (index > ([data length] - 1 - halfBlockSize)) startIndex = [data length] - 1 - halfBlockSize;
	
	NSMutableDictionary *frequencies = [[NSMutableDictionary alloc] init];
	for(unsigned long i = startIndex; i < startIndex + blocksize; i++) {
		NSNumber *key = [NSNumber numberWithUnsignedChar:bytes[i]];
		unsigned long freq = [[frequencies objectForKey:key] integerValue] + 1;
		[frequencies setObject:[NSNumber numberWithUnsignedLong:freq] forKey:key];
	}
	
	float entropy = 0.0f,
	logBlockSize = logf(blocksize);
	for(id frequencyKey in frequencies) {
		float p = (float)[[frequencies objectForKey:frequencyKey] integerValue] / (float)blocksize;
		entropy -= (p * (logf(p) / logBlockSize)); // Shannon Entropy
	}
	[frequencies release];
	
	return entropy;
}

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

// TODO: Should deal with max file size (probably sizeof(unsigned int)-1 or something) here
- (BOOL)openFile:(NSString *)filename {
	// Note: Disk errors /could/ occur here. Also, option 'NSMappedRead' might be useful for big files.
	NSData *data = [NSData dataWithContentsOfFile:filename];
	if (data == nil) return NO;
	
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	_filePath = [filename retain];
	_data = [data retain];
	[[self window] setTitle:[self windowTitleForDocumentDisplayName:_filePath]];
	[self initiateWindowAction];
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
	[_curvePanelProgressIndicator startAnimation:self];
	switch ([_curveTypeSegmentedControl selectedSegment]) {
		case 0:
			[_curveView setCurveType:CurveViewTypeHilbert];
			break;
		case 1:
			[_curveView setCurveType:CurveViewTypeZigzag];
			break;
	}
	
	switch ([_curveColouringSegmentedControl selectedSegment]) {
		case 0:
			[_curveView setCurveColourMode:CurveViewColourModeSimilarity];
			break;
		case 1:
			[_curveView setCurveColourMode:CurveViewColourModeEntropy];
			break;
		case 2:
			[_curveView setCurveColourMode:CurveViewColourModeStructural];
	}
	
	[_curveView redraw];
	[_curvePanelProgressIndicator stopAnimation:self];
}

- (void) updateLabels {
	NSString *fileName = @"N/A", *fileSize = @"0 bytes", *fileSizeHex = @"0x000000", *fileEntropy = @"0.00%";
	
	if ([_data length] > 0) {
		fileName = [[_filePath componentsSeparatedByString:@"/"] lastObject];
		fileSize = [NSString stringWithFormat:@"%lu bytes", [_data length]];
		fileSizeHex = [NSString stringWithFormat:@"(0x%06lX)", [_data length]];
		fileEntropy = [NSString stringWithFormat:@"%.02f%%", [WindowController calculateShannonEntropy:_data fromIndex:0 forBlockSize:[_data length]]*100];
	}
	
	[_fileNameLabel setStringValue:fileName];
	[_fileSizeLabel setStringValue:fileSize];
	[_fileSizeHexLabel setStringValue:fileSizeHex];
	[_fileEntropyLabel setStringValue:fileEntropy];
}

- (void)initiateWindowAction {
	if([_filePath length] == 0) {
		[self presentOpenDialog];
	} else {
		// Moves the window to the front of the screen list, within its level, and makes it the key window
		[[self window] makeKeyAndOrderFront:nil];
		[_curvePanelProgressIndicator startAnimation:self];
		[self updateLabels];
		[_curveView setZoomLevel:_zoomLevel];
		[_curveView setDataSource:_data];
		[_curvePanelProgressIndicator stopAnimation:self];
		
		[self segmentedControlClicked:nil];
	}
}

- (void)windowDidLoad { // Invoked when this controller's window has been loaded from its nib file
	[super windowDidLoad];
	
	_zoomLevel = 1;
	_hoverRegionSize = 64;
	
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
	
	[self updateLabels];
	[_curveView clearState];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (_selectionRegionEndIndex - _selectionRegionStartIndex == 0) return nil;
	
	// Formulate the identifier name for the table view cell in Interface Builder which should be copied for this particular cell.
	NSString *viewIdentifier = @"hexView";
	viewIdentifier = [viewIdentifier stringByAppendingString:tableColumn.identifier];
	
	// Create a new NSTableCellView from the identifier, and set its value appropriately.
	NSTableCellView *result = [tableView makeViewWithIdentifier:viewIdentifier owner:self];
	NSString *resultString = @"";
	const unsigned char *bytes = _data.bytes;
	if ([tableColumn.identifier isEqualTo:@"Bytes"]) {
		resultString = [NSString stringWithFormat:@"%02X %02X %02X %02X %02X %02X %02X %02X",
						bytes[_selectionRegionStartIndex + row * 8 + 0], bytes[_selectionRegionStartIndex + row * 8 + 1],
						bytes[_selectionRegionStartIndex + row * 8 + 2], bytes[_selectionRegionStartIndex + row * 8 + 3],
						bytes[_selectionRegionStartIndex + row * 8 + 4], bytes[_selectionRegionStartIndex + row * 8 + 5],
						bytes[_selectionRegionStartIndex + row * 8 + 6], bytes[_selectionRegionStartIndex + row * 8 + 7]];
	}
	else {
		for(unsigned char i = 0; i < 8; i++) {
			unsigned char value = bytes[_selectionRegionStartIndex + row * 8 + i];
			resultString = [resultString stringByAppendingFormat:@"%c", (isprint(value) ? value : ' ')];
		}
	}
	
	result.textField.stringValue = resultString;

	return result;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return 8; // TODO: Or 0.
}

- (void) curveViewMouseMovedToInvalidIndex {
	[_hoveredMemoryAddressLabel setStringValue:@"N/A"];
	[_hoveredRegionMemoryAddressRangeLabel setStringValue:@"N/A"];
	
	_selectionRegionStartIndex = 0;
	_selectionRegionEndIndex = 0;
	
	[_tableView reloadData];
}
- (void) curveViewMouseMovedToIndex:(NSInteger)index {
	unsigned long regionStartIndex = index,
	              regionEndIndex = index + _hoverRegionSize,
				  maximumDataIndex = _data.length - 1;
	
	if (regionEndIndex > maximumDataIndex) {
		regionStartIndex = maximumDataIndex - _hoverRegionSize;
		regionEndIndex = maximumDataIndex;
	}
	
	_selectionRegionStartIndex = regionStartIndex;
	_selectionRegionEndIndex = regionEndIndex;
	
	[_hoveredMemoryAddressLabel setStringValue:[NSString stringWithFormat:@"0x%06lX", index]];
	[_hoveredRegionMemoryAddressRangeLabel setStringValue:[NSString stringWithFormat:@"0x%06lX - 0x%06lX", regionStartIndex, regionEndIndex]];
	[_tableView reloadData];
}

// A method to handle the action sent from the 'Open' command in the menu bar
- (IBAction) openDocument:(id)sender { [self presentOpenDialog]; }

// A method to handle the action sent from the 'Copy' command in the menu bar
- (IBAction) copy:(id)sender {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	NSString *copiedString = @"Copied!"; // TODO: Copy selected hex view data to clipboard
	[pasteboard setString:copiedString forType:NSStringPboardType];
}

@end
