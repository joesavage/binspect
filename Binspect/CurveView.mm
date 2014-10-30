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

- (void) setCurveType:(CurveViewType)type {
    _type = type;
    switch(_type) {
        case CurveViewTypeHilbert:
            break;
        case CurveViewTypeZigzag:
            break;
    }
    
    // _vertexArray and _colourArray should be indexed the same as _data (for sequential drawing, indexed access, etc.)
    for(int i = 0; i < [_data length]; i++) {
        float halfPointSize = (_pointSize / 2.0f);
        unsigned long rowNumber = (i * _pointSize) / (int)_viewBounds.width;
        
        // Assign the (x, y, z) co-ordinates for this point in the vertex array
        _vertexArray[(3 * i)]     = ((i * _pointSize) % (int)_viewBounds.width) + halfPointSize;
        _vertexArray[(3 * i) + 1] = (rowNumber * _pointSize) + halfPointSize;
        _vertexArray[(3 * i) + 2] = 0.0f;
    }
}
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
    if (_type != CurveViewTypeBlank) glDrawArrays(GL_POINTS, 0, (GLsizei)[_data length]);
    glFlush();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

- (void) awakeFromNib {
    _data = nil;
    _pointSize = 3;
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
