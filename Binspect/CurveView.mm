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

+ (unsigned int) getHilbertCurveIndex:(unsigned int)size forCoords:(CGPoint)point {
    CGPoint rotation;
    unsigned int result = 0;
    int temporarySize;
    for (temporarySize = size / 2; temporarySize > 0; temporarySize /= 2) {
        rotation.x = ((int)point.x & temporarySize) > 0;
        rotation.y = ((int)point.y & temporarySize) > 0;
        result += temporarySize * temporarySize * ((3 * (int)rotation.x) ^ (int)rotation.y);
        [CurveView rotateHilbertCurveQuadrant:temporarySize by:rotation forPoint:&point];
    }
    
    return result;
}

+ (CGPoint) getHilbertCurveCoordinates:(unsigned int)size forIndex:(unsigned int)index {
    CGPoint rotation, result = CGPointMake(0, 0);
    int temporarySize, temporaryIndex = index;
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

+ (void) rotateHilbertCurveQuadrant:(unsigned int)size by:(CGPoint)rotation forPoint:(CGPoint *)point {
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
        case CurveViewTypeHilbert: // TODO: Clean up some of the casting here.
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
                
                // Spit the curve into 128-size segments, and stack those on top of eachother.
                unsigned long chunkWidth = nearestPowerOfTwo,
                             chunks    = 1,
                             maxWidth  = _viewBounds.width / _pointSize;
                if (nearestPowerOfTwo > maxWidth) {
                    chunkWidth = maxWidth;
                    chunks = (unsigned long)(((float)[_data length] / (float)(maxWidth * maxWidth)) + 1.0f);
                }
                
                // A _pointSize of 4 works particularly well for this, as it produces a 'chunkWidth' of size 128.
                // Due to the nature of the Hilbert curve, this means that the curves finish in the bottom left,
                // and so tile excellently with (and have proper locality with) the next chunk.
                
                // In fact, if the _pointSize is not 4 then chunking makes the visualisation somewhat ugly.
                // I wouldn't recommend using this chunking method (and instead enabling horizontal scrolling
                // of a square curve) for _pointSize values which are not 4.
                for(int chunk = 0; chunk < chunks; chunk++) {
                    unsigned long currentChunkArea = chunkWidth * chunkWidth,
                                  lastPointCovered = chunkWidth * chunkWidth * chunk;
                    if (chunk + 1 == chunks) currentChunkArea = [_data length] - lastPointCovered;
                    for(unsigned long i = 0; i < currentChunkArea; i++) {
                        unsigned long index = lastPointCovered + i;
                        CGPoint point = [CurveView getHilbertCurveCoordinates:(unsigned int)(chunkWidth * chunkWidth) forIndex:(int)i];
                        
                        point.x = (point.x * _pointSize) + (_pointSize / 2.0f);
                        point.y = (point.y * _pointSize) + (_pointSize / 2.0f);
                        
                        // Assign the (x, y, z) co-ordinates for this point in the vertex array
                        _vertexArray[(3 * index)]     = point.x;
                        _vertexArray[(3 * index) + 1] = point.y + (chunk * chunkWidth * _pointSize);
                        _vertexArray[(3 * index) + 2] = 0.0f;
                    }
                }
                
                
                // TODO: Unroll the curve so it fits into a rectangular pattern (vertical scrolling only, 512( / _pointSize) width)
                
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
            for(int i = 0; i < (3 * [_data length]); i++)
                _colourArray[i] = rand() / (float)RAND_MAX;
            break;
        case CurveViewColourModeEntropy:
            break;
        case CurveViewColourModeStructural:
            // To consider: Having the cycle never repeat is useful for some purposes (namely, seeing raw files offsets)
            const unsigned int colourRepeatCycleSize = 128 * 128 * 2; // If time permits, the 2 here can be modified in user prefs.
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
            break;
    }
}

- (void) setDataSource:(NSData *)data {
    if ([data isEqualToData:_data]) return; // Don't re-set the data source if it's not necessary.
    
    [_data release];
    _data = nil;
    _data = [data retain];
    
    // TODO: Move away from C++ style memory allocation.
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    _vertexArray = new float[3 * [_data length]];
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
    _colourArray = new float[3 * [_data length]];
    
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
    
    // TODO: Don't draw points that aren't on screen.
    if (_type != CurveViewTypeBlank) glDrawArrays(GL_POINTS, 0, (GLsizei)[_data length]); // GL_LINE_STRIP for curve debugging
    glFlush();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

- (void) awakeFromNib {
    _data = nil;
    
    _pointSize = 4; // Should be a power of 2. Ideally 4 (see Hilbert chunking code).
    [self setCurveType:CurveViewTypeBlank];
    [self setCurveColourMode:CurveViewColourModeBlank];
}

- (void) clearMemoryFingerprint {
    [_data release];
    _data = nil;
    
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
}

- (void) dealloc {
    [self clearMemoryFingerprint];
    [super dealloc];
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited
// Note for highlighting: Can cache old colours in an (NS?) array and restore on deselection (and redraw, obviously)

@end
