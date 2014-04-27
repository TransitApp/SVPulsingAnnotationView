//
//  SVPulsingAnnotationView.m
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import "SVPulsingAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

@interface SVPulsingAnnotationView ()

@property (nonatomic, strong) CALayer *shinyDotLayer;
@property (nonatomic, strong) CALayer *glowingHaloLayer;
@property (nonatomic, strong) UIImageView *imageView;

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
        self.bounds = CGRectMake(0, 0, 22, 22);
        self.pulseScaleFactor = 5.3;
        self.pulseAnimationDuration = 1.5;
        self.outerPulseAnimationDuration = 3;
        self.delayBetweenPulseCycles = 0;
        self.annotationColor = [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1];
        
        self.willMoveToSuperviewAnimationBlock = ^(SVPulsingAnnotationView *annotationView, UIView *superview) {
            CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            
            bounceAnimation.values = @[@0.05, @1.25, @0.8, @1.1, @0.9, @1.0];
            bounceAnimation.duration = 0.3;
            bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut, easeInOut, easeInOut];
            [annotationView.layer addAnimation:bounceAnimation forKey:@"popIn"];
        };
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

- (void)willMoveToSuperview:(UIView *)superview {
    if(superview)
        [self rebuildLayers];
    
    if(self.willMoveToSuperviewAnimationBlock)
        self.willMoveToSuperviewAnimationBlock(self, superview);
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

- (void)setAnnotationColor:(UIColor *)annotationColor {
    if(CGColorGetNumberOfComponents(annotationColor.CGColor) == 2) {
        float white = CGColorGetComponents(annotationColor.CGColor)[0];
        float alpha = CGColorGetComponents(annotationColor.CGColor)[1];
        annotationColor = [UIColor colorWithRed:white green:white blue:white alpha:alpha];
    }
    
    _annotationColor = annotationColor;
    _imageView.tintColor = annotationColor;
    
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

- (void)setImage:(UIImage *)image {
    _image = image;
    
    if(self.superview)
        [self rebuildLayers];
    
    self.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.bounds = CGRectMake(0, 0, ceil(image.size.width), ceil(image.size.height));
    self.imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.imageView.tintColor = self.annotationColor;
}

#pragma mark - Getters

- (UIColor *)pulseColor {
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

- (UIImageView *)imageView {
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeTopLeft;
    }
    return _imageView;
}

- (CALayer*)whiteDotLayer {
    if(!_whiteDotLayer) {
        _whiteDotLayer = [CALayer layer];
        _whiteDotLayer.bounds = self.bounds;
        _whiteDotLayer.contents = (id)[self circleImageWithColor:[UIColor whiteColor] height:self.bounds.size.height].CGImage;
        _whiteDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _whiteDotLayer.contentsGravity = kCAGravityCenter;
        _whiteDotLayer.contentsScale = [UIScreen mainScreen].scale;
        _whiteDotLayer.shadowColor = [UIColor blackColor].CGColor;
        _whiteDotLayer.shadowOffset = CGSizeMake(0, 2);
        _whiteDotLayer.shadowRadius = 3;
        _whiteDotLayer.shadowOpacity = 0.3;
        _whiteDotLayer.shouldRasterize = YES;
        _whiteDotLayer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return _whiteDotLayer;
}

- (CALayer*)colorDotLayer {
    if(!_colorDotLayer) {
        _colorDotLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width-6;
        _colorDotLayer.bounds = CGRectMake(0, 0, width, width);
        _colorDotLayer.allowsGroupOpacity = YES;
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
        _colorHaloLayer.contentsScale = [UIScreen mainScreen].scale;
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

- (UIImage*)circleImageWithColor:(UIColor*)color height:(float)height {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIBezierPath* fillPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, height, height)];
    [color setFill];
    [fillPath fill];
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpace);
    
    return dotImage;
}

@end
