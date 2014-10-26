//
//  CurveView.h
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CurveView : NSOpenGLView
{
    NSInteger _curveMode;
}

- (void) drawRect: (NSRect) bounds;
- (void) redraw;
- (void) setCurveModeBlank;
- (void) setCurveModeHilbert;
- (void) setCurveModeZigzag;

@end
