//
//  SBWindowController.m
//  Binspect
//
//  Created by Joe Savage on 24/10/2014.
//

#import "SBWindowController.h"
#import "SBCurveView.h"

@implementation SBWindowController

// An 'init' method for the class
- (id) init {
	self = [super initWithWindowNibName:@"MainWindow"];
	if (self) {
		_filePath = nil;
		_data = nil;
	}
	
	return self;
}

// A 'dealloc' method for the class
- (void) dealloc {
	[_filePath release];
	[_data release];
	[super dealloc];
}

// A static method to calculate the Shannon Entropy for a block of data, from an index, in an NSData object.
+ (CGFloat) calculateShannonEntropy:(NSData *)data fromIndex:(NSInteger)index forBlockSize:(NSInteger)blocksize {
	if (data.length < blocksize)
		blocksize = data.length;
	
	const unsigned char *bytes = (const unsigned char *)data.bytes;
	NSInteger halfBlockSize = (blocksize / 2),
	          startIndex = index - halfBlockSize;
	
	// Establish the block beginning and ending indices
	if (index < halfBlockSize)
		startIndex = 0;
	else if (index > (data.length - 1 - halfBlockSize))
		startIndex = data.length - 1 - halfBlockSize;
	
	// Generate a dictionary of frequencies for the different byte values in the specified block
	NSMutableDictionary *frequencies = [[NSMutableDictionary alloc] init];
	for (NSUInteger i = startIndex; i < startIndex + blocksize; i++) {
		NSNumber *key = [NSNumber numberWithUnsignedChar:bytes[i]];
		NSUInteger freq = [[frequencies objectForKey:key] integerValue] + 1;
		[frequencies setObject:[NSNumber numberWithUnsignedLong:freq] forKey:key];
	}
	
	// Calculate the Shannon Entropy from the frequencies
	float entropy = 0.0f,
	logBlockSize = logf(blocksize);
	for (id frequencyKey in frequencies) {
		float p = (float)[[frequencies objectForKey:frequencyKey] integerValue] / (float)blocksize;
		entropy -= (p * (logf(p) / logBlockSize));
	}
	[frequencies release];
	
	return entropy;
}

// A method to update the window title based on a specified string
- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName {
	if (displayName.length == 0)
		return @"Binspect";
	
	displayName = [displayName componentsSeparatedByString:@"/"].lastObject;
	return [NSString stringWithFormat:@"Binspect — %@", displayName];
}

// A method to open a file from a path, returning YES or NO depending on whether the file was opened successfully.
- (BOOL) openFile:(NSString *)filename {
	// Open the file from the path, checking if it meets the application-handled constraints.
	// Note: The 'NSMappedRead' option might be useful for big files?
	NSData *data = [NSData dataWithContentsOfFile:filename];
	if (data == nil || data.length == 0 || data.length >= NSIntegerMax)
		return NO;
	
	// Add the file path to the 'Open Recent' list for this application
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	
	_filePath = [filename retain];
	_data = [data retain];
	[self.window setTitle:[self windowTitleForDocumentDisplayName:_filePath]];
	[self initiateWindowAction];
	return YES;
}

// A method to present an open dialog to the user, loading the file through the 'openFile' method after selection.
- (void) presentOpenDialog {
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	
	[openPanel setTitle: @"Select a file for analysis"];
	[openPanel setShowsResizeIndicator: YES];
	[openPanel setShowsHiddenFiles: NO];
	[openPanel setCanChooseDirectories: NO];
	[openPanel setCanCreateDirectories: YES];
	[openPanel setAllowsMultipleSelection: NO];
	
	if ([openPanel runModal] == NSModalResponseOK) {
		NSURL *selection = openPanel.URLs.firstObject;
		NSString *path = selection.path.stringByResolvingSymlinksInPath;
		[self openFile:path];
	}
}

// A method invoked when the value of a segmented control is clicked
- (IBAction) segmentedControlClicked:(id)sender {
	[_curvePanelProgressIndicator startAnimation:self];
	switch (_curveTypeSegmentedControl.selectedSegment) {
		case 0:
			[_curveView setCurveType:SBCurveViewTypeHilbert];
			break;
		case 1:
			[_curveView setCurveType:SBCurveViewTypeZigzag];
			break;
	}
	
	switch (_curveColouringSegmentedControl.selectedSegment) {
		case 0:
			[_curveView setCurveColourMode:SBCurveViewColourModeSimilarity];
			break;
		case 1:
			[_curveView setCurveColourMode:SBCurveViewColourModeEntropy];
			break;
		case 2:
			[_curveView setCurveColourMode:SBCurveViewColourModeStructural];
			break;
	}
	
	[_curveView draw];
	[_curvePanelProgressIndicator stopAnimation:self];
}

// A method to change the value of a segmented control, calling 'segmentedControlClicked' to simulate a user click action
- (void) changeSegmentedControl:(NSSegmentedControl *)segmentedControl toIndex:(NSInteger)index {
	[segmentedControl setSelectedSegment:index];
	[self segmentedControlClicked:nil];
}

// A method to update the file-based labels in the window
- (void) updateFileLabels {
	NSString *fileName = @"N/A", *fileSize = @"0 bytes", *fileSizeHex = @"0x000000", *fileEntropy = @"0.00%";
	
	if (_data.length > 0) {
		fileName = [_filePath componentsSeparatedByString:@"/"].lastObject;
		fileSize = [NSString stringWithFormat:@"%lu bytes", _data.length];
		fileSizeHex = [NSString stringWithFormat:@"(0x%06lX)", _data.length];
		
		// Note: The shannon entropy like this for the entire file often isn't particularly useful as it varies wildly
		// depending on the size of the file. Consider changing, removing, or moving to a selection-based statistic.
		fileEntropy = [NSString stringWithFormat:@"%.02f%%", [SBWindowController calculateShannonEntropy:_data fromIndex:0 forBlockSize:_data.length]*100];
	}
	
	_fileNameLabel.stringValue = fileName;
	_fileSizeLabel.stringValue = fileSize;
	_fileSizeHexLabel.stringValue = fileSizeHex;
	_fileEntropyLabel.stringValue = fileEntropy;
}

// A method called when the window should begin action after standing idle
- (void) initiateWindowAction {
	if (_filePath.length == 0) {
		// If no file path has been specified, present the open dialog for file selection.
		[self presentOpenDialog];
	} else {
		// Moves the window to the front of the screen list and makes it the key window
		[self.window makeKeyAndOrderFront:nil];
		
		// Update labels and set the data source to the specified file
		[_curvePanelProgressIndicator startAnimation:self];
		[self updateFileLabels];
		[_curveView setDataSource:_data];
		[_curvePanelProgressIndicator stopAnimation:self];
		
		// Re-register any previous segmented control selections
		[self segmentedControlClicked:nil];
	}
}

// Invoked when the window that this controller is managing has been loaded from its nib file
- (void) windowDidLoad {
	[super windowDidLoad];
	
	// Initialize class properties
	_zoomLevel = 1;
	_hoverRegionSize = 64;
	[_curveView setZoomLevel:_zoomLevel];
	
	// Register the window NSWindowWillCloseNotification to our 'windowWillClose' controller method
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(windowWillClose:)
										  name:NSWindowWillCloseNotification
										  object:self.window];
}

// Invoked when the window that this controller is managing will close (registered in 'windowDidLoad')
- (void) windowWillClose:(NSNotification *)notification {
	[self windowTitleForDocumentDisplayName:nil];
	
	[_filePath release];
	_filePath = nil;
	[_data release];
	_data = nil;
	
	[self updateFileLabels];
	[_curveView clearState];
}

// A delegate method for _hexTableView to get the view that should be used for a specific table cell.
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (_selectionRegionEndIndex - _selectionRegionStartIndex == 0)
		return nil;
	
	// Formulate the identifier name for the table view cell in Interface Builder which should be copied for this particular cell.
	NSString *viewIdentifier = @"hexView";
	viewIdentifier = [viewIdentifier stringByAppendingString:tableColumn.identifier];
	
	// Create a new NSTableCellView from the identifier, and set its value as appropriate to its column and row.
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
		for (unsigned char i = 0; i < 8; i++) {
			unsigned char value = bytes[_selectionRegionStartIndex + row * 8 + i];
			resultString = [resultString stringByAppendingFormat:@"%c", (isprint(value) ? value : ' ')];
		}
	}
	
	result.textField.stringValue = resultString;
	return result;
}

// A delegate method for _hexTableView to get the number of rows that should be present in the table.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
	// There should always be eight rows in the hex table view.
	return 8;
}

// A delegate method for _curveView, invoked when the user hovers their mouse over an invalid byte visualisation area in the view.
- (void) curveViewMouseMovedToInvalidIndex {
	_hoveredMemoryAddressLabel.stringValue = @"N/A";
	_hoveredRegionMemoryAddressRangeLabel.stringValue = @"N/A";
	
	_selectionRegionStartIndex = 0;
	_selectionRegionEndIndex = 0;
	
	[_hexTableView reloadData];
}

// A delegate method for _curveView, invoked when the user hovers their mouse over a valid visualised byte in the view.
- (void) curveViewMouseMovedToIndex:(NSInteger)index {
	NSUInteger regionStartIndex = index,
	           regionEndIndex = index + _hoverRegionSize,
	           maximumDataIndex = _data.length - 1;
	
	// If the selected region spans over the end of the data, move the indices back so it doesn't.
	if (regionEndIndex > maximumDataIndex) {
		regionStartIndex = maximumDataIndex - _hoverRegionSize;
		regionEndIndex = maximumDataIndex;
	}
	
	_selectionRegionStartIndex = regionStartIndex;
	_selectionRegionEndIndex = regionEndIndex;
	
	_hoveredMemoryAddressLabel.stringValue = [NSString stringWithFormat:@"0x%06lX", index];
	_hoveredRegionMemoryAddressRangeLabel.stringValue = [NSString stringWithFormat:@"0x%06lX - 0x%06lX", regionStartIndex, regionEndIndex];
	[_hexTableView reloadData];
}

// A method to handle the action sent from the 'Copy' command in the menu bar
- (IBAction) copy:(id)sender {
	// If there is no current selected region, we don't want to do any copying.
	if (_selectionRegionStartIndex == _selectionRegionEndIndex)
		return;
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	
	// For each row in the hex table view, add that row's data (in a pretty format) to the string we'll change the clipboard to
	NSString *copiedString = @"";
	NSUInteger rowMemoryAddress = _selectionRegionStartIndex;
	for (NSInteger row = 0; row < _hexTableView.numberOfRows; row++) {
		NSTextField *firstColumnTextField = [[_hexTableView viewAtColumn:0 row:row makeIfNecessary:YES] textField],
		            *secondColumnTextField = [[_hexTableView viewAtColumn:1 row:row makeIfNecessary:YES] textField];
		
		copiedString = [copiedString stringByAppendingFormat:@"%06lX | %@   %@\n", rowMemoryAddress, firstColumnTextField.stringValue, secondColumnTextField.stringValue];
		rowMemoryAddress += 8;
	}
	
	// Set the clipboard contents to the assembled string
	[pasteboard setString:copiedString forType:NSStringPboardType];
}

// A method to handle the action sent from the 'Zoom In' command in the menu bar
- (IBAction) zoomIn:(id)sender {
	if ([_curveView isValidZoomLevel:_zoomLevel + 1]) {
		[_curveView setZoomLevel:++_zoomLevel];
		[_curveView draw];
	}
}

// A method to handle the action sent from the 'Zoom Out' command in the menu bar
- (IBAction) zoomOut:(id)sender {
	if ([_curveView isValidZoomLevel:_zoomLevel - 1]) {
		[_curveView setZoomLevel:--_zoomLevel];
		[_curveView draw];
	}
}

// A method to handle the action sent from the 'Reload' command in the menu bar, and from the 'Reload' button
- (IBAction) reload:(id)sender {
	[self openFile:_filePath];
}

// Methods to handle the actions sent from different curve type commands from the menu bar
- (IBAction) selectPrimaryCurveType:(id)sender {
	[self changeSegmentedControl:_curveTypeSegmentedControl toIndex:0];
}
- (IBAction) selectSecondaryCurveType:(id)sender {
	[self changeSegmentedControl:_curveTypeSegmentedControl toIndex:1];
}

// Methods to handle the actions sent from different curve colouring mode commands from the menu bar
- (IBAction) selectPrimaryCurveColouringMode:(id)sender {
	[self changeSegmentedControl:_curveColouringSegmentedControl toIndex:0];
}
- (IBAction) selectSecondaryCurveColouringMode:(id)sender {
	[self changeSegmentedControl:_curveColouringSegmentedControl toIndex:1];
}
- (IBAction) selectTertiaryCurveColouringMode:(id)sender {
	[self changeSegmentedControl:_curveColouringSegmentedControl toIndex:2];
}

@end
