//
//  JCTiledScrollView.m
//  
//  Created by Jesse Collis on 1/2/2012.
//  Copyright (c) 2012, Jesse Collis JC Multimedia Design. <jesse@jcmultimedia.com.au>
//  All rights reserved.
//
//  * Redistribution and use in source and binary forms, with or without 
//   modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright 
//   notice, this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright 
//   notice, this list of conditions and the following disclaimer in the 
//   documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY 
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
//

#import "JCTiledScrollView.h"
#import "JCTiledView.h"
#import "RMMapLayer.h"
#import "RMMapOverlayView.h"

//#define kZoomRectPixelBuffer 150.0
#define kZoomRectPixelBuffer 10.0

@interface JCTiledScrollView () <JCTiledBitmapViewDelegate>
@property (nonatomic, retain) UIView *canvasView;
- (void)createMapView;
- (void)correctPositionOfAllAnnotations;
- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllLayers wasZoom:(BOOL)wasZoom;
@end



@implementation JCTiledScrollView
{
  
  BOOL _delegateHasTiledScrollViewDidZoom;
  BOOL _delegateHasTiledScrollViewWillZoom;
  BOOL _delegateHasTiledScrollViewWillScroll;
  BOOL _delegateHasTiledScrollViewDidScroll;
  BOOL _delegateHasBeforeMapMove;
  //BOOL _delegateHasAfterMapMove;
  BOOL _delegateHasScrollViewRegionDidChange;
  BOOL _delegateHasDoubleTapOnScrollView;
  BOOL _delegateHasDoubleTapTwoFingersOnScrollView;
  BOOL _delegateHasSingleTapOnScrollView;
  BOOL _delegateHasSingleTapTwoFingersOnScrollView;
  BOOL _delegateHasLongSingleTapOnScrollView;
  BOOL _delegateHasTapOnAnnotation;
  BOOL _delegateHasDoubleTapOnAnnotation;
  BOOL _delegateHasTapOnLabelForAnnotation;
  BOOL _delegateHasDoubleTapOnLabelForAnnotation;
  BOOL _delegateHasShouldDragMarker;
  BOOL _delegateHasDidDragMarker;
  BOOL _delegateHasDidEndDragMarker;
  
  BOOL _delegateHasLayerForAnnotation;
  BOOL _delegateHasWillHideLayerForAnnotation;
  BOOL _delegateHasDidHideLayerForAnnotation;
  
  BOOL _constrainMovement;
  
  float _lastZoom;
  CGPoint _lastContentOffset, _accumulatedDelta;
  BOOL _mapScrollViewIsZooming;
}
@synthesize tiledScrollViewDelegate = _tiledScrollViewDelegate;
@synthesize levelsOfZoom = _levelsOfZoom;
@synthesize levelsOfDetail = _levelsOfDetail;
@synthesize tiledView = _tiledView;
@synthesize canvasView = _canvasView;
@synthesize dataSource = _dataSource;
@synthesize scrollView = _scrollView;


+ (Class)tiledLayerClass
{
  return [JCTiledView class];
}

- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize
{
  if ((self = [super initWithFrame:frame]))
  {
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    
    self.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    _scrollView.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);  
    self.levelsOfZoom = 2;
    _scrollView.minimumZoomScale = 0.5;
    _scrollView.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    _scrollView.contentSize = contentSize;
    _scrollView.bouncesZoom = YES;
    _scrollView.bounces = YES;
    
    CGRect canvas_frame = CGRectMake(0., 0., _scrollView.contentSize.width, _scrollView.contentSize.height);
    _canvasView = [[UIView alloc] initWithFrame:canvas_frame];
    
    self.tiledView = [[[[[self class] tiledLayerClass] alloc] initWithFrame:canvas_frame] autorelease];
    self.tiledView.delegate = self;
    
    [self.canvasView addSubview:self.tiledView];
    
    [_scrollView addSubview:self.canvasView];
    [self addSubview:_scrollView];
    
    //From RMMapView
    zoom = log2f(self.zoomScale);
    _lastZoom = zoom;
    
    _constrainMovement = NO;
    _mapScrollViewIsZooming = NO;
    _accumulatedDelta = CGPointMake(0.0, 0.0);
    annotations = [NSMutableSet new];
    visibleAnnotations = [NSMutableSet new];
    overlayView = nil;
    [self createMapView];
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];    
    
  }
  
  return self;
}

-(void)createMapView{
  [overlayView removeFromSuperview]; [overlayView release]; overlayView = nil;
  [visibleAnnotations removeAllObjects];
  
  //[tiledLayerView removeFromSuperview]; [tiledLayerView release]; tiledLayerView = nil;
  
  //[mapScrollView removeObserver:self forKeyPath:@"contentOffset"];
  //[mapScrollView removeFromSuperview]; [mapScrollView release]; mapScrollView = nil;
  
  //_mapScrollViewIsZooming = NO;
  
  //int tileSideLength = [[self tileSource] tileSideLength];
  //CGSize contentSize = CGSizeMake(tileSideLength, tileSideLength); // zoom level 1
  
  //mapScrollView = [[UIScrollView alloc] initWithFrame:[self bounds]];
  //mapScrollView.delegate = self;
  //mapScrollView.opaque = NO;
  //mapScrollView.backgroundColor = [UIColor clearColor];
  //mapScrollView.showsVerticalScrollIndicator = NO;
  //mapScrollView.showsHorizontalScrollIndicator = NO;
  //mapScrollView.scrollsToTop = NO;
  //mapScrollView.contentSize = contentSize;
  //mapScrollView.minimumZoomScale = exp2f([self minZoom]);
  //mapScrollView.maximumZoomScale = exp2f([self maxZoom]);
  //mapScrollView.contentOffset = CGPointMake(0.0, 0.0);
  
  //tiledLayerView = [[RMMapTiledLayerView alloc] initWithFrame:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) mapView:self];
  //tiledLayerView.delegate = self;
  
  //if (self.adjustTilesForRetinaDisplay && screenScale > 1.0)
  //{
  //RMLog(@"adjustTiles");
  //((CATiledLayer *)tiledLayerView.layer).tileSize = CGSizeMake(tileSideLength * 2.0, tileSideLength * 2.0);
  //}
  //else
  //{
  //((CATiledLayer *)tiledLayerView.layer).tileSize = CGSizeMake(tileSideLength, tileSideLength);
  //}
  
  //[mapScrollView addSubview:tiledLayerView];
  
  //[mapScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
  //[mapScrollView setZoomScale:exp2f([self zoom]) animated:NO];
  
  //_lastZoom = [self zoom];
  //_lastContentOffset = mapScrollView.contentOffset;
  //_accumulatedDelta = CGPointMake(0.0, 0.0);
  
  //if (backgroundView)
  //[self insertSubview:mapScrollView aboveSubview:backgroundView];
  //else
  //[self insertSubview:mapScrollView atIndex:0];
  
  overlayView = [[RMMapOverlayView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
  overlayView.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth); 
  //overlayView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
  overlayView.delegate = self;
  
  [self insertSubview:overlayView aboveSubview:_scrollView];
}

-(void)dealloc
{	
  
  [_tiledView release];
  _tiledView = nil;
  
  [_canvasView release];
  _canvasView = nil;
  
  [_scrollView removeObserver:self forKeyPath:@"contentOffset" ];   
  [_scrollView release];
  _scrollView = nil;
  
  [annotations release]; annotations = nil;
  [visibleAnnotations release]; visibleAnnotations = nil;    
  [overlayView release]; overlayView = nil;
  
  [super dealloc];
}

- (void)setTiledScrollViewDelegate:(id<JCTiledScrollViewDelegate>)tiledScrollViewDelegate{
  _tiledScrollViewDelegate = tiledScrollViewDelegate;
  
  
  _delegateHasTiledScrollViewWillZoom = [_tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewWillZoom:)];
  _delegateHasTiledScrollViewDidZoom = [_tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewDidZoom:)];
  
  _delegateHasTiledScrollViewWillScroll = [_tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewWillScroll:)];
  _delegateHasTiledScrollViewDidScroll = [_tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewDidScroll:)];
  
  _delegateHasDoubleTapOnScrollView = [_tiledScrollViewDelegate respondsToSelector:@selector(doubleTapOnScrollView:at:)];
  _delegateHasDoubleTapTwoFingersOnScrollView = [_tiledScrollViewDelegate respondsToSelector:@selector(doubleTapTwoFingersOnScrollView:at:)];
  _delegateHasSingleTapOnScrollView = [_tiledScrollViewDelegate respondsToSelector:@selector(singleTapOnScrollView:at:)];
  _delegateHasSingleTapTwoFingersOnScrollView = [_tiledScrollViewDelegate respondsToSelector:@selector(singleTapOnScrollView:at:)];
  _delegateHasLongSingleTapOnScrollView = [_tiledScrollViewDelegate respondsToSelector:@selector(longSingleTapOnScrollView:at:)];
  
  _delegateHasLayerForAnnotation = [_tiledScrollViewDelegate respondsToSelector:@selector(scrollView:layerForAnnotation:)];
  _delegateHasWillHideLayerForAnnotation = [_tiledScrollViewDelegate respondsToSelector:@selector(scrollView:willHideLayerForAnnotation:)];
  _delegateHasDidHideLayerForAnnotation = [_tiledScrollViewDelegate respondsToSelector:@selector(scrollView:didHideLayerForAnnotation:)];
  
  _delegateHasScrollViewRegionDidChange = [_tiledScrollViewDelegate respondsToSelector:@selector(scrollViewRegionDidChange:)];
  
}


#pragma mark - zoom
- (float)zoom
{
  return zoom;
}

//if #zoom is outside of range #minZoom to #maxZoom, zoom level is clamped to that range.
- (void)setZoom:(float)newZoom
{
  zoom = (newZoom > self.levelsOfZoom) ? self.levelsOfZoom : newZoom;
  zoom = (zoom < log2f(_scrollView.minimumZoomScale)) ? log2f(_scrollView.minimumZoomScale) : zoom;
  
  NSLog(@"New zoom:%f", zoom);
  _scrollView.zoomScale = exp2f(zoom);
}

- (float)nextNativeZoomFactor
{
  float newZoom = fminf(floorf([self zoom] + 1.0), self.levelsOfZoom);
  
  return exp2f(newZoom - [self zoom]);
}

- (float)previousNativeZoomFactor
{
  float newZoom = fmaxf(floorf([self zoom] - 1.0), log2f(_scrollView.minimumZoomScale));
  
  return exp2f(newZoom - [self zoom]);
}

- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot
{
  [self zoomInToNextNativeZoomAt:pivot animated:NO];
}
//
- (void)zoomInToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL)animated
{
  // Calculate rounded zoom
  float newZoom = fmin(ceilf([self zoom]) + 0.99, self.levelsOfZoom);
  
  if (newZoom == self.zoom)
    return;
  
  float factor = exp2f(newZoom - [self zoom]);
  
  if (factor > 2.25)
  {
    newZoom = fmin(ceilf([self zoom]) - 0.01, self.levelsOfZoom);
    factor = exp2f(newZoom - [self zoom]);
  }
  
  //    RMLog(@"zoom in from:%f to:%f by factor:%f around {%f,%f}", [self zoom], newZoom, factor, pivot.x, pivot.y);
  [self zoomContentByFactor:factor near:pivot animated:animated];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot
{
  [self zoomOutToNextNativeZoomAt:pivot animated:NO];
}

- (void)zoomOutToNextNativeZoomAt:(CGPoint)pivot animated:(BOOL) animated
{
  // Calculate rounded zoom
  float newZoom = fmax(floorf([self zoom]) - 0.01, log2f(_scrollView.minimumZoomScale));
  
  if (newZoom == self.zoom)
    return;
  
  float factor = exp2f(newZoom - [self zoom]);
  
  if (factor > 0.75)
  {
    newZoom = fmax(floorf([self zoom]) - 1.01, log2f(_scrollView.minimumZoomScale));
    factor = exp2f(newZoom - [self zoom]);
  }
  
  //    RMLog(@"zoom out from:%f to:%f by factor:%f around {%f,%f}", [self zoom], newZoom, factor, pivot.x, pivot.y);
  [self zoomContentByFactor:factor near:pivot animated:animated];
}


- (void)zoomContentByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated
{
  //if (![self tileSourceBoundsContainScreenPoint:pivot])
  //return;
  
  //zoomFactor = [self adjustedZoomForCurrentBoundingMask:zoomFactor];
  float zoomDelta = log2f(zoomFactor);
  float targetZoom = zoomDelta + [self zoom];
  
  if (targetZoom == [self zoom])
    return;
  
  // clamp zoom to remain below or equal to maxZoom after zoomAfter will be applied
  // Set targetZoom to maxZoom so the map zooms to its maximum
  if (targetZoom > [self levelsOfZoom])
  {
    zoomFactor = exp2f([self levelsOfZoom] - [self zoom]);
    targetZoom = [self levelsOfZoom];
  }
  
  // clamp zoom to remain above or equal to minZoom after zoomAfter will be applied
  // Set targetZoom to minZoom so the map zooms to its maximum
  if (targetZoom < log2f(_scrollView.minimumZoomScale))
  {
    zoomFactor = 1/exp2f([self zoom] - log2f(_scrollView.minimumZoomScale));
    targetZoom = log2f(_scrollView.minimumZoomScale);
  }
  
  if ([self shouldZoomToTargetZoom:targetZoom withZoomFactor:zoomFactor])
  {
    float zoomScale = _scrollView.zoomScale;
    CGSize newZoomSize = CGSizeMake(_scrollView.bounds.size.width / zoomFactor,
                                    _scrollView.bounds.size.height / zoomFactor);
    CGFloat factorX = pivot.x / _scrollView.bounds.size.width,
    factorY = pivot.y / _scrollView.bounds.size.height;
    CGRect zoomRect = CGRectMake(((_scrollView.contentOffset.x + pivot.x) - (newZoomSize.width * factorX)) / zoomScale,
                                 ((_scrollView.contentOffset.y + pivot.y) - (newZoomSize.height * factorY)) / zoomScale,
                                 newZoomSize.width / zoomScale,
                                 newZoomSize.height / zoomScale);
    [_scrollView zoomToRect:zoomRect animated:animated];
  }
  else
  {
    if ([self zoom] > [self levelsOfZoom])
      [self setZoom:[self levelsOfZoom]];
    if ([self zoom] < log2f(_scrollView.minimumZoomScale))
      [self setZoom:log2f(_scrollView.minimumZoomScale)];
  }
}

- (BOOL)shouldZoomToTargetZoom:(float)targetZoom withZoomFactor:(float)zoomFactor
{
  // bools for syntactical sugar to understand the logic in the if statement below
  BOOL zoomAtMax = ([self zoom] == [self levelsOfZoom]);
  BOOL zoomAtMin = ([self zoom] == log2f(_scrollView.minimumZoomScale));
  BOOL zoomGreaterMin = ([self zoom] > log2f(_scrollView.minimumZoomScale));
  BOOL zoomLessMax = ([self zoom] < [self levelsOfZoom]);
  
  //zooming in zoomFactor > 1
  //zooming out zoomFactor < 1
  if ((zoomGreaterMin && zoomLessMax) || (zoomAtMax && zoomFactor<1) || (zoomAtMin && zoomFactor>1))
    return YES;
  else
    return NO;
}

//- (float)adjustedZoomForCurrentBoundingMask:(float)zoomFactor
//{
//  if (boundingMask == RMMapNoMinBound)
//    return zoomFactor;
//  
//  double newMetersPerPixel = self.metersPerPixel / zoomFactor;
//  
//  RMProjectedRect mercatorBounds = [projection planetBounds];
//  
//  // Check for MinWidthBound
//  if (boundingMask & RMMapMinWidthBound)
//  {
//    double newMapContentsWidth = mercatorBounds.size.width / newMetersPerPixel;
//    double screenBoundsWidth = [self bounds].size.width;
//    double mapContentWidth;
//    
//    if (newMapContentsWidth < screenBoundsWidth)
//    {
//      // Calculate new zoom facter so that it does not shrink the map any further.
//      mapContentWidth = mercatorBounds.size.width / self.metersPerPixel;
//      zoomFactor = screenBoundsWidth / mapContentWidth;
//    }
//  }
//  
//  // Check for MinHeightBound
//  if (boundingMask & RMMapMinHeightBound)
//  {
//    double newMapContentsHeight = mercatorBounds.size.height / newMetersPerPixel;
//    double screenBoundsHeight = [self bounds].size.height;
//    double mapContentHeight;
//    
//    if (newMapContentsHeight < screenBoundsHeight)
//    {
//      // Calculate new zoom facter so that it does not shrink the map any further.
//      mapContentHeight = mercatorBounds.size.height / self.metersPerPixel;
//      zoomFactor = screenBoundsHeight / mapContentHeight;
//    }
//  }
//  
//  return zoomFactor;
//}



#pragma mark - UIScrolViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.canvasView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
  if (_delegateHasTiledScrollViewDidZoom)
  {
    [self.tiledScrollViewDelegate tiledScrollViewDidZoom:self];
  }
  [self correctPositionOfAllAnnotations];
  
  //if (_delegateHasAfterMapZoom) [delegate afterMapZoom:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if(_delegateHasTiledScrollViewDidScroll)
  {
    [self.tiledScrollViewDelegate tiledScrollViewDidScroll:self];
  }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
  _mapScrollViewIsZooming = YES;
  
  //if (_delegateHasBeforeMapZoom)[delegate beforeMapZoom:self];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
  _mapScrollViewIsZooming = NO;
  
  [self correctPositionOfAllAnnotations];
}



#pragma mark - JCTiledView delegate
-(UIView*)referenceViewForCoordinates{
  return self;
}


-(void)tiledView:(JCTiledView *)aTiledView singleTapAtPoint:(CGPoint)aPoint{
  NSLog(@"Tap at point %f, %f",aPoint.x,aPoint.y);
  if (_delegateHasSingleTapOnScrollView)
    [_tiledScrollViewDelegate singleTapOnScrollView:self at:aPoint];
}


- (void)tiledView:(JCTiledView *)aTiledView doubleTapAtPoint:(CGPoint)aPoint{
  
  [self zoomInToNextNativeZoomAt:aPoint animated:YES];
  if(_delegateHasDoubleTapOnScrollView)
    [_tiledScrollViewDelegate doubleTapOnScrollView:self at:aPoint];
}



- (void)tiledView:(JCTiledView *)aTiledView twoFingerDoubleTapAtPoint:(CGPoint)aPoint{
  [self zoomOutToNextNativeZoomAt:aPoint animated:YES];
  if(_delegateHasDoubleTapTwoFingersOnScrollView){
    [_tiledScrollViewDelegate doubleTapTwoFingersOnScrollView:self at:aPoint];
  }
}


-(void)tiledView:(JCTiledView *)aTiledView twoFingerSingleTapAtPoint:(CGPoint)aPoint{
  //[self zoomOutToNextNativeZoomAt:aPoint animated:YES];
  
  if(_delegateHasSingleTapTwoFingersOnScrollView)
    [_tiledScrollViewDelegate singleTapTwoFingersOnScrollView:self at:aPoint];
}



- (void)tiledView:(JCTiledView *)aTiledView longPressAtPoint:(CGPoint)aPoint{
  if(_delegateHasLongSingleTapOnScrollView)
    [_tiledScrollViewDelegate longSingleTapOnScrollView:self at:aPoint];
}






#pragma mark - JCTiledScrollView

-(void)setZoomScale:(float)zoomScale{
  self.scrollView.zoomScale = zoomScale;
}

-(float)zoomScale{
  return self.scrollView.zoomScale;
}

-(void)setLevelsOfZoom:(size_t)levelsOfZoom
{
  _levelsOfZoom = levelsOfZoom;
  _scrollView.maximumZoomScale = (float)powf(2, MAX(0, levelsOfZoom));
}

- (void)setLevelsOfDetail:(size_t)levelsOfDetail
{
  if (levelsOfDetail == 1) NSLog(@"Note: Setting levelsOfDetail to 1 causes strange behaviour");
  
  _levelsOfDetail = levelsOfDetail;
  [self.tiledView setNumberOfZoomLevels:levelsOfDetail];
}

- (void)setContentCenter:(CGPoint)center animated:(BOOL)animated
{
  CGPoint new_contentOffset;
  new_contentOffset.x = MAX(0, (center.x * _scrollView.zoomScale) - (self.bounds.size.width / 2.0f));
  new_contentOffset.y = MAX(0, (center.y * _scrollView.zoomScale) - (self.bounds.size.height / 2.0f));
  
  new_contentOffset.x = MIN(new_contentOffset.x, (_scrollView.contentSize.width - self.bounds.size.width));
  new_contentOffset.y = MIN(new_contentOffset.y, (_scrollView.contentSize.height - self.bounds.size.height));
  
  [_scrollView setContentOffset:new_contentOffset animated:animated];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)change context:(void *)context
{
  //RMProjectedRect planetBounds = projection.planetBounds;
  //metersPerPixel = planetBounds.size.width / mapScrollView.contentSize.width;
  zoom = log2f(self.zoomScale);
  
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(correctPositionOfAllAnnotations) object:nil];
  
  //if (_constrainMovement && ![self projectedBounds:_constrainingProjectedBounds containsPoint:[self centerProjectedPoint]])
  if (_constrainMovement)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_scrollView setContentOffset:_lastContentOffset animated:NO];
    });
    
    return;
  }
  
  if (zoom == _lastZoom)
  {
    CGPoint contentOffset = _scrollView.contentOffset;
    CGPoint delta = CGPointMake(_lastContentOffset.x - contentOffset.x, _lastContentOffset.y - contentOffset.y);
    _accumulatedDelta.x += delta.x;
    _accumulatedDelta.y += delta.y;
    
    if (fabsf(_accumulatedDelta.x) < kZoomRectPixelBuffer && fabsf(_accumulatedDelta.y) < kZoomRectPixelBuffer)
    {
      [overlayView moveLayersBy:_accumulatedDelta];
      [self performSelector:@selector(correctPositionOfAllAnnotations) withObject:nil afterDelay:0.1];
    }
    else
    {
      if (_mapScrollViewIsZooming)
        [self correctPositionOfAllAnnotationsIncludingInvisibles:NO wasZoom:YES];
      else
        [self correctPositionOfAllAnnotations];
    }
  }
  else
  {
    [self correctPositionOfAllAnnotationsIncludingInvisibles:NO wasZoom:YES];
    _lastZoom = zoom;
  }
  
  _lastContentOffset = _scrollView.contentOffset;
  
  // Don't do anything stupid here or your scrolling experience will suck
  if (_delegateHasScrollViewRegionDidChange)[_tiledScrollViewDelegate scrollViewRegionDidChange:self];
}

#pragma mark - JCTileSource

-(UIImage *)tiledView:(JCTiledView *)tiledView imageForRow:(NSInteger)row column:(NSInteger)column scale:(NSInteger)scale
{
  return [self.dataSource tiledScrollView:self imageForRow:row column:column scale:scale];
}

#pragma mark - Annotations

- (void)correctScreenPosition:(RMAnnotation *)annotation
{
  //RMProjectedRect planetBounds = projection.planetBounds;
  //RMProjectedPoint normalizedProjectedPoint;
  //normalizedProjectedPoint.x = annotation.projectedLocation.x + fabs(planetBounds.origin.x);
  //normalizedProjectedPoint.y = annotation.projectedLocation.y + fabs(planetBounds.origin.y);
  
  annotation.position = 
  CGPointMake((annotation.positionInTiledContent.x * self.zoomScale) - _scrollView.contentOffset.x, 
              (annotation.positionInTiledContent.y * self.zoomScale) - _scrollView.contentOffset.y);
  //NSLog(@"Change annotation at {%f,%f} in mapView {%f,%f}", annotation.position.x, annotation.position.y, self.contentSize.width, self.contentSize.height);
}

- (void)correctPositionOfAllAnnotations
{
  [self correctPositionOfAllAnnotationsIncludingInvisibles:YES wasZoom:NO];
}

- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllAnnotations wasZoom:(BOOL)wasZoom
{
  // Prevent blurry movements
  [CATransaction begin];
  
  // Synchronize marker movement with the map scroll view
  if (wasZoom && !_scrollView.isZooming)
  {
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [CATransaction setAnimationDuration:0.30];
  }
  else
  {
    [CATransaction setAnimationDuration:0.0];
  }
  
  _accumulatedDelta.x = 0.0;
  _accumulatedDelta.y = 0.0;
  [overlayView moveLayersBy:_accumulatedDelta];
  
  //Annotation clustering is not implemented yet
  if(false)//if (self.quadTree)
  {
    //        if (!correctAllAnnotations || _mapScrollViewIsZooming)
    //        {
    //            for (RMAnnotation *annotation in visibleAnnotations)
    //                [self correctScreenPosition:annotation];
    //            
    //            //            RMLog(@"%d annotations corrected", [visibleAnnotations count]);
    //            
    //            [CATransaction commit];
    //            
    //            return;
    //        }
    //        
    //        RMProjectedRect boundingBox = [self projectedBounds];
    //        double boundingBoxBuffer = kZoomRectPixelBuffer * self.metersPerPixel;
    //        boundingBox.origin.x -= boundingBoxBuffer;
    //        boundingBox.origin.y -= boundingBoxBuffer;
    //        boundingBox.size.width += 2*boundingBoxBuffer;
    //        boundingBox.size.height += 2*boundingBoxBuffer;
    //        
    //        NSArray *annotationsToCorrect = [quadTree annotationsInProjectedRect:boundingBox
    //                                                    createClusterAnnotations:self.enableClustering
    //                                                    withProjectedClusterSize:RMProjectedSizeMake(self.clusterAreaSize.width * self.metersPerPixel, self.clusterAreaSize.height * self.metersPerPixel)
    //                                               andProjectedClusterMarkerSize:RMProjectedSizeMake(self.clusterMarkerSize.width * self.metersPerPixel, self.clusterMarkerSize.height * self.metersPerPixel)
    //                                                           findGravityCenter:self.positionClusterMarkersAtTheGravityCenter];
    //        NSMutableSet *previousVisibleAnnotations = [[NSMutableSet alloc] initWithSet:visibleAnnotations];
    //        
    //        for (RMAnnotation *annotation in annotationsToCorrect)
    //        {
    //            if (annotation.layer == nil && _delegateHasLayerForAnnotation)
    //                annotation.layer = [delegate mapView:self layerForAnnotation:annotation];
    //            if (annotation.layer == nil)
    //                continue;
    //            
    //            // Use the zPosition property to order the layer hierarchy
    //            if (![visibleAnnotations containsObject:annotation])
    //            {
    //                [overlayView addSublayer:annotation.layer];
    //                [visibleAnnotations addObject:annotation];
    //            }
    //            
    //            [self correctScreenPosition:annotation];
    //            
    //            [previousVisibleAnnotations removeObject:annotation];
    //        }
    //        
    //        for (RMAnnotation *annotation in previousVisibleAnnotations)
    //        {
    //            if (_delegateHasWillHideLayerForAnnotation)
    //                [delegate mapView:self willHideLayerForAnnotation:annotation];
    //            
    //            annotation.layer = nil;
    //            
    //            if (_delegateHasDidHideLayerForAnnotation)
    //                [delegate mapView:self didHideLayerForAnnotation:annotation];
    //            
    //            [visibleAnnotations removeObject:annotation];
    //        }
    //        
    //        [previousVisibleAnnotations release];
    //        
    //        //        RMLog(@"%d annotations on screen, %d total", [overlayView sublayersCount], [annotations count]);
  }
  else
  {
    CALayer *lastLayer = nil;
    
    @synchronized (annotations)
    {
      if (correctAllAnnotations)
      {
        for (RMAnnotation *annotation in annotations)
        {
          [self correctScreenPosition:annotation];
          
          if ([annotation isAnnotationWithinBounds:[[self superview] bounds]])
          {
            if (annotation.layer == nil && _delegateHasLayerForAnnotation)
              annotation.layer = [_tiledScrollViewDelegate scrollView:self layerForAnnotation:annotation];
            if (annotation.layer == nil)
              continue;
            
            if (![visibleAnnotations containsObject:annotation])
            {
              if (!lastLayer)
                [overlayView insertSublayer:annotation.layer atIndex:0];
              else
                [overlayView insertSublayer:annotation.layer above:lastLayer];
              CABasicAnimation *theAnimation;
              
              theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
              theAnimation.duration=0.25;
              theAnimation.repeatCount=1;
              //theAnimation.autoreverses=YES;
              theAnimation.fromValue=[NSNumber numberWithFloat:0.0];
              theAnimation.toValue=[NSNumber numberWithFloat:1.0];
              [annotation.layer addAnimation:theAnimation forKey:@"animateOpacity"];
              
              
              
              [visibleAnnotations addObject:annotation];
            }
            
            lastLayer = annotation.layer;
          }
          else
          {
            if (_delegateHasWillHideLayerForAnnotation)
              [_tiledScrollViewDelegate scrollView:self willHideLayerForAnnotation:annotation];
            
            annotation.layer = nil;
            [visibleAnnotations removeObject:annotation];
            
            if (_delegateHasDidHideLayerForAnnotation)
              [_tiledScrollViewDelegate scrollView:self didHideLayerForAnnotation:annotation];
          }
        }
        //                RMLog(@"%d annotations on screen, %d total", [overlayView sublayersCount], [annotations count]);
      }
      else
      {
        for (RMAnnotation *annotation in visibleAnnotations)
          [self correctScreenPosition:annotation];
        
        //                RMLog(@"%d annotations corrected", [visibleAnnotations count]);
      }
    }
  }
  
  [CATransaction commit];
}

- (void)addAnnotation:(RMAnnotation *)annotation
{
  @synchronized (annotations)
  {
    [annotations addObject:annotation];
    //[self.quadTree addAnnotation:annotation];
  }
  
  if (enableClustering)
  {
    //Not implemented yet
    @throw @"Not implemented yet";
    //[self correctPositionOfAllAnnotations];
  }
  else
  {
    
    [self correctScreenPosition:annotation];
    
    if ([annotation isAnnotationOnScreen] && _delegateHasLayerForAnnotation)
    {
      annotation.layer = [self.tiledScrollViewDelegate scrollView:self layerForAnnotation:annotation];
      
      if (annotation.layer)
      {
        NSLog(@"Annotation is on screen and has a layer");
        [overlayView addSublayer:annotation.layer];
        [visibleAnnotations addObject:annotation];
      }
    }
  }
}

@end
