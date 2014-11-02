//
//  CurveView.m
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import "CurveView.h"
#include <OpenGL/gl.h>

@implementation CurveView

// The following three Hilbert curve algorithms are based on those shown on Wikipedia.
// http://en.wikipedia.org/wiki/Hilbert_curve#Applications_and_mapping_algorithms
+ (unsigned long) getHilbertCurveIndex:(unsigned long)size forCoords:(CGPoint)point {
    CGPoint rotation;
    unsigned long result = 0, temporarySize;
    for (temporarySize = size / 2; temporarySize > 0; temporarySize /= 2) {
        rotation.x = ((int)point.x & temporarySize) > 0;
        rotation.y = ((int)point.y & temporarySize) > 0;
        result += temporarySize * temporarySize * ((3 * (int)rotation.x) ^ (int)rotation.y);
        [CurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&point];
    }
    
    return result;
}

+ (CGPoint) getHilbertCurveCoordinates:(unsigned long)size forIndex:(unsigned long)index {
    CGPoint rotation, result = CGPointMake(0, 0);
    unsigned long temporarySize, temporaryIndex = index;
    for (temporarySize = 1; temporarySize < size; temporarySize *= 2) {
        rotation.x = 1 & (temporaryIndex / 2);
        rotation.y = 1 & (temporaryIndex ^ (int)rotation.x);
        [CurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&result];
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

+ (unsigned int) getZigzagCurveIndex:(unsigned int)width forCoords:(CGPoint)point {
    unsigned int result, rowNumber = point.y;
    bool oddRow = (rowNumber % 2 == 1);
    result = (point.y * width) + (oddRow ? (width - 1) - point.x : point.x);
    
    return result;
}

+ (CGPoint) getZigzagCurveCoordinates:(unsigned int)width forIndex:(unsigned int)index {
    CGPoint result = CGPointMake(0, 0);
    unsigned int rowNumber = index / width;
    bool oddRow = (rowNumber % 2 == 1);
    result.x = index % width;
    result.y = rowNumber;
    if (oddRow) result.x = (width - 1) - result.x;
    
    return result;
}

// Note: _vertexArray and _colourArray should be indexed the same as _data (for sequential drawing, indexed access, etc.)
- (void) setCurveType:(CurveViewType)type {
    _type = type;
    switch(_type) {
        case CurveViewTypeHilbert:
            {
                unsigned int nearestPowerOfTwo = (unsigned int)(sqrt([_data length]) + 0.5f);
                
                // Bit Twiddling Hacks: "Round up to the next highest power of 2"
                // http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
                nearestPowerOfTwo--;
                nearestPowerOfTwo |= nearestPowerOfTwo >> 1;
                nearestPowerOfTwo |= nearestPowerOfTwo >> 2;
                nearestPowerOfTwo |= nearestPowerOfTwo >> 4;
                nearestPowerOfTwo |= nearestPowerOfTwo >> 8;
                nearestPowerOfTwo |= nearestPowerOfTwo >> 16;
                nearestPowerOfTwo++;
                
                // Spit the curve into chunks to be stacked on top of each other for rectangular viewing.
                //
                // A _pointSize of 2^(2n) works particularly well for this, as it produces a desirable 'chunkWidth'
                // which ensures that the Hilbert chunk will finish in the bottom left, and so tiles excellently
                // with, and has proper visual locality with, the next chunk.
                //
                // In fact, if _pointSize is not of this type then chunking makes the visualisation somewhat ugly.
                // I wouldn't recommend using this chunking method (and instead enabling horizontal scrolling
                // of a square curve) for _pointSize values which are not of this type.
                unsigned long chunkWidth = nearestPowerOfTwo,
                              chunks    = 1,
                              maxWidth  = _viewBounds.width / _pointSize;
                if (nearestPowerOfTwo > maxWidth) {
                    chunkWidth = maxWidth;
                    chunks = (unsigned long)(((float)[_data length] / (float)(maxWidth * maxWidth)) + 1.0f);
                }
                
                // Set the vertex array values for each chunk
                for(int chunk = 0; chunk < chunks; chunk++) {
                    unsigned long currentChunkArea = chunkWidth * chunkWidth,
                                  lastPointCovered = chunkWidth * chunkWidth * chunk;
                    if (chunk + 1 == chunks) currentChunkArea = [_data length] - lastPointCovered;
                    for(unsigned long i = 0; i < currentChunkArea; i++) {
                        unsigned long index = lastPointCovered + i;
                        CGPoint point = [CurveView getHilbertCurveCoordinates:(chunkWidth * chunkWidth) forIndex:i];
                        
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
        case CurveViewTypeZigzag:
            {
                for(int i = 0; i < [_data length]; i++) {
                    CGPoint point = [CurveView getZigzagCurveCoordinates:(_viewBounds.width / _pointSize) forIndex:i];
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
- (void) setCurveColourMode:(CurveViewColourMode)mode {
    if (mode == _colourMode) return; // Don't re-set the colour mode if it's not necessary.
    
    _colourMode = mode;
    switch (_colourMode) {
        case CurveViewColourModeSimilarity:
            {
                // TODO: Actually use a colour palette here (where similar bytes have similar colours)
                // [Using varying hues isn't sufficient here as the cyclical nature means that very different
                //   values may have very similar colours]
                //
                // ALSO: At current, this colour scheme collides with the background colour. Fix.
                const unsigned char *bytes = (const unsigned char*)[_data bytes];
                for(int i = 0; i < [_data length]; i++) {
                    _colourArray[(3 * i)] = bytes[i] / 255.0f;
                    _colourArray[(3 * i) + 1] = bytes[i] / 255.0f;
                    _colourArray[(3 * i) + 2] = bytes[i] / 255.0f;
                }
            }
            break;
        case CurveViewColourModeEntropy:
            for(int i = 0; i < (3 * [_data length]); i++)
                _colourArray[i] = rand() / (float)RAND_MAX;
            break;
        case CurveViewColourModeStructural:
            {
                // Note: Being able to change the repeat cycle size in preferences might be a nice touch for the future.
                // To consider: Having the cycle never repeat is useful sometimes (mainly for seeing raw files offsets)
                // [ Alt. absolute cycle size: 128 * 128 * 4. Can be difficult to see distinctions at different zoom sizes. ]
                const unsigned int colourRepeatCycleSize = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize) * 2;
                bool repeatingPalette = ([_data length] > colourRepeatCycleSize);
                NSMutableArray *palette = [[NSMutableArray alloc] init];
                NSColorSpace *rgbSpace = [NSColorSpace sRGBColorSpace];
                for(int i = 0; i < [_data length]; i++) {
                    float percentageComplete = (float)i / (float)[_data length];
                    float hue = percentageComplete;
                    
                    if (repeatingPalette) hue = (float)i / (float)colourRepeatCycleSize;
                    if (repeatingPalette && hue > 1.0f) break;
                    
                    if (hue > 1.0f) hue = (float)hue - (int)hue;
                    NSColor *colour = [NSColor colorWithCalibratedHue:hue saturation:0.9f brightness:1.0f alpha:1.0f];
                    [colour colorUsingColorSpace:rgbSpace];
                    [palette addObject:colour];
                }
                
                for(int i = 0; i < [_data length]; i++) {
                    int paletteIndex = i;
                    if (repeatingPalette) paletteIndex = i % colourRepeatCycleSize;
                    _colourArray[(i * 3)] = [[palette objectAtIndex:paletteIndex] redComponent];
                    _colourArray[(i * 3) + 1] = [[palette objectAtIndex:paletteIndex] greenComponent];
                    _colourArray[(i * 3) + 2] = [[palette objectAtIndex:paletteIndex] blueComponent];
                }
                [palette release];
            }
            break;
    }
}

- (void) setDataSource:(NSData *)data {
    if ([data isEqualToData:_data]) return; // Don't re-set the data source if it's not necessary.
    
    [_data release];
    _data = nil;
    _data = [data retain];
    
    if (_vertexArray != nil) free(_vertexArray);
    _vertexArray = nil;
    _vertexArray = (float*)calloc(3 * [_data length], sizeof(float));
    if (_colourArray != nil) free(_vertexArray);
    _colourArray = nil;
    _colourArray = (float*)calloc(3 * [_data length], sizeof(float));
    
    glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
    glColorPointer(3, GL_FLOAT, 0, _colourArray);
    
    [self setCurveType:CurveViewTypeBlank];
    [self setCurveColourMode:CurveViewColourModeBlank];
}

- (void) redraw { [self drawRect:[self bounds]]; }

- (void) prepareOpenGL {
    // NSLog(@"Preparing...");
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
    glPointSize(_pointSize);
}

- (void) reshape {
    CGSize viewBounds = [self bounds].size;
    // NSLog(@"Reshape: %fw x %fh", viewBounds.width, viewBounds.height);
    
    // If a reshape operation isn't necessary, don't perform one.
    if (viewBounds.height == _viewBounds.height && viewBounds.width == _viewBounds.width) return;
    
    _viewBounds = viewBounds;
    glViewport(0, 0, _viewBounds.width, _viewBounds.height);
    glMatrixMode(GL_PROJECTION);
    glOrtho(0.0f, _viewBounds.width, _viewBounds.height, 0.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

-(void) drawRect: (NSRect) bounds
{
    // NSLog(@"Draw!");
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity();
    
    // Note: Would be nice if the user's scrolling preferences were used here.
    glTranslatef(0.0f, -_scrollPosition, 0.0f); // Translate by the distance scrolled.
    
    if (_type != CurveViewTypeBlank) { // Only draw if we're not in the blank curve mode
        
        // Draw only visible bytes (Hilbert makes this more difficult to calculate, so draw a bit extra both sides)
        GLsizei sqArea = (_viewBounds.width / _pointSize) * (_viewBounds.width / _pointSize),
             drawCount = (_viewBounds.height / _pointSize) * (_viewBounds.width / _pointSize) + sqArea,
        startDrawIndex = ((_scrollPosition / _pointSize) * (_viewBounds.width / _pointSize)) - sqArea / 2.0f;
        if (startDrawIndex < 0) startDrawIndex = 0;
        if ((startDrawIndex + drawCount) > [_data length]) drawCount = (GLsizei)[_data length] - startDrawIndex;
        
        glDrawArrays(GL_POINTS, startDrawIndex, drawCount);
    }
    glFlush();
}

- (void) scrollWheel: (NSEvent*) event {
    _scrollPosition -= [event deltaY] * 4.0f; // If time allows, setting scroll sensitivity in prefs. would be good.
    unsigned long minScrollPosition = 0,
                  maxScrollPosition = (unsigned long)(([_data length] / (_viewBounds.width / _pointSize)) + 1.0f) * _pointSize;
    if (maxScrollPosition >= _viewBounds.height / 4.0f) maxScrollPosition -= (_viewBounds.height / 4.0f);
    if (_scrollPosition < minScrollPosition) _scrollPosition = minScrollPosition;
    else if (_scrollPosition > maxScrollPosition) _scrollPosition = maxScrollPosition;
    
    [self redraw];
}

- (void) awakeFromNib {
    _data = nil;
    
    _pointSize = 4; // Should be a power of 2. Ideally in the form 2^(2n) - see Hilbert chunking code.
    _scrollPosition = 0.0f;
    [self setCurveType:CurveViewTypeBlank];
    [self setCurveColourMode:CurveViewColourModeBlank];
}

- (void) clearMemoryFingerprint {
    [_data release];
    _data = nil;
    _scrollPosition = 0.0f; // TODO: This probably doesn't belong in a method related to memory (rename this method?)
    
    if (_vertexArray != nil) free(_vertexArray);
    _vertexArray = nil;
    if (_colourArray != nil) free(_colourArray);
    _colourArray = nil;
}

- (void) dealloc {
    [self clearMemoryFingerprint];
    [super dealloc];
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited
// Note for highlighting: Can cache old colours in an (NS?) array and restore on deselection (and redraw, obviously)

@end
