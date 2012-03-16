//
//  RMAnnotation.m
//  MapView
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import <CoreLocation/CoreLocation.h>

//#import "RMGlobalConstants.h"
#import "RMAnnotation.h"
#import "JCTiledScrollView.h"//#import "RMMapView.h"
#import "RMMapLayer.h"
//#import "RMQuadTree.h"

@implementation RMAnnotation

@synthesize coordinate;
@synthesize title;
@synthesize userInfo;
@synthesize annotationType;
@synthesize annotationIcon, badgeIcon;
@synthesize anchorPoint;

@synthesize mapView;
//@synthesize projectedLocation;
//@synthesize projectedBoundingBox;
@synthesize hasBoundingBox;
@synthesize enabled, clusteringEnabled;
@synthesize position;
@synthesize positionInTiledContent;
@synthesize quadTreeNode;

+ (id)annotationWithScrollView:(JCTiledScrollView *)aScrollView positionInTiledContent:(CGPoint)aPositionInTiledContent andTitle:(NSString *)aTitle
{
    return [[[self alloc] initWithScrollView:aScrollView positionInTiledContent:aPositionInTiledContent andTitle:aTitle] autorelease];
}

- (id)initWithScrollView:(JCTiledScrollView *)aScrollView positionInTiledContent:(CGPoint)aPositionInTiledContent andTitle:(NSString *)aTitle
{
    if (!(self = [super init]))
        return nil;

    self.mapView      = aScrollView;
    //self.coordinate   = aCoordinate;
    self.title        = aTitle;
    self.userInfo     = nil;
    self.quadTreeNode = nil;

    self.annotationType    = nil;
    self.annotationIcon    = nil;
    self.badgeIcon         = nil;
    self.anchorPoint       = CGPointZero;
    self.hasBoundingBox    = NO;
    self.enabled           = YES;
    self.clusteringEnabled = YES;
    self.positionInTiledContent = aPositionInTiledContent;

    layer = nil;

    return self;
}

- (void)dealloc
{
    self.title        = nil;
    self.userInfo     = nil;
    self.layer        = nil;
    //[[self.mapView quadTree] removeAnnotation:self];
    self.quadTreeNode = nil;
    self.mapView      = nil;

    self.annotationType = nil;
    self.annotationIcon = nil;
    self.badgeIcon      = nil;

    [super dealloc];
}

- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    coordinate = aCoordinate;
    //self.projectedLocation = [[mapView projection] coordinateToProjectedPoint:aCoordinate];
    //self.position = [mapView projectedPointToPixel:self.projectedLocation];

    //if (!self.hasBoundingBox)
        //self.projectedBoundingBox = RMProjectedRectMake(self.projectedLocation.x, self.projectedLocation.y, 1.0, 1.0);

    //[self.quadTreeNode performSelector:@selector(annotationDidChangeBoundingBox:) withObject:self];
}

- (void)setMapView:(JCTiledScrollView *)aMapView
{
    [mapView autorelease];
    mapView = [aMapView retain];

    if (!aMapView)
        self.layer = nil;
}

- (void)setPosition:(CGPoint)aPosition
{
    position = aPosition;

    if (layer)
        layer.position = aPosition;
}

- (RMMapLayer *)layer
{
    return layer;
}

- (void)setLayer:(RMMapLayer *)aLayer
{
    if (layer != aLayer)
    {
        if (layer.superlayer)
            [layer removeFromSuperlayer];

        [layer release]; layer = nil;
    }

    if (aLayer)
    {
        layer = aLayer;
        [layer retain];
        layer.annotation = self;
        layer.position = self.position;
    }
}

- (BOOL)isAnnotationWithinBounds:(CGRect)bounds
{
    if (self.hasBoundingBox)
    {
        //RMProjectedRect projectedScreenBounds = [mapView projectedBounds];
        //return RMProjectedRectIntersectsProjectedRect(projectedScreenBounds, projectedBoundingBox);
        
    }
    else
    {
        //NSLog(@"Annotation is without bounds");
        return CGRectContainsPoint(bounds, self.position);
    }

}

- (BOOL)isAnnotationOnScreen
{
    CGRect screenBounds = [[mapView superview] bounds];
    //NSLog(@"Screen bounds: w:%f h:%f", screenBounds.size.width,screenBounds.size.height);
    return [self isAnnotationWithinBounds:screenBounds];
}

#pragma mark -

- (void)setBoundingBoxCoordinatesSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast
{
    //RMProjectedPoint first = [[mapView projection] coordinateToProjectedPoint:southWest];
    //RMProjectedPoint second = [[mapView projection] coordinateToProjectedPoint:northEast];
    //self.projectedBoundingBox = RMProjectedRectMake(first.x, first.y, second.x - first.x, second.y - first.y);
    self.hasBoundingBox = YES;
}

- (void)setBoundingBoxFromLocations:(NSArray *)locations
{
    CLLocationCoordinate2D min, max;
	//min.latitude = kRMMaxLatitude; min.longitude = kRMMaxLongitude;
	//max.latitude = kRMMinLatitude; max.longitude = kRMMinLongitude;

    CLLocationDegrees currentLatitude, currentLongitude;

	for (CLLocation *currentLocation in locations)
    {
        currentLatitude = currentLocation.coordinate.latitude;
        currentLongitude = currentLocation.coordinate.longitude;

        // POIs outside of the world...
        //if (currentLatitude < kRMMinLatitude || currentLatitude > kRMMaxLatitude || currentLongitude < kRMMinLongitude || currentLongitude > kRMMaxLongitude)
            //continue;

		//max.latitude  = fmax(currentLatitude, max.latitude);
		//max.longitude = fmax(currentLongitude, max.longitude);
		//min.latitude  = fmin(currentLatitude, min.latitude);
		//min.longitude = fmin(currentLongitude, min.longitude);
	}

    [self setBoundingBoxCoordinatesSouthWest:min northEast:max];
}

#pragma mark -

- (NSString *)description
{
//    if (self.hasBoundingBox)
//        return [NSString stringWithFormat:@"<%@: %@ @ (%.0f,%.0f) {(%.0f,%.0f) - (%.0f,%.0f)}>", NSStringFromClass([self class]), (self.title ? self.title : self.annotationType), self.projectedLocation.x, self.projectedLocation.y, self.projectedBoundingBox.origin.x, self.projectedBoundingBox.origin.y, self.projectedBoundingBox.origin.x + self.projectedBoundingBox.size.width, self.projectedBoundingBox.origin.y + self.projectedBoundingBox.size.height];
//    else
//        return [NSString stringWithFormat:@"<%@: %@ @ (%.0f,%.0f)>", NSStringFromClass([self class]), (self.title ? self.title : self.annotationType), self.projectedLocation.x, self.projectedLocation.y];
    return @"Description should be added for RMAnnotation";
}

@end
