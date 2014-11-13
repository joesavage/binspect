//
//  SBCurveView.m
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "SBCurveView.h"
#include <OpenGL/gl.h>

@implementation SBCurveView

// A method invoked when an instance of the view has been loaded from its nib file
- (void) awakeFromNib {
	// Track mouse entering, exiting, and movement when our window is the key window
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
																options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved |NSTrackingActiveInKeyWindow
																  owner:self
															   userInfo:nil];
	[self addTrackingArea:trackingArea];
	[trackingArea release];
	
	// Initialize class properties
	_data = nil;
	_scrollPosition = 0.0f;
	[self setZoomLevel:1];
	[self setCurveType:SBCurveViewTypeBlank];
	[self setCurveColourMode:SBCurveViewColourModeBlank];
}

// A 'dealloc' method for the class
- (void) dealloc {
	[self clearState];
	[super dealloc];
}

// The following three static methods are based on those shown on Wikipedia to
// convert to and from co-ordinates on 2D Hilbert curve and an index in a 1D array.
// http://en.wikipedia.org/wiki/Hilbert_curve#Applications_and_mapping_algorithms
+ (NSUInteger) getHilbertCurveIndex:(NSUInteger)size forCoords:(CGPoint)point {
	CGPoint rotation;
	NSUInteger result = 0, temporarySize;
	for (temporarySize = size / 2; temporarySize > 0; temporarySize /= 2) {
		rotation.x = ((int)point.x & temporarySize) > 0;
		rotation.y = ((int)point.y & temporarySize) > 0;
		result += temporarySize * temporarySize * ((3 * (int)rotation.x) ^ (int)rotation.y);
		[SBCurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&point];
	}
	
	return result;
}

+ (CGPoint) getHilbertCurveCoordinates:(NSUInteger)size forIndex:(NSUInteger)index {
	CGPoint rotation, result = CGPointMake(0, 0);
	NSUInteger temporarySize, temporaryIndex = index;
	for (temporarySize = 1; temporarySize < size; temporarySize *= 2) {
		rotation.x = 1 & (temporaryIndex / 2);
		rotation.y = 1 & (temporaryIndex ^ (int)rotation.x);
		[SBCurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&result];
		result.x += temporarySize * (int)rotation.x;
		result.y += temporarySize * (int)rotation.y;
		temporaryIndex /= 4;
	}
	
	return result;
}

+ (void) rotateHilbertCurveQuadrant:(NSUInteger)size by:(CGPoint)rotation forPoint:(CGPoint *)point {
	if (rotation.y == 0) {
		if (rotation.x == 1) {
			point->x = (size - 1) - point->x;
			point->y = (size - 1) - point->y;
		}
		
		// Swap coordinates, (x, y) -> (y, x)
		CGFloat temporary  = point->x;
		point->x = point->y;
		point->y = temporary;
	}
}

// The following two static methods are to convert to and from co-ordinates on a 2D Zigzag
// curve and an index in a 1D array.
+ (NSUInteger) getZigzagCurveIndex:(NSUInteger)width forCoords:(CGPoint)point {
	NSUInteger result, rowNumber = point.y;
	bool oddRow = (rowNumber % 2 == 1);
	result = (point.y * width) + (oddRow ? (width - 1) - point.x : point.x);
	
	return result;
}

+ (CGPoint) getZigzagCurveCoordinates:(NSUInteger)width forIndex:(NSUInteger)index {
	CGPoint result = CGPointMake(0, 0);
	NSUInteger rowNumber = index / width;
	bool oddRow = (rowNumber % 2 == 1);
	result.x = index % width;
	result.y = rowNumber;
	if (oddRow) result.x = (width - 1) - result.x;
	
	return result;
}

// A method to calculate an appropriate Hilbert-curve width (and technically, height, since the
// curves are square) based on the data length and a maximum width
- (NSUInteger) calculateHilbertChunkWidth:(NSUInteger)maxWidth {
	NSUInteger chunkWidth = ceil(sqrt(_data.length)); // Calculate the exact ideal chunk width(/height), and round it up.
	chunkWidth = pow(2, ceil(log2(chunkWidth))); // Round up to the next highest power of 2 (as required for our Hilbert usage)
	if (chunkWidth > maxWidth) chunkWidth = maxWidth;
	
	return chunkWidth;
}

// A method to get the index of the byte that the user is currenly hovering over in the view
- (NSUInteger) getIndexOfCurrentlyHoveredByte {
	NSUInteger index = 0,
			   maxWidth = _viewBounds.width / _pointSize;
	
	// Adjust the mouse positions to our curve view grid scale, with some adjustments in Y for accuracy
	_mousePosition.x = (NSUInteger)(_mousePosition.x / _pointSize);
	_mousePosition.y = (NSUInteger)((_mousePosition.y - 2.5f + _scrollPosition) / _pointSize);
	
	if (_type == SBCurveViewTypeHilbert) {
		// For getting the hovered index on a Hilbert curve, the positions need to be 'un-chunked' to get
		// the correct value from 'getHilbertCurveIndex: for Coords:' which expects a square curve
		NSUInteger hilbertWidth = [self calculateHilbertChunkWidth:maxWidth],
				   chunkArea    = (hilbertWidth * hilbertWidth),
				   chunkIndex   = (NSUInteger)(_mousePosition.y / hilbertWidth);
		CGPoint hilbertPoint = _mousePosition;
		hilbertPoint.y = (NSUInteger)_mousePosition.y % hilbertWidth;
		index = chunkIndex*chunkArea + [SBCurveView getHilbertCurveIndex:chunkArea forCoords:hilbertPoint];
	} else if (_type == SBCurveViewTypeZigzag) {
		index = [SBCurveView getZigzagCurveIndex:maxWidth forCoords:_mousePosition];
	}
	
	return index;
}

// A method to set the curve type to a specific SBCurveViewType, re-generating the _vertexArray mapping of
// bytes in the file to locations on screen
- (void) setCurveType:(SBCurveViewType)type {
	_type = type;
	switch(_type) {
		case SBCurveViewTypeHilbert:
			{
				// Spit the curve into chunks to be stacked on top of each other for rectangular viewing.
				//
				// A _pointSize of 2^(2n) works particularly well for this, as it produces a desirable 'chunkWidth'
				// which ensures that the Hilbert chunk will finish in the bottom left, and so tiles excellently
				// with, and has proper visual locality with, the next chunk.
				//
				// In fact, if _pointSize is not of this type then chunking makes the visualisation somewhat ugly.
				// I wouldn't recommend using this chunking method (and instead enabling horizontal scrolling
				// of a square curve) for _pointSize values which are not of this type.
				NSUInteger maxWidth = _viewBounds.width / _pointSize,
						   chunkWidth = [self calculateHilbertChunkWidth:maxWidth],
						   chunks = ceilf((float)_data.length / (float)(maxWidth * maxWidth));
				
				// Set the vertex array values for each chunk
				for(NSUInteger chunk = 0; chunk < chunks; chunk++) {
					NSUInteger currentChunkArea = chunkWidth * chunkWidth,
							   lastPointCovered = chunkWidth * chunkWidth * chunk;
					if (chunk + 1 == chunks) currentChunkArea = _data.length - lastPointCovered;
					
					// For each byte in this chunk, set the position as determined by 'getHilbertCurveCoordinates: forIndex:',
					// adjusting as appropriate for _pointSize, and for the Y position of this chunk
					for(NSUInteger i = 0; i < currentChunkArea; i++) {
						NSUInteger index = lastPointCovered + i;
						CGPoint point = [SBCurveView getHilbertCurveCoordinates:(chunkWidth * chunkWidth) forIndex:i];
						
						point.x = (point.x * _pointSize) + (_pointSize / 2.0f);
						point.y = (point.y * _pointSize) + (_pointSize / 2.0f);
						
						// Assign the (x, y, z) co-ordinates for this point in the vertex array
						_vertexArray[(3 * index)]     = point.x;
						_vertexArray[(3 * index) + 1] = point.y + (chunk * chunkWidth * _pointSize);
						_vertexArray[(3 * index) + 2] = 0.0f;
					}
				}
				break;
			}
		case SBCurveViewTypeZigzag:
			{
				// For each byte, set the position as determined by 'getZigzagCurveCoordinates: forIndex',
				// adjusting as appropriate for _pointSize
				for(NSUInteger i = 0; i < _data.length; i++) {
					CGPoint point = [SBCurveView getZigzagCurveCoordinates:(_viewBounds.width / _pointSize) forIndex:i];
					point.x = (point.x * _pointSize) + (_pointSize / 2.0f);
					point.y = (point.y * _pointSize) + (_pointSize / 2.0f);
					
					// Assign the (x, y, z) co-ordinates for this point in the vertex array
					_vertexArray[(3 * i)]     = point.x;
					_vertexArray[(3 * i) + 1] = point.y;
					_vertexArray[(3 * i) + 2] = 0.0f;
				}
				break;
			}
	}
}

// A method to set the curve colouring mode to a specific SBCurveViewColourMode, re-generating the
// _colourArray mapping of bytes in the file to colours
- (void) setCurveColourMode:(SBCurveViewColourMode)mode {
	_colourMode = mode;
	switch (_colourMode) {
		case SBCurveViewColourModeSimilarity:
			{
				// Similarity colour palette, generated through a Hilbert-order traversal of the RGB colour cube - more
				// specifically through the use of Aldo Cortesi's scurve swatch Python utility. This palette idea
				// itself was heavily inspired by the work of Cortesi.
				#include "ColourModeSimilarityPalette.c"
				const unsigned char *bytes = (const unsigned char *)(_data.bytes);
				
				// For each byte, set the RGB colour values to the appropriate colour based on the similarity palette.
				for(NSInteger i = 0; i < _data.length; i++) {
					_colourArray[(3 * i)] = palette[(3 * bytes[i])];
					_colourArray[(3 * i) + 1] = palette[(3 * bytes[i]) + 1];
					_colourArray[(3 * i) + 2] = palette[(3 * bytes[i]) + 2];
				}
			}
			break;
		case SBCurveViewColourModeEntropy:
			{
				NSUInteger blocksize = 128; // The number of bytes around this one which should be factored into the calculation
				if (_data.length < blocksize) blocksize = _data.length;
				
				NSInteger halfBlockSize = (blocksize / 2), previousStartIndex = 0;
				double logBlockSize = log(blocksize),
				       entropy = 0.0f;
				const unsigned char *bytes = (const unsigned char *)(_data.bytes);
				NSUInteger frequencies[256] = {0}; // An array indicating the number of different byte values (0 - 255)
				
				// For each byte, update the 'frequencies' array and modify the 'entropy' result for this block (rolling result),
				// and then finally set the colour for this byte.
				for(NSInteger i = 0; i < _data.length; i++) {
					// Calculate the position of this block
					NSInteger startIndex = i - halfBlockSize;
					if (i < halfBlockSize) startIndex = 0;
					else if (i > (_data.length - 1 - halfBlockSize)) startIndex = _data.length - 1 - halfBlockSize;
					
					if (i == 0) {
						// Calculate the frequencies and entropy for the first block
						for(NSUInteger j = startIndex; j < startIndex + blocksize; j++)
							frequencies[bytes[j]]++;
						
						// Standard shannon entropy calculation
						for(NSUInteger i = 0; i < 256; i++) {
							if (frequencies[i] == 0) continue;
							double p = (double)frequencies[i] / (double)blocksize;
							entropy -= (p * (log(p) / logBlockSize));
						}
					} else if (startIndex != previousStartIndex) {
						// Modify the frequencies and entropy result for this byte block
						
						// Remove a byte from the start of the block
						double p = (double)frequencies[bytes[previousStartIndex]] / (double)blocksize;
						entropy += (p * (log(p) / logBlockSize));
						frequencies[bytes[previousStartIndex]]--;
						if (frequencies[bytes[previousStartIndex]] != 0) {
							p = (double)frequencies[bytes[previousStartIndex]] / (double)blocksize;
							entropy -= (p * (log(p) / logBlockSize));
						}
						
						
						// Add a byte to the end of the block
						if (frequencies[bytes[previousStartIndex + blocksize]] != 0) {
							p = (double)frequencies[bytes[previousStartIndex + blocksize]] / (double)blocksize;
							entropy += (p * (log(p) / logBlockSize));
						}
						frequencies[bytes[previousStartIndex + blocksize]]++;
						p = (double)frequencies[bytes[previousStartIndex + blocksize]] / (double)blocksize;
						entropy -= (p * (log(p) / logBlockSize));
					}
					
					previousStartIndex = startIndex; // This start index is now the 'previous' index, for future iterations.
					

					// Set the RGB values for this byte (low entropy -> high entropy: black -> blue -> pink)
					// Note: Entropy values here are squared here to ensure that only the highest entropy areas
					//       show up noticably in the final colouring. Too much noise isn't useful to the user.
					float red = 0, blue = pow(entropy, 2);
					if (entropy > 0.5) red = 4 * pow(entropy - 0.5f, 2);
					_colourArray[(3 * i)] = red;
					_colourArray[(3 * i) + 1] = 0.0f;
					_colourArray[(3 * i) + 2] = blue;
				}
			}
			break;
		case SBCurveViewColourModeStructural:
			{
				// The cycle at which the structural colour pattern should repeat.
				// [ Alternative: absolute cycle size: 128 * 128 * 4. This can make it difficult ]
				// [ to see distinctions at different zoom sizes, however.                       ]
				const NSUInteger colourRepeatCycleSize = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize) * 2;
				bool repeatingPalette = (_data.length > colourRepeatCycleSize); // Whether this palette repeats
				
				// Set the colour palette (HSL hue cycle -> RGB)
				NSMutableArray *palette = [[NSMutableArray alloc] init];
				NSColorSpace *rgbSpace = [NSColorSpace sRGBColorSpace];
				for(NSUInteger i = 0; i < _data.length; i++) {
					float percentageComplete = (float)i / (float)_data.length;
					float hue = percentageComplete;
					
					if (repeatingPalette) hue = (float)i / (float)colourRepeatCycleSize;
					if (repeatingPalette && hue > 1.0f) break;
					
					if (hue > 1.0f) hue = (float)hue - (NSUInteger)hue; // Wrap the hue to the range 0.0f - 1.0f
					
					// Note: I reckon conversion is slow. Can probably be calculated sufficiently at/by compile time.
					NSColor *colour = [NSColor colorWithCalibratedHue:hue saturation:0.9f brightness:1.0f alpha:1.0f];
					[colour colorUsingColorSpace:rgbSpace];
					[palette addObject:colour];
				}
				
				// For each byte, set the colour to the corresponding colour in the generated palette.
				for(NSUInteger i = 0; i < _data.length; i++) {
					NSUInteger paletteIndex = i;
					if (repeatingPalette) paletteIndex = i % colourRepeatCycleSize;
					_colourArray[(i * 3)] = [[palette objectAtIndex:paletteIndex] redComponent];
					_colourArray[(i * 3) + 1] = [[palette objectAtIndex:paletteIndex] greenComponent];
					_colourArray[(i * 3) + 2] = [[palette objectAtIndex:paletteIndex] blueComponent];
				}
				
				[palette release];
			}
			break;
		case SBCurveViewColourModeRandom:
			// For each byte, set the colour to a 'randomly' generated colour.
			for(NSUInteger i = 0; i < (3 * _data.length); i++)
				_colourArray[i] = rand() / (float)RAND_MAX;
			break;
	}
}

// A method to set/change the data source of the view
- (void) setDataSource:(NSData *)data {
	if ([data isEqualToData:_data]) return; // Don't re-set the data source if it's not necessary.
	
	// Release the retained memory for the old data pointer, and set the data pointer to the newly
	// passed pointer, retaining the memory for our usage.
	[_data release];
	_data = nil;
	_data = [data retain];
	
	_scrollPosition = 0.0f; // Reset the user scroll position
	
	// C-style memory management for the vertex and colour arrays.
	// Free any currently allocated array memory, and 'calloc' (allocate and clear to 0) new arrays
	// of size 3 * sizeof(datatype) [each vertex and colour have three components (X, Y, Z and R, G, B)]
	if (_vertexArray != nil) free(_vertexArray);
	_vertexArray = nil;
	_vertexArray = (float*)calloc(3 * _data.length, sizeof(float));
	if (_colourArray != nil) free(_colourArray);
	_colourArray = nil;
	_colourArray = (float*)calloc(3 * _data.length, sizeof(float));
	
	// Specify the vertex and colour arrays for usage in OpenGL
	glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
	glColorPointer(3, GL_FLOAT, 0, _colourArray);
	
	// Draw a blank screen to the view
	[self setCurveType:SBCurveViewTypeBlank];
	[self setCurveColourMode:SBCurveViewColourModeBlank];
	[self draw];
	
	// Set the curve type and colour mode back to their specified values, ready for drawing
	[self setCurveType:_type];
	[self setCurveColourMode:_colourMode];
}

// An NSOpenGLView method invoked to initialise OpenGL state
- (void) prepareOpenGL {
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
}

// An NSOpenGLView method invoked when the view's visible rectangle changes
- (void) reshape {
	CGSize viewBounds = self.bounds.size;
	
	// If a reshape operation isn't necessary, don't perform one.
	if (viewBounds.height == _viewBounds.height && viewBounds.width == _viewBounds.width) return;
	
	_viewBounds = viewBounds;
	
	// Set the OpenGL viewport size and orthographic projection size
	glViewport(0, 0, _viewBounds.width, _viewBounds.height);
	glMatrixMode(GL_PROJECTION);
	glOrtho(0.0f, _viewBounds.width, _viewBounds.height, 0.0f, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

// A method to draw/redraw the contents of the view
- (void) draw
{
	// Clear the colour writing buffer, and load an identity matrix as our transformation matrix
	glClear(GL_COLOR_BUFFER_BIT);
	glLoadIdentity();
	
	// Translate by the distance scrolled.
	glTranslatef(0.0f, -_scrollPosition, 0.0f);
	
	// Only draw if we're not in the blank curve mode
	if (_type != SBCurveViewTypeBlank) {
		// Draw visible points only. Hilbert makes this more difficult to calculate, so draw a bit extra both sides.
		GLsizei sqArea = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize),
			    drawCount = (_viewBounds.height / _pointSize) * (_viewBounds.width / _pointSize) + sqArea,
		startDrawIndex = ((_scrollPosition / _pointSize) * (_viewBounds.width / _pointSize)) - sqArea / 2.0f;
		if (startDrawIndex < 0) startDrawIndex = 0;
		if ((startDrawIndex + drawCount) > _data.length) drawCount = (GLsizei)_data.length - startDrawIndex;
		
		// Draw points at the specified indices using the specified GL vertex and colour arrays.
		glDrawArrays(GL_POINTS, startDrawIndex, drawCount);
	}
	
	glFlush(); // Force execution of OpenGL commands
}

// A method to set the scroll position of the view
- (void) setScrollPosition:(float)position {
	// Define the minimum and maximum scroll positions
	NSUInteger minScrollPosition = 0,
			   maxScrollPosition = ceilf(_data.length / (_viewBounds.width / _pointSize)) * _pointSize;
	
	// Adjust the maximum scroll position such that the user can't scroll to a fully white screen
	if (maxScrollPosition >= _viewBounds.height / 4.0f) maxScrollPosition -= (_viewBounds.height / 4.0f);
	
	// Clamp and set the scroll position as appropriate
	if (position < minScrollPosition) _scrollPosition = minScrollPosition;
	else if (position > maxScrollPosition) _scrollPosition = maxScrollPosition;
	else _scrollPosition = position;
}

// A method invoked when the user scrolls while on the view
- (void) scrollWheel:(NSEvent *)event {
	[self setScrollPosition:(_scrollPosition - event.deltaY * 4.0f)];
	[self draw];
}

// A method to check whether a given zoom level is valid
- (BOOL) isValidZoomLevel:(NSInteger)zoomLevel {
	NSInteger zoomValue = powf(2, 2 * zoomLevel);
	return (zoomValue >= 1 && zoomValue <= (_viewBounds.width / 8));
}

// A method to set the zoom level (i.e. _pointSize) for the view
- (void) setZoomLevel:(NSInteger)zoomLevel {
	NSInteger oldPointSize = _pointSize;
	
	// The form 2^(2n) is for aesthetics - see comments in the Hilbert chunking code.
	_pointSize = pow(2, 2 * zoomLevel);
	glPointSize(_pointSize);
	[self setScrollPosition:(_scrollPosition * (pow((float)_pointSize, 2) / pow((float)oldPointSize, 2)))];
	[self setCurveType:_type];
	[self setCurveColourMode:_colourMode];
}

// A method invoked when the user's mouse exits the view
- (void) mouseExited:(NSEvent *)event {
	[_delegate curveViewMouseMovedToInvalidIndex];
}

// A method invoked when the user's mouse is moved in the view
- (void) mouseMoved:(NSEvent *)event {
	// Set the _mousePosition class properties to reflect this mouse event, adjusting
	// the recieved co-ordinates so that the origin is in the /top/ left
	_mousePosition = [self convertPoint:event.locationInWindow fromView:nil];
	_mousePosition.y = _viewBounds.height - _mousePosition.y;
	
	// Call delegate mouse movement methods as appropriate
	NSUInteger currentHoveredByteIndex = [self getIndexOfCurrentlyHoveredByte];
	if (currentHoveredByteIndex < _data.length)
		[_delegate curveViewMouseMovedToIndex:currentHoveredByteIndex];
	else
		[_delegate curveViewMouseMovedToInvalidIndex];
}

// A method to clear the state of the view so it is ready to be re-used
- (void) clearState {
	_scrollPosition = 0.0f; // Reset the user scroll position
	
	// Release/free any allocated memory
	[_data release];
	_data = nil;
	if (_vertexArray != nil) free(_vertexArray);
	_vertexArray = nil;
	if (_colourArray != nil) free(_colourArray);
	_colourArray = nil;
}

@end
