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
    [self drawRect:[self bounds]];
}

- (void) prepareOpenGL {
    // NSLog(@"Preparing...");
}

-(void) drawRect: (NSRect) bounds
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    if (_curveType != 0) [CurveView drawAnObject];
    glFlush();
}

+ (void) drawAnObject {
    glColor3f(1.0f, 0.85f, 0.35f);
    glBegin(GL_TRIANGLES);
    {
        glVertex3f(  0.0,  0.6, 0.0);
        glVertex3f( -0.2, -0.3, 0.0);
        glVertex3f(  0.2, -0.3 ,0.0);
    }
    glEnd();
}

- (void) scrollWheel: (NSEvent*) event {
    // NSLog(@"Scroll!");
}

// For mouse hovering in future: updateTrackingAreas, mouseEntered, mouseExited

@end
