//
//  SBCurveView.h
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, SBCurveViewType) {
	SBCurveViewTypeBlank,
	SBCurveViewTypeHilbert,
	SBCurveViewTypeZigzag
};

typedef NS_ENUM(NSInteger, SBCurveViewColourMode) {
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

// TODO: Update the method prototypes shown here. Like, seriously - do it.
- (void) setCurveType:(SBCurveViewType)type;
- (void) setCurveColourMode:(SBCurveViewColourMode)mode;
- (void) setScrollPosition:(float)position;
- (BOOL) isValidZoomLevel:(NSInteger)zoomLevel;
- (void) setZoomLevel:(NSInteger)zoomLevel;
- (void) setDataSource:(NSData *)data;
- (void) drawRect:(NSRect)bounds;
- (void) redraw;
- (void) clearState;
- (unsigned long) getIndexOfCurrentlyHoveredByte;

@end
