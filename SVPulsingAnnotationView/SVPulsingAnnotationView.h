//
//  SPRealTimeVehicleAnnotationView.h
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import <MapKit/MapKit.h>

@interface SVPulsingAnnotationView : MKAnnotationView

@property (nonatomic, strong) UIColor *annotationColor;
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration;
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles;

@end
