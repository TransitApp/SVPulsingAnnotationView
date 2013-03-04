//
//  SPRealTimeVehicleAnnotationView.h
//  Transit
//
//  Created by Sam Vermette on 01.03.13.
//
//

#import <MapKit/MapKit.h>

@interface SVPulsingAnnotationView : MKAnnotationView

@property (nonatomic, strong) UIColor *annotationColor;
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration;
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles;

@end
