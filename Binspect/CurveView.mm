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

- (void) setCurveType:(CurveViewType)type { _type = type; }
- (void) setCurveColourMode:(CurveViewColourMode)mode {
    if (mode == _colourMode) return; // Don't re-set the colour mode if it's not necessary.
    
    _colourMode = mode;
    switch (_colourMode) {
        case CurveViewColourModeEntropy:
            break;
        case CurveViewColourModeSimilarity:
            break;
        case CurveViewColourModeStructural:
            break;
        default:
            break;
    }
    
    for(int i = 0; i < (3 * [_data length]); i++)
        _colourArray[i] = rand() / (float)RAND_MAX;
}

// TODO: Clean up this mess. Including all the casting, and maybe the raw memory management.
// TODO: This doesn't seem to always draw right to the edge of the view as e.g. points at (0, y) are half drawn off-screen
//       (Same with (x, 0) [sometimes offscreen]. Need to be drawn with an offset of pointsize / 2. Could use a transformation?
- (void) setDataSource:(NSData *)data {
    if ([data isEqualToData:_data]) return; // Don't re-set the data source if it's not necessary.
    
    [_data release];
    _data = nil;
    _data = [data retain];
    
    // TODO: Could possibly move from C++-style arrays and alloc to NSArray and point to the C-style internals if it's memory efficient.
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    _vertexArray = new float[3 * [_data length]];
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
    _colourArray = new float[3 * [_data length]];
    
    for(int i = 0; i < [_data length]; i++) {
        _vertexArray[(3 * i)]     = i % (int)_drawBounds.width;
        _vertexArray[(3 * i) + 1] = (int)(i / _drawBounds.width);
        _vertexArray[(3 * i) + 2] = 0.0f;
    }
    
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
}

- (void) reshape {
    //NSLog(@"Reshape!");
    CGSize viewSize = [self bounds].size;
    int pixelScaleFactor = 2;
    
    CGSize drawBounds;
    drawBounds.height = (int)(viewSize.height / pixelScaleFactor);
    drawBounds.width = (int)(viewSize.width / pixelScaleFactor);
    glPointSize(pixelScaleFactor);
    
    // If a reshape operation isn't necessary, don't perform one.
    if (drawBounds.height == _drawBounds.height && drawBounds.width == _drawBounds.width) return;
    
    _drawBounds = drawBounds;
    
    glViewport(0, 0, (int)viewSize.width, (int)viewSize.height);
    glMatrixMode(GL_PROJECTION);
    glOrtho(0.0f, _drawBounds.width, _drawBounds.height, 0.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(0.5f, 1.0f, 0.0f); // Transform GL_POINTS wholly into the view
}

-(void) drawRect: (NSRect) bounds
{
    // NSLog(@"Draw!");
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_type != CurveViewTypeBlank) glDrawArrays(GL_POINTS, 0, (GLsizei)[_data length]);
    glFlush();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

- (void) awakeFromNib {
    _data = nil;
    [self setCurveType:CurveViewTypeBlank];
    [self setCurveColourMode:CurveViewColourModeBlank];
}

- (void) dealloc {
    [_data release];
    _data = nil;
    
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
    
    [super dealloc];
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited

@end
