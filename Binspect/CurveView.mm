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
    _curveType = 0;
}

- (void) dealloc {
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    [super dealloc];
}

- (void) prepareOpenGL {
    // NSLog(@"Preparing...");
    glEnableClientState(GL_VERTEX_ARRAY);
    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
}

- (void) reshape {
    //NSLog(@"Reshape!");
    CGSize viewSize = [self bounds].size;
    
    NSScreen *screen = [NSScreen mainScreen];
    NSDictionary *description = [screen deviceDescription];
    NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
    CGSize displayPhysicalSize = CGDisplayScreenSize([[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);
    float pixelDensityFactor = (displayPixelSize.width / displayPhysicalSize.width) * 0.233;
    
    CGSize drawBounds;
    drawBounds.height = (int)(viewSize.height / pixelDensityFactor);
    drawBounds.width = (int)(viewSize.width / pixelDensityFactor);
    glPointSize(pixelDensityFactor);
    
    
    // If a reshape operation isn't necessary, don't perform one.
    if (drawBounds.height == _drawBounds.height && drawBounds.width == _drawBounds.width) return;
    
    _drawBounds = drawBounds;
    if (_vertexArray != nil) delete [] _vertexArray;
    _vertexArray = nil;
    _vertexArray = new float[3 * (int)_drawBounds.width * (int)_drawBounds.height];
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
    switch(_curveType) {
        case 0:
            break;
        case 1:
            glColor3f(1.0f, 0.0f, 0.0f);
            [self drawAnObject];
            break;
        case 2:
            glColor3f(0.0f, 1.0f, 0.0f);
            [self drawAnObject];
            break;
    }
    glFlush();
}

- (void) drawAnObject {
    _vertexArray[0] = _drawBounds.width / 4;
    _vertexArray[1] = _drawBounds.height / 4;
    _vertexArray[2] = 0.0f;
    _vertexArray[3] = _drawBounds.width / 2;
    _vertexArray[4] = _drawBounds.height / 2;
    _vertexArray[5] = 0.0f;
    _vertexArray[6] = (_drawBounds.width / 2) + (_drawBounds.width / 4);
    _vertexArray[7] = (_drawBounds.height / 2) + (_drawBounds.height / 4);
    _vertexArray[8] = 0.0f;
    glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
    glBegin(GL_POINTS);
    {
        glArrayElement(0);
        glArrayElement(1);
        glArrayElement(2);
    }
    glEnd();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited

@end
