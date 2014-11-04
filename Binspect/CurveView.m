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
    _colourMode = mode;
    switch (_colourMode) {
        case CurveViewColourModeSimilarity:
            {
                // Similarity colour palette, generated through a Hilbert-order traversal of the RGB colour cube - more
                // specifically through the use of Aldo Cortesi's scurve swatch Python utility. This palette idea
                // itself was heavily inspired by the work of Cortesi.
                #include "ColourModeSimilarityPalette.c"
                
                const unsigned char *bytes = (const unsigned char*)[_data bytes];
                for(int i = 0; i < [_data length]; i++) {
                    _colourArray[(3 * i)] = palette[(3 * bytes[i])];
                    _colourArray[(3 * i) + 1] = palette[(3 * bytes[i]) + 1];
                    _colourArray[(3 * i) + 2] = palette[(3 * bytes[i]) + 2];
                }
            }
            break;
        case CurveViewColourModeEntropy:
            {
                // TODO: Clean up and properly comment this whole section
                unsigned long blocksize = 128;
                if ([_data length] < blocksize) blocksize = [_data length];
                
                long halfBlockSize = (blocksize / 2), previousStartIndex = 0;
                double logBlockSize = log(blocksize);
                
                unsigned long frequencies[256] = {0};
                double entropy = 0.0f;
                for(long i = 0; i < [_data length]; i++) {
                    const unsigned char *bytes = (const unsigned char*)[_data bytes];
                    long startIndex    = i - halfBlockSize;
                    
                    if (i < halfBlockSize) startIndex = 0;
                    else if (i > ([_data length] - 1 - halfBlockSize)) startIndex = [_data length] - 1 - halfBlockSize;
                    
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
        case CurveViewColourModeRandom:
            for(int i = 0; i < (3 * [_data length]); i++)
                _colourArray[i] = rand() / (float)RAND_MAX;
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
    if (_colourArray != nil) free(_colourArray);
    _colourArray = nil;
    _colourArray = (float*)calloc(3 * [_data length], sizeof(float));
    
    glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
    glColorPointer(3, GL_FLOAT, 0, _colourArray);
    
    
    [self setCurveType:CurveViewTypeBlank];
    [self setCurveColourMode:CurveViewColourModeBlank];
    [self setCurveType:_type];
    [self setCurveColourMode:_colourMode];
    [self redraw];
}

- (void) redraw { [self drawRect:[self bounds]]; }

- (void) prepareOpenGL {
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
    glPointSize(_pointSize);
}

- (void) reshape {
    CGSize viewBounds = [self bounds].size;
    
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
    
    // TODO: If time allows, zoom functionality is invaluable (more/less byte detail, bigger/smaller files, etc.)
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
