# SVPulsingAnnotationView

SVPulsingAnnotationView is a customizable, high-fidelity replica of Apple's `MKUserLocationView`. 

For more details about how it was created, head over to my [Recreating MKUserLocationView](http://samvermette.com/317) blog post.

![SVPulsingAnnotationView](http://cl.ly/NI4r/SVPulsingAnnotationView.gif)

## Installation

### From CocoaPods

Add `pod 'SVPulsingAnnotationView'` to your Podfile or `pod 'SVPulsingAnnotationView', :head` if you're feeling adventurous.

### Manually

_**Important note if your project doesn't use ARC**: you must add the `-fobjc-arc` compiler flag to `SVPulsingAnnotationView.m` in Target Settings > Build Phases > Compile Sources._

* Drag the `SVPulsingAnnotationView/SVPulsingAnnotationView` folder into your project. 
* Add the **QuartzCore** and **MapKit** frameworks to your project.

## Usage

(see sample Xcode project in `/Demo`)

You use SVPulsingAnnotationView just like any other MKAnnotationView:

```objective-c
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if([annotation isKindOfClass:[MyAnnotationClass class]]) {
        static NSString *identifier = @"currentLocation";
        SVPulsingAnnotationView *pulsingView = (SVPulsingAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

        if(pulsingView == nil) {
            pulsingView = [[SVPulsingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            pulsingView.annotationColor = [UIColor colorWithRed:0.678431 green:0 blue:0 alpha:1];
        }

        pulsingView.canShowCallout = YES;
        return pulsingView;
    }

    return nil;
}
```

## Customization

SVPulsingAnnotationView can be customized with the following properties:

```objective-c
@property (nonatomic, strong) UIColor *annotationColor;
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration;
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles;
```

## Credits

SVPulsingAnnotationView is brought to you by [Sam Vermette](http://samvermette.com) and [contributors to the project](https://github.com/samvermette/SVPulsingAnnotationView/contributors). If you have feature suggestions or bug reports, feel free to help out by sending pull requests or by [creating new issues](https://github.com/samvermette/SVPulsingAnnotationView/issues/new). If you're using SVPulsingAnnotationView in your project, attribution would be nice.

Hat tip to [Nick Farina](http://nfarina.com) for sharing the process of [creating his UICalloutView replica](http://nfarina.com/post/29883229869/callout-view).