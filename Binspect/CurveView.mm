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

- (void) redraw { [self drawRect:[self bounds]]; }

- (void) setCurveTypeBlank { _curveType = 0; }
- (void) setCurveTypeHilbert { _curveType = 1; }
- (void) setCurveTypeZigzag { _curveType = 2; }
- (void) setCurveColourModeBlank { _curveColourMode = 0; }
- (void) setCurveColourModeSimilarity { _curveColourMode = 1; }
- (void) setCurveColourModeEntropy { _curveColourMode = 2; }
- (void) setCurveColourModeStructural { _curveColourMode = 3; }

- (void) awakeFromNib {
    [self setCurveTypeBlank];
}

- (void) dealloc {
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
    [super dealloc];
}

- (void) prepareOpenGL {
    // NSLog(@"Preparing...");
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
}

- (void) reshape {
    //NSLog(@"Reshape!");
    CGSize viewSize = [self bounds].size;
    
    NSScreen *screen = [NSScreen mainScreen];
    NSDictionary *description = [screen deviceDescription];
    NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
    CGSize displayPhysicalSize = CGDisplayScreenSize([[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);
    int pixelDensityFactor = (int)(((displayPixelSize.width / displayPhysicalSize.width) * 0.233) + 0.5f);
    
    CGSize drawBounds;
    drawBounds.height = (int)(viewSize.height / pixelDensityFactor);
    drawBounds.width = (int)(viewSize.width / pixelDensityFactor);
    glPointSize(pixelDensityFactor);
    
    // If a reshape operation isn't necessary, don't perform one.
    if (drawBounds.height == _drawBounds.height && drawBounds.width == _drawBounds.width) return;
    
    _drawBounds = drawBounds;
    
    // TODO: The size of these should be based on data size alone (and should only change on a data or algorithm change).
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    _vertexArray = new float[3 * (int)_drawBounds.width * (int)_drawBounds.height];
    if (_colourArray != nil) delete [] _colourArray;
    _colourArray = nil;
    _colourArray = new float[3 * (int)_drawBounds.width * (int)_drawBounds.height];
    
    for(int i = 0; i < _drawBounds.height; i++) {
        for(int j = 0; j < _drawBounds.width; j++) {
            _vertexArray[3 * (int)(_drawBounds.width * i + j)] = j;
            _vertexArray[3 * (int)(_drawBounds.width * i + j) + 1] = i;
            _vertexArray[3 * (int)(_drawBounds.width * i + j) + 2] = 0.0f;
        }
    }
    for(int i = 0; i < (3 * _drawBounds.width * _drawBounds.height); i++)
        _colourArray[i] = rand() / (float)RAND_MAX;
    glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
    glColorPointer(3, GL_FLOAT, 0, _colourArray);
    
    glViewport(0, 0, (int)viewSize.width, (int)viewSize.height);
    glMatrixMode(GL_PROJECTION);
    glOrtho(0.0f, _drawBounds.width, 0.0f, _drawBounds.height, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

-(void) drawRect: (NSRect) bounds
{
    // NSLog(@"Draw!");
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity();
    if (_curveType != 0) glDrawArrays(GL_POINTS, 0, _drawBounds.width * _drawBounds.height);
    glFlush();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited

@end
