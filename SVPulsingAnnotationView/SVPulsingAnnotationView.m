//
//  SVPulsingAnnotationView.m
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import "SVPulsingAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#define SVImageView UIImageView
#define SVView UIView
#else
#define SVImageView NSImageView
#define SVView NSView
#endif

@interface SVPulsingAnnotationView ()

@property (nonatomic, strong) CALayer *shinyDotLayer;
@property (nonatomic, strong) CALayer *glowingHaloLayer;
@property (nonatomic, strong) SVImageView *imageView;

@property (nonatomic, strong) CALayer *whiteDotLayer;
@property (nonatomic, strong) CALayer *colorDotLayer;
@property (nonatomic, strong) CALayer *colorHaloLayer;

@property (nonatomic, strong) CAAnimationGroup *pulseAnimationGroup;

@end

@implementation SVPulsingAnnotationView

@synthesize annotation = _annotation;
@synthesize image = _image;

+ (NSMutableDictionary*)cachedRingImages {
    static NSMutableDictionary *cachedRingLayers = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{ cachedRingLayers = [NSMutableDictionary new]; });
    return cachedRingLayers;
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.calloutOffset = CGPointMake(0, 4);
#if TARGET_OS_IPHONE
        self.bounds = CGRectMake(0, 0, 22, 22);
#else
        self.frame = NSMakeRect(0, 0, 22, 22);
#endif
        self.pulseScaleFactor = 5.3;
        self.pulseAnimationDuration = 1.5;
        self.outerPulseAnimationDuration = 3;
        self.delayBetweenPulseCycles = 0;
        self.annotationColor = [SVColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1];
    }
    return self;
}

- (void)rebuildLayers {
    [_whiteDotLayer removeFromSuperlayer];
    _whiteDotLayer = nil;
    
    [_colorDotLayer removeFromSuperlayer];
    _colorDotLayer = nil;
    
    [_colorHaloLayer removeFromSuperlayer];
    _colorHaloLayer = nil;
    
    _pulseAnimationGroup = nil;
    
    if(!self.image) {
        [_imageView removeFromSuperview];
        _imageView = nil;
    }
    
    [self.layer addSublayer:self.colorHaloLayer];
    [self.layer addSublayer:self.whiteDotLayer];
    
    if(self.image)
        [self addSubview:self.imageView];
    else
        [self.layer addSublayer:self.colorDotLayer];
}

#if TARGET_OS_IPHONE
- (void)willMoveToSuperview:(SVView *)newSuperview {
#else
-(void)viewWillMoveToSuperview:(SVView *)newSuperview {
#endif
    if(newSuperview) {
        [self rebuildLayers];
        [self popIn];
    }
}

- (void)popIn {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    bounceAnimation.values = @[@0.05, @1.25, @0.8, @1.1, @0.9, @1.0];
    bounceAnimation.duration = 0.3;
    bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut, easeInOut, easeInOut];
    [self.layer addAnimation:bounceAnimation forKey:@"popIn"];
}

#pragma mark - Setters

- (void)setAnnotationColor:(SVColor *)annotationColor {
    if(CGColorGetNumberOfComponents(annotationColor.CGColor) == 2) {
        float white = CGColorGetComponents(annotationColor.CGColor)[0];
        float alpha = CGColorGetComponents(annotationColor.CGColor)[1];
        annotationColor = [SVColor colorWithRed:white green:white blue:white alpha:alpha];
    }
    
    _annotationColor = annotationColor;
#if TARGET_OS_IPHONE
    _imageView.tintColor = annotationColor;
#endif
    if(self.superview)
        [self rebuildLayers];
}

- (void)setDelayBetweenPulseCycles:(NSTimeInterval)delayBetweenPulseCycles {
    _delayBetweenPulseCycles = delayBetweenPulseCycles;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setPulseAnimationDuration:(NSTimeInterval)pulseAnimationDuration {
    _pulseAnimationDuration = pulseAnimationDuration;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setImage:(SVImage *)image {
    _image = image;
    
    if(self.superview)
        [self rebuildLayers];
    
#if TARGET_OS_IPHONE
    self.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.bounds = CGRectMake(0, 0, ceil(image.size.width), ceil(image.size.height));
    
    self.imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.imageView.tintColor = self.annotationColor;
#else
    self.imageView.image = _image;
#endif
}

#pragma mark - Getters

- (SVColor *)pulseColor {
    if(!_pulseColor)
        return self.annotationColor;
    return _pulseColor;
}

- (CAAnimationGroup*)pulseAnimationGroup {
    if(!_pulseAnimationGroup) {
        CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        
        _pulseAnimationGroup = [CAAnimationGroup animation];
        _pulseAnimationGroup.duration = self.outerPulseAnimationDuration + self.delayBetweenPulseCycles;
        _pulseAnimationGroup.repeatCount = INFINITY;
        _pulseAnimationGroup.removedOnCompletion = NO;
        _pulseAnimationGroup.timingFunction = defaultCurve;
        
        NSMutableArray *animations = [NSMutableArray new];
        
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
        pulseAnimation.fromValue = @0.0;
        pulseAnimation.toValue = @1.0;
        pulseAnimation.duration = self.outerPulseAnimationDuration;
        [animations addObject:pulseAnimation];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        animation.duration = self.outerPulseAnimationDuration;
        animation.values = @[@0.45, @0.45, @0];
        animation.keyTimes = @[@0, @0.2, @1];
        animation.removedOnCompletion = NO;
        [animations addObject:animation];
        
        _pulseAnimationGroup.animations = animations;
    }
    return _pulseAnimationGroup;
}

#pragma mark - Graphics

- (SVImageView *)imageView {
    if(!_imageView) {
        _imageView = [[SVImageView alloc] initWithFrame:self.bounds];
#if TARGET_OS_IPHONE
        _imageView.contentMode = UIViewContentModeTopLeft;
#endif
    }
    return _imageView;
}

- (CALayer*)whiteDotLayer {
    if(!_whiteDotLayer) {
        _whiteDotLayer = [CALayer layer];
        _whiteDotLayer.bounds = self.bounds;
#if TARGET_OS_IPHONE
        _whiteDotLayer.contents = (id)[self circleImageWithColor:[SVColor whiteColor] height:self.bounds.size.height].CGImage;
        _whiteDotLayer.contentsScale = [UIScreen mainScreen].scale;
        _whiteDotLayer.rasterizationScale = [UIScreen mainScreen].scale;
#else
        _whiteDotLayer.contents = [self circleImageWithColor:[SVColor whiteColor] height:self.bounds.size.height];
#endif
        _whiteDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _whiteDotLayer.contentsGravity = kCAGravityCenter;
        
        _whiteDotLayer.shadowColor = [SVColor blackColor].CGColor;
        _whiteDotLayer.shadowOffset = CGSizeMake(0, 2);
        _whiteDotLayer.shadowRadius = 3;
        _whiteDotLayer.shadowOpacity = 0.3;
        _whiteDotLayer.shouldRasterize = YES;
    }
    return _whiteDotLayer;
}

- (CALayer*)colorDotLayer {
    if(!_colorDotLayer) {
        _colorDotLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width-6;
        _colorDotLayer.bounds = CGRectMake(0, 0, width, width);
        
#if TARGET_OS_IPHONE
        _colorDotLayer.allowsGroupOpacity = YES;
#endif
        
        _colorDotLayer.backgroundColor = self.annotationColor.CGColor;
        _colorDotLayer.cornerRadius = width/2;
        _colorDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
                
                CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
                animationGroup.duration = self.pulseAnimationDuration;
                animationGroup.repeatCount = INFINITY;
                animationGroup.removedOnCompletion = NO;
                animationGroup.autoreverses = YES;
                animationGroup.timingFunction = defaultCurve;
                animationGroup.speed = 1;
                animationGroup.fillMode = kCAFillModeBoth;
                
                CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
                pulseAnimation.fromValue = @0.8;
                pulseAnimation.toValue = @1;
                pulseAnimation.duration = self.pulseAnimationDuration;
                
                CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                opacityAnimation.fromValue = @0.8;
                opacityAnimation.toValue = @1;
                opacityAnimation.duration = self.pulseAnimationDuration;
                
                animationGroup.animations = @[pulseAnimation, opacityAnimation];
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [_colorDotLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });
        
    }
    return _colorDotLayer;
}

- (CALayer *)colorHaloLayer {
    if(!_colorHaloLayer) {
        _colorHaloLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width*self.pulseScaleFactor;
        _colorHaloLayer.bounds = CGRectMake(0, 0, width, width);
        _colorHaloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
#if TARGET_OS_IPHONE
        _colorHaloLayer.contentsScale = [UIScreen mainScreen].scale;
#endif
        
        _colorHaloLayer.backgroundColor = self.pulseColor.CGColor;
        _colorHaloLayer.cornerRadius = width/2;
        _colorHaloLayer.opacity = 0;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAAnimationGroup *animationGroup = self.pulseAnimationGroup;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [_colorHaloLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });
    }
    return _colorHaloLayer;
}

- (SVImage*)circleImageWithColor:(SVColor*)color height:(float)height {
#if TARGET_OS_IPHONE
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIBezierPath* fillPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, height, height)];
    [color setFill];
    [fillPath fill];
    
    SVImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpace);
    
    return dotImage;
#else
    return [NSImage imageWithSize:NSMakeSize(height, height) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        NSBezierPath *fillPath = [NSBezierPath bezierPathWithOvalInRect:dstRect];
        [color setFill];
        [fillPath fill];
        return YES;
    }];
#endif
}

@end
