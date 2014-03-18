//
//  SVPulsingAnnotationView.h
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import <MapKit/MapKit.h>

#if TARGET_OS_IPHONE
#define SVColor UIColor
#define SVImage UIImage
#else
#define SVColor NSColor
#define SVImage NSImage
#endif

@interface SVPulsingAnnotationView : MKAnnotationView

@property (nonatomic, strong) SVColor *annotationColor; // default is same as MKUserLocationView
@property (nonatomic, strong) SVColor *pulseColor; // default is same as annotationColor
@property (nonatomic, strong) SVImage *image; // default is nil

@property (nonatomic, readwrite) float pulseScaleFactor; // default is 5.3
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration; // default is 1s
@property (nonatomic, readwrite) NSTimeInterval outerPulseAnimationDuration; // default is 3s
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles; // default is 1s

@end
