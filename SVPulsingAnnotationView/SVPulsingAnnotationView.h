//
//  SVPulsingAnnotationView.h
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import <MapKit/MapKit.h>

@interface SVPulsingAnnotationView : MKAnnotationView

@property (nonatomic, strong) UIColor *annotationColor; // default is same as MKUserLocationView
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration; // default is 1s
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles; // default is 1s

@end
