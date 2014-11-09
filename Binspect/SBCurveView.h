//
//  SBCurveView.h
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, SBCurveViewType) {
	SBCurveViewTypeBlank,
	SBCurveViewTypeHilbert,
	SBCurveViewTypeZigzag
};

typedef NS_ENUM(NSUInteger, SBCurveViewColourMode) {
	SBCurveViewColourModeBlank,
	SBCurveViewColourModeSimilarity,
	SBCurveViewColourModeEntropy,
	SBCurveViewColourModeStructural,
	SBCurveViewColourModeRandom
};

@protocol SBCurveViewDelegate <NSObject>
- (void) curveViewMouseMovedToInvalidIndex;
- (void) curveViewMouseMovedToIndex:(NSInteger)index;
@end

@interface SBCurveView : NSOpenGLView
{
	         CGSize                  _viewBounds;
	         CGPoint                 _mousePosition;
	         float                   *_vertexArray, *_colourArray;
	         NSData                  *_data;
	         NSInteger               _type, _colourMode, _pointSize;
	         float                   _scrollPosition;
	IBOutlet id<SBCurveViewDelegate> _delegate;
}

- (void) awakeFromNib;
- (void) dealloc;

+ (NSUInteger) getHilbertCurveIndex:(NSUInteger)size forCoords:(CGPoint)point;
+ (CGPoint) getHilbertCurveCoordinates:(NSUInteger)size forIndex:(NSUInteger)index;
+ (void) rotateHilbertCurveQuadrant:(NSUInteger)size by:(CGPoint)rotation forPoint:(CGPoint *)point;
+ (NSUInteger) getZigzagCurveIndex:(NSUInteger)width forCoords:(CGPoint)point;
+ (CGPoint) getZigzagCurveCoordinates:(NSUInteger)width forIndex:(NSUInteger)index;

- (NSUInteger) calculateHilbertChunkWidth:(NSUInteger)maxWidth;
- (NSUInteger) getIndexOfCurrentlyHoveredByte;
- (void) setCurveType:(SBCurveViewType)type;
- (void) setCurveColourMode:(SBCurveViewColourMode)mode;
- (void) setDataSource:(NSData *)data;
- (void) prepareOpenGL;
- (void) reshape;
- (void) redraw;
- (void) drawRect: (NSRect)boun;
- (void) setScrollPosition:(float)position;
- (void) scrollWheel:(NSEvent *)event;
- (BOOL) isValidZoomLevel:(NSInteger)zoomLevel;
- (void) setZoomLevel:(NSInteger)zoomLevel;
- (void) mouseExited:(NSEvent *)event;
- (void) mouseMoved:(NSEvent *)event;
- (void) clearState;

@end
