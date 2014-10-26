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

- (void) setCurveModeBlank { _curveMode = 0; }
- (void) setCurveModeHilbert { _curveMode = 1; }
- (void) setCurveModeZigzag { _curveMode = 2; }

- (void) awakeFromNib {
    _curveMode = 0;
    [self drawRect:[self bounds]];
}

- (void) prepareOpenGL {
    // NSLog(@"Preparing...");
}

-(void) drawRect: (NSRect) bounds
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    if (_curveMode != 0) [CurveView drawAnObject];
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
