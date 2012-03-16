//
//  JCTiledScrollView.h
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

#import <UIKit/UIKit.h>
#import <CoreGraphics/CGGeometry.h>
#import "JCTiledView.h"
#import "RMAnnotation.h"
#import "RMMapOverlayView.h"

@class JCTiledScrollView, JCTiledView;

@protocol JCTileSource <NSObject>
- (UIImage *)tiledScrollView:(JCTiledScrollView *)scrollView imageForRow:(NSInteger)row column:(NSInteger)column scale:(NSInteger)scale;
@end

@protocol JCTiledScrollViewDelegate <NSObject>
@optional
- (void)tiledScrollViewDidZoom:(JCTiledScrollView *)scrollView;
- (void)tiledScrollViewWillZoom:(JCTiledScrollView *)scrollView;
- (void)tiledScrollViewWillScroll:(JCTiledScrollView*)scrollView;
- (void)tiledScrollViewDidScroll:(JCTiledScrollView *)scrollView;


//From RMMApViewDelegate
- (void)scrollViewRegionDidChange:(JCTiledScrollView *)scrollView;
- (RMMapLayer *)scrollView:(JCTiledScrollView *)mapView layerForAnnotation:(RMAnnotation *)annotation;
- (void)scrollView:(JCTiledScrollView *)mapView willHideLayerForAnnotation:(RMAnnotation *)annotation;
- (void)scrollView:(JCTiledScrollView *)mapView didHideLayerForAnnotation:(RMAnnotation *)annotation;

- (void)tapOnAnnotation:(RMAnnotation *)annotation inScrollView:(JCTiledScrollView *)scrollView;
- (void)doubleTapOnAnnotation:(RMAnnotation *)annotation inScrollView:(JCTiledScrollView *)scrollView;
- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation inScrollView:(JCTiledScrollView *)scrollView;
- (void)doubleTapOnLabelForAnnotation:(RMAnnotation *)annotation inScrollView:(JCTiledScrollView *)scrollView;


@end

@interface JCTiledScrollView : UIView <UIScrollViewDelegate,RMMapOverlayViewDelegate>{
    //From RMMapView
    NSMutableSet   *annotations;
    NSMutableSet   *visibleAnnotations;
    BOOL            enableClustering, positionClusterMarkersAtTheGravityCenter;
    RMMapOverlayView *overlayView;
}

@property (nonatomic, assign) id <JCTiledScrollViewDelegate> tiledScrollViewDelegate;
@property (nonatomic, retain) UIScrollView * scrollView;
@property (nonatomic, assign) float zoomScale;
@property (nonatomic, assign) id <JCTileSource> dataSource;
@property (nonatomic, retain) JCTiledView *tiledView;
@property (nonatomic, assign) size_t levelsOfZoom;
@property (nonatomic, assign) size_t levelsOfDetail;

+ (Class)tiledLayerClass;

- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize;

- (void)setContentCenter:(CGPoint)center animated:(BOOL)animated;

//From RMMapView
- (void)addAnnotation:(RMAnnotation *)annotation;


@end
