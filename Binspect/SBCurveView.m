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

// The following three Hilbert curve algorithms are based on those shown on Wikipedia.
// http://en.wikipedia.org/wiki/Hilbert_curve#Applications_and_mapping_algorithms
+ (unsigned long) getHilbertCurveIndex:(unsigned long)size forCoords:(CGPoint)point {
	CGPoint rotation;
	unsigned long result = 0, temporarySize;
	for (temporarySize = size / 2; temporarySize > 0; temporarySize /= 2) {
		rotation.x = ((int)point.x & temporarySize) > 0;
		rotation.y = ((int)point.y & temporarySize) > 0;
		result += temporarySize * temporarySize * ((3 * (int)rotation.x) ^ (int)rotation.y);
		[SBCurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&point];
	}
	
	return result;
}

+ (CGPoint) getHilbertCurveCoordinates:(unsigned long)size forIndex:(unsigned long)index {
	CGPoint rotation, result = CGPointMake(0, 0);
	unsigned long temporarySize, temporaryIndex = index;
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

+ (void) rotateHilbertCurveQuadrant:(unsigned long)size by:(CGPoint)rotation forPoint:(CGPoint *)point {
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

+ (unsigned long) getZigzagCurveIndex:(unsigned long)width forCoords:(CGPoint)point {
	unsigned long result, rowNumber = point.y;
	bool oddRow = (rowNumber % 2 == 1);
	result = (point.y * width) + (oddRow ? (width - 1) - point.x : point.x);
	
	return result;
}

+ (CGPoint) getZigzagCurveCoordinates:(unsigned long)width forIndex:(unsigned long)index {
	CGPoint result = CGPointMake(0, 0);
	unsigned long rowNumber = index / width;
	bool oddRow = (rowNumber % 2 == 1);
	result.x = index % width;
	result.y = rowNumber;
	if (oddRow) result.x = (width - 1) - result.x;
	
	return result;
}

- (unsigned long) calculateHilbertChunkWidth:(unsigned long)maxWidth {
	// Calculate the exact ideal chunk width(/height), and round it up.
	unsigned long chunkWidth = ceil(sqrt(_data.length));
	
	// Round up to the next highest power of 2 (as required for our Hilbert usage)
	chunkWidth = pow(2, ceil(log2(chunkWidth)));
	
	// Spit the curve into chunks to be stacked on top of each other for rectangular viewing.
	//
	// A _pointSize of 2^(2n) works particularly well for this, as it produces a desirable 'chunkWidth'
	// which ensures that the Hilbert chunk will finish in the bottom left, and so tiles excellently
	// with, and has proper visual locality with, the next chunk.
	//
	// In fact, if _pointSize is not of this type then chunking makes the visualisation somewhat ugly.
	// I wouldn't recommend using this chunking method (and instead enabling horizontal scrolling
	// of a square curve) for _pointSize values which are not of this type.
	if (chunkWidth > maxWidth) chunkWidth = maxWidth;
	
	return chunkWidth;
}

- (unsigned long) getIndexOfCurrentlyHoveredByte {
	unsigned long index = 0,
			   maxWidth = _viewBounds.width / _pointSize;
	
	_mousePosition.x = (unsigned long)(_mousePosition.x / _pointSize);
	_mousePosition.y = (unsigned long)((_mousePosition.y - 2.5f + _scrollPosition) / _pointSize); // The 2.5f is a little accuracy adjustment factor. I assume for the little top border that the NSOpenGLView seems to have.
	
	if (_type == SBCurveViewTypeHilbert) {
		unsigned long hilbertWidth = [self calculateHilbertChunkWidth:maxWidth],
					  chunkArea    = (hilbertWidth * hilbertWidth),
					  chunkIndex   = (unsigned long)(_mousePosition.y / hilbertWidth);
		CGPoint hilbertPoint = _mousePosition;
		hilbertPoint.y = (unsigned long)_mousePosition.y % hilbertWidth;
		index = chunkIndex*chunkArea + [SBCurveView getHilbertCurveIndex:chunkArea forCoords:hilbertPoint];
	} else if (_type == SBCurveViewTypeZigzag) {
		index = [SBCurveView getZigzagCurveIndex:maxWidth forCoords:_mousePosition];
	}
	
	return index;
}

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
				unsigned long maxWidth   = _viewBounds.width / _pointSize,
							  chunkWidth = [self calculateHilbertChunkWidth:maxWidth],
								  chunks = ceilf((float)_data.length / (float)(maxWidth * maxWidth));
				
				// Set the vertex array values for each chunk
				for(int chunk = 0; chunk < chunks; chunk++) {
					unsigned long currentChunkArea = chunkWidth * chunkWidth,
								  lastPointCovered = chunkWidth * chunkWidth * chunk;
					if (chunk + 1 == chunks) currentChunkArea = _data.length - lastPointCovered;
					for(unsigned long i = 0; i < currentChunkArea; i++) {
						unsigned long index = lastPointCovered + i;
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
				for(int i = 0; i < _data.length; i++) {
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
- (void) setCurveColourMode:(SBCurveViewColourMode)mode {
	_colourMode = mode;
	switch (_colourMode) {
		case SBCurveViewColourModeSimilarity:
			{
				// Similarity colour palette, generated through a Hilbert-order traversal of the RGB colour cube - more
				// specifically through the use of Aldo Cortesi's scurve swatch Python utility. This palette idea
				// itself was heavily inspired by the work of Cortesi.
				#include "ColourModeSimilarityPalette.c"
				
				const unsigned char *bytes = (const unsigned char*)(_data.bytes);
				for(int i = 0; i < _data.length; i++) {
					_colourArray[(3 * i)] = palette[(3 * bytes[i])];
					_colourArray[(3 * i) + 1] = palette[(3 * bytes[i]) + 1];
					_colourArray[(3 * i) + 2] = palette[(3 * bytes[i]) + 2];
				}
			}
			break;
		case SBCurveViewColourModeEntropy:
			{
				// TODO: Clean up and properly comment this whole section
				unsigned long blocksize = 128;
				if (_data.length < blocksize) blocksize = _data.length;
				
				long halfBlockSize = (blocksize / 2), previousStartIndex = 0;
				double logBlockSize = log(blocksize);
				
				unsigned long frequencies[256] = {0};
				double entropy = 0.0f;
				for(long i = 0; i < _data.length; i++) {
					const unsigned char *bytes = (const unsigned char*)(_data.bytes);
					long startIndex    = i - halfBlockSize;
					
					if (i < halfBlockSize) startIndex = 0;
					else if (i > (_data.length - 1 - halfBlockSize)) startIndex = _data.length - 1 - halfBlockSize;
					
					if (i == 0) {
						for(unsigned long j = startIndex; j < startIndex + blocksize; j++)
							frequencies[bytes[j]]++;
						
						// Calculate Shannon Entropy
						for(unsigned int i = 0; i < 256; i++) {
							if (frequencies[i] == 0) continue;
							double p = (double)frequencies[i] / (double)blocksize;
							entropy -= (p * (log(p) / logBlockSize));
						}
					} else if (startIndex != previousStartIndex) {
						// Remove from start
						double p = (double)frequencies[bytes[previousStartIndex]] / (double)blocksize;
						entropy += (p * (log(p) / logBlockSize));
						frequencies[bytes[previousStartIndex]]--;
						if (frequencies[bytes[previousStartIndex]] != 0) {
							p = (double)frequencies[bytes[previousStartIndex]] / (double)blocksize;
							entropy -= (p * (log(p) / logBlockSize));
						}
						
						
						// Add to end
						if (frequencies[bytes[previousStartIndex + blocksize]] != 0) {
							p = (double)frequencies[bytes[previousStartIndex + blocksize]] / (double)blocksize;
							entropy += (p * (log(p) / logBlockSize));
						}
						frequencies[bytes[previousStartIndex + blocksize]]++;
						p = (double)frequencies[bytes[previousStartIndex + blocksize]] / (double)blocksize;
						entropy -= (p * (log(p) / logBlockSize));
					}
					
					previousStartIndex = startIndex;
					

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
				// Alternative: absolute cycle size: 128 * 128 * 4 => can be difficult to see distinctions at different zoom sizes.
				const unsigned int colourRepeatCycleSize = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize) * 2;
				bool repeatingPalette = (_data.length > colourRepeatCycleSize);
				NSMutableArray *palette = [[NSMutableArray alloc] init];
				NSColorSpace *rgbSpace = [NSColorSpace sRGBColorSpace];
				for(int i = 0; i < _data.length; i++) {
					float percentageComplete = (float)i / (float)_data.length;
					float hue = percentageComplete;
					
					if (repeatingPalette) hue = (float)i / (float)colourRepeatCycleSize;
					if (repeatingPalette && hue > 1.0f) break;
					
					if (hue > 1.0f) hue = (float)hue - (int)hue;
					NSColor *colour = [NSColor colorWithCalibratedHue:hue saturation:0.9f brightness:1.0f alpha:1.0f];
					[colour colorUsingColorSpace:rgbSpace];
					[palette addObject:colour];
				}
				
				for(int i = 0; i < _data.length; i++) {
					int paletteIndex = i;
					if (repeatingPalette) paletteIndex = i % colourRepeatCycleSize;
					_colourArray[(i * 3)] = [[palette objectAtIndex:paletteIndex] redComponent];
					_colourArray[(i * 3) + 1] = [[palette objectAtIndex:paletteIndex] greenComponent];
					_colourArray[(i * 3) + 2] = [[palette objectAtIndex:paletteIndex] blueComponent];
				}
				[palette release];
			}
			break;
		case SBCurveViewColourModeRandom:
			for(int i = 0; i < (3 * _data.length); i++)
				_colourArray[i] = rand() / (float)RAND_MAX;
			break;
	}
}

- (void) setDataSource:(NSData *)data {
	if ([data isEqualToData:_data]) return; // Don't re-set the data source if it's not necessary.
	
	[_data release];
	_data = nil;
	_data = [data retain];
	
	_scrollPosition = 0.0f;
	
	if (_vertexArray != nil) free(_vertexArray);
	_vertexArray = nil;
	_vertexArray = (float*)calloc(3 * _data.length, sizeof(float));
	if (_colourArray != nil) free(_colourArray);
	_colourArray = nil;
	_colourArray = (float*)calloc(3 * _data.length, sizeof(float));
	
	glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
	glColorPointer(3, GL_FLOAT, 0, _colourArray);
	
	
	[self setCurveType:SBCurveViewTypeBlank];
	[self setCurveColourMode:SBCurveViewColourModeBlank];
	[self setCurveType:_type];
	[self setCurveColourMode:_colourMode];
	[self redraw];
}

- (void) redraw { [self drawRect:self.bounds]; }

- (void) prepareOpenGL {
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
}

- (void) reshape {
	CGSize viewBounds = self.bounds.size;
	
	// If a reshape operation isn't necessary, don't perform one.
	if (viewBounds.height == _viewBounds.height && viewBounds.width == _viewBounds.width) return;
	
	_viewBounds = viewBounds;
	glViewport(0, 0, _viewBounds.width, _viewBounds.height);
	glMatrixMode(GL_PROJECTION);
	glOrtho(0.0f, _viewBounds.width, _viewBounds.height, 0.0f, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

- (void) drawRect: (NSRect)bounds
{
	glClear(GL_COLOR_BUFFER_BIT);
	glLoadIdentity();
	
	glTranslatef(0.0f, -_scrollPosition, 0.0f); // Translate by the distance scrolled.
	
	if (_type != SBCurveViewTypeBlank) { // Only draw if we're not in the blank curve mode
		// Draw only visible bytes (Hilbert makes this more difficult to calculate, so draw a bit extra both sides)
		GLsizei sqArea = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize),
			 drawCount = (_viewBounds.height / _pointSize) * (_viewBounds.width / _pointSize) + sqArea,
		startDrawIndex = ((_scrollPosition / _pointSize) * (_viewBounds.width / _pointSize)) - sqArea / 2.0f;
		if (startDrawIndex < 0) startDrawIndex = 0;
		if ((startDrawIndex + drawCount) > _data.length) drawCount = (GLsizei)_data.length - startDrawIndex;
		
		glDrawArrays(GL_POINTS, startDrawIndex, drawCount);
	}
	glFlush();
}

- (void) setScrollPosition:(float)position {
	unsigned long minScrollPosition = 0,
				  maxScrollPosition = ceilf(_data.length / (_viewBounds.width / _pointSize)) * _pointSize;
	if (maxScrollPosition >= _viewBounds.height / 4.0f) maxScrollPosition -= (_viewBounds.height / 4.0f);
	if (position < minScrollPosition) _scrollPosition = minScrollPosition;
	else if (position > maxScrollPosition) _scrollPosition = maxScrollPosition;
	else _scrollPosition = position;
}

- (void) scrollWheel:(NSEvent *)event {
	[self setScrollPosition:(_scrollPosition - event.deltaY * 4.0f)];
	[self redraw];
}

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

- (BOOL) isValidZoomLevel:(NSInteger)zoomLevel {
	NSInteger zoomValue = powf(2, 2 * zoomLevel);
	return (zoomValue >= 1 && zoomValue <= (_viewBounds.width / 8));
}

- (void) setZoomLevel:(NSInteger)zoomLevel {
	NSInteger oldPointSize = _pointSize;
	// The form 2^(2n) is for aesthetics - see comments in the Hilbert chunking code.
	_pointSize = pow(2, 2 * zoomLevel);
	glPointSize(_pointSize);
	[self setScrollPosition:(_scrollPosition * (pow((float)_pointSize, 2) / pow((float)oldPointSize, 2)))];
	[self setCurveType:_type];
	[self setCurveColourMode:_colourMode];
}

- (void) mouseExited:(NSEvent *)event {
	[_delegate curveViewMouseMovedToInvalidIndex];
}

- (void) mouseMoved:(NSEvent *)event {
	_mousePosition = [self convertPoint:event.locationInWindow fromView:nil];
	_mousePosition.y = _viewBounds.height - _mousePosition.y;
	
	unsigned long currentHoveredByteIndex = [self getIndexOfCurrentlyHoveredByte];
	if (currentHoveredByteIndex < _data.length)
		[_delegate curveViewMouseMovedToIndex:currentHoveredByteIndex];
	else
		[_delegate curveViewMouseMovedToInvalidIndex];
}

- (void) clearState {
	[_data release];
	_data = nil;
	_scrollPosition = 0.0f;
	
	if (_vertexArray != nil) free(_vertexArray);
	_vertexArray = nil;
	if (_colourArray != nil) free(_colourArray);
	_colourArray = nil;
}

- (void) dealloc {
	[self clearState];
	[super dealloc];
}

@end
