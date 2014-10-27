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
    NSInteger _curveType, _curveColourMode;
    CGSize    _drawBounds;
    float     *_vertexArray;
}

- (void) drawRect: (NSRect) bounds;
- (void) redraw;

- (void) setCurveTypeBlank;
- (void) setCurveTypeHilbert;
- (void) setCurveTypeZigzag;
- (void) setCurveColourModeBlank;
- (void) setCurveColourModeSimilarity;
- (void) setCurveColourModeEntropy;
- (void) setCurveColourModeStructural;


@end
