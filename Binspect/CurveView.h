//
//  CurveView.h
//  Binspect
//
//  Created by Joe Savage on 26/10/2014.
//  Copyright (c) 2014 Joe Savage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CurveViewType) {
	CurveViewTypeBlank,
	CurveViewTypeHilbert,
	CurveViewTypeZigzag
};

typedef NS_ENUM(NSInteger, CurveViewColourMode) {
	CurveViewColourModeBlank,
	CurveViewColourModeSimilarity,
	CurveViewColourModeEntropy,
	CurveViewColourModeStructural,
	CurveViewColourModeRandom
};

@protocol CurveViewDelegate <NSObject>
- (void) curveViewMouseMovedToInvalidIndex;
- (void) curveViewMouseMovedToIndex:(NSInteger)index;
@end

@interface CurveView : NSOpenGLView
{
	         CGSize                _viewBounds;
	         CGPoint               _mousePosition;
	         float                 *_vertexArray, *_colourArray;
	         NSData                *_data;
	         NSInteger             _type, _colourMode, _pointSize;
	         float                 _scrollPosition;
	IBOutlet id<CurveViewDelegate> _delegate;
}

// TODO: Update the method prototypes shown here. Like, seriously - do it.
- (void) setCurveType:(CurveViewType)type;
- (void) setCurveColourMode:(CurveViewColourMode)mode;
- (void) setScrollPosition:(float)position;
- (BOOL) isValidZoomLevel:(NSInteger)zoomLevel;
- (void) setZoomLevel:(NSInteger)zoomLevel;
- (void) setDataSource:(NSData *)data;
- (void) drawRect:(NSRect)bounds;
- (void) redraw;
- (void) clearState;
- (unsigned long) getIndexOfCurrentlyHoveredByte;

@end
