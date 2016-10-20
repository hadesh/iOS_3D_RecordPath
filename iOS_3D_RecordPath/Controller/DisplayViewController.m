
//
//  DisplayViewController.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "DisplayViewController.h"
#import "MAMutablePolylineRenderer.h"
#import "Record.h"
#import "MovingAnnotationView.h"
#import "TracingPoint.h"
#import "Util.h"

@interface DisplayViewController()<MAMapViewDelegate>
{
    NSMutableArray *_tracking;
    CFTimeInterval _duration;
}

@property (nonatomic, strong) Record *record;

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) MAPointAnnotation *myLocation;

@property (nonatomic, assign) BOOL isPlaying;

@end


@implementation DisplayViewController


#pragma mark - Utility

- (void)showRoute
{
    if (self.record == nil || [self.record numOfLocations] == 0)
    {
        NSLog(@"invaled route");
    }
    
    MAPointAnnotation *startPoint = [[MAPointAnnotation alloc] init];
    startPoint.coordinate = [self.record startLocation].coordinate;
    startPoint.title = @"start";
    [self.mapView addAnnotation:startPoint];
    
    MAPointAnnotation *endPoint = [[MAPointAnnotation alloc] init];
    endPoint.coordinate = [self.record endLocation].coordinate;
    endPoint.title = @"end";
    [self.mapView addAnnotation:endPoint];

    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:self.record.coordinates count:self.record.numOfLocations];
    [self.mapView addOverlay:polyline];
    
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
    
    [self initTrackingWithCoords:self.record.coordinates count:self.record.numOfLocations];
}

#pragma mark - Interface

- (void)setRecord:(Record *)record
{
    if (_record == record)
    {
        return;
    }
    
    [self actionPlayAndStop];
    
    _record = record;
    _duration = _record.totalDuration / 10.0;
}

#pragma mark - mapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if([annotation isEqual:self.myLocation]) {
        
        static NSString *annotationIdentifier = @"myLcoationIdentifier";
        
        MovingAnnotationView *annotationView = (MovingAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (annotationView == nil)
        {
            annotationView = [[MovingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"aeroplane.png"];
        annotationView.canShowCallout = NO;
        
        return annotationView;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *annotationIdentifier = @"lcoationIdentifier";
        
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        poiAnnotationView.pinColor = MAPinAnnotationColorGreen;
        poiAnnotationView.canShowCallout = YES;
        
        return poiAnnotationView;
    }
    
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *view = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        view.lineWidth = 4.0;
        view.strokeColor = [UIColor redColor];
        
        return view;
    }
    return nil;
}

#pragma mark - Action

- (void)actionPlayAndStop
{
    if (self.record == nil)
    {
        return;
    }
    
    self.isPlaying = !self.isPlaying;
    if (self.isPlaying)
    {
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"icon_stop.png"];
        if (self.myLocation == nil)
        {
            self.myLocation = [[MAPointAnnotation alloc] init];
            self.myLocation.title = @"AMap";
            self.myLocation.coordinate = [self.record startLocation].coordinate;
            
            [self.mapView addAnnotation:self.myLocation];
        }
        
        MovingAnnotationView * carView = (MovingAnnotationView *)[self.mapView viewForAnnotation:self.myLocation];
        [carView addTrackingAnimationForPoints:_tracking duration:_duration];

    }
    else
    {
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"icon_play.png"];
        
        MAAnnotationView *view = [self.mapView viewForAnnotation:self.myLocation];
        
        if (view != nil)
        {
            [view.layer removeAllAnimations];
        }
    }
}

#pragma mark - Initialazation

- (void)initToolBar
{
    UIBarButtonItem *playItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_play.png"] style:UIBarButtonItemStylePlain target:self action:@selector(actionPlayAndStop)];
    self.navigationItem.rightBarButtonItem = playItem;
}

- (void)initMapView
{
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
}

- (void)initTrackingWithCoords:(CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    _tracking = [NSMutableArray array];
    for (int i = 0; i<count - 1; i++)
    {
        TracingPoint * tp = [[TracingPoint alloc] init];
        tp.coordinate = coords[i];
        tp.course = [Util calculateCourseFromCoordinate:coords[i] to:coords[i+1]];
        [_tracking addObject:tp];
    }
    
    TracingPoint * tp = [[TracingPoint alloc] init];
    tp.coordinate = coords[count - 1];
    tp.course = ((TracingPoint *)[_tracking lastObject]).course;
    [_tracking addObject:tp];
}


#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Display";
    
    [self initMapView];
    
    [self initToolBar];
    
    [self showRoute];
}

@end
