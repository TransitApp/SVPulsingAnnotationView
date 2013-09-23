//
//  SVPulsingAnnotationView.m
//
//  Created by Sam Vermette on 01.03.13.
//  https://github.com/samvermette/SVPulsingAnnotationView
//

#import "SVPulsingAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

@interface SVPulsingAnnotationView ()

@property (nonatomic, readwrite) BOOL shouldBeFlat;

@property (nonatomic, strong) CALayer *shinyDotLayer;
@property (nonatomic, strong) CALayer *glowingHaloLayer;

@property (nonatomic, strong) CALayer *whiteDotLayer;
@property (nonatomic, strong) CALayer *colorDotLayer;
@property (nonatomic, strong) CALayer *colorHaloLayer;

@property (nonatomic, strong) CAAnimationGroup *pulseAnimationGroup;

@end

@implementation SVPulsingAnnotationView

@synthesize annotation = _annotation;

+ (NSMutableDictionary*)cachedRingImages {
    static NSMutableDictionary *cachedRingLayers = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{ cachedRingLayers = [NSMutableDictionary new]; });
    return cachedRingLayers;
}

- (BOOL)shouldBeFlat {
    return ([[[UIDevice currentDevice] systemVersion] compare:@"7" options:NSNumericSearch] == NSOrderedDescending);
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.calloutOffset = CGPointMake(0, 4);
        
        if(self.shouldBeFlat) {
            self.bounds = CGRectMake(0, 0, 22, 22);
            self.pulseAnimationDuration = 1.5;
            self.outerPulseAnimationDuration = 3;
            self.delayBetweenPulseCycles = 0;
            self.annotationColor = [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1];
        }
        else {
            self.bounds = CGRectMake(0, 0, 23, 23);
            self.pulseAnimationDuration = 1;
            self.outerPulseAnimationDuration = 1;
            self.delayBetweenPulseCycles = 1;
            self.annotationColor = [UIColor colorWithRed:0.082 green:0.369 blue:0.918 alpha:1];
        }
    }
    return self;
}

- (void)rebuildLayers {
    if(self.shouldBeFlat) {
        [_whiteDotLayer removeFromSuperlayer];
        _whiteDotLayer = nil;
        
        [_colorDotLayer removeFromSuperlayer];
        _colorDotLayer = nil;
        
        [_colorHaloLayer removeFromSuperlayer];
        _colorHaloLayer = nil;
        
        [self.layer addSublayer:self.colorHaloLayer];
        [self.layer addSublayer:self.whiteDotLayer];
        [self.layer addSublayer:self.colorDotLayer];
    }
    else {
        [_glowingHaloLayer removeFromSuperlayer];
        _glowingHaloLayer = nil;
        
        [_shinyDotLayer removeFromSuperlayer];
        _shinyDotLayer = nil;
        
        [self.layer addSublayer:self.glowingHaloLayer];
        [self.layer addSublayer:self.shinyDotLayer];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
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
    [(self.shouldBeFlat ? self.layer : self.shinyDotLayer) addAnimation:bounceAnimation forKey:@"popIn"];
}

#pragma mark - Setters

- (void)setAnnotationColor:(UIColor *)annotationColor {
    if(CGColorGetNumberOfComponents(annotationColor.CGColor) == 2) {
        float white = CGColorGetComponents(annotationColor.CGColor)[0];
        float alpha = CGColorGetComponents(annotationColor.CGColor)[1];
        annotationColor = [UIColor colorWithRed:white green:white blue:white alpha:alpha];
    }
    _annotationColor = annotationColor;
    
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

- (CAAnimationGroup*)pulseAnimationGroup {
    if(!_pulseAnimationGroup) {
        CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        
        _pulseAnimationGroup = [CAAnimationGroup animation];
        _pulseAnimationGroup.duration = self.outerPulseAnimationDuration + self.delayBetweenPulseCycles;
        _pulseAnimationGroup.repeatCount = INFINITY;
        _pulseAnimationGroup.removedOnCompletion = NO;
        _pulseAnimationGroup.timingFunction = defaultCurve;
        
        NSMutableArray *animations = [NSMutableArray new];
        
        if(!self.shouldBeFlat) {
            CAKeyframeAnimation *imageAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            imageAnimation.duration = self.pulseAnimationDuration;
            imageAnimation.calculationMode = kCAAnimationDiscrete;
            imageAnimation.values = @[
                                      (id)[[self haloImageWithRadius:20] CGImage],
                                      (id)[[self haloImageWithRadius:35] CGImage],
                                      (id)[[self haloImageWithRadius:50] CGImage]
                                      ];
            [animations addObject:imageAnimation];
        }
        
        
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
        pulseAnimation.fromValue = @0.0;
        pulseAnimation.toValue = @1.0;
        pulseAnimation.duration = self.outerPulseAnimationDuration;
        [animations addObject:pulseAnimation];
        
        
        if(!self.shouldBeFlat) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @1.0;
            animation.toValue = @0.0;
            animation.duration = self.outerPulseAnimationDuration;
            animation.timingFunction = defaultCurve;
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            [animations addObject:animation];
        }
        else {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            animation.duration = self.outerPulseAnimationDuration;
            animation.values = @[@0.45, @0.45, @0];
            animation.keyTimes = @[@0, @0.2, @1];
            animation.removedOnCompletion = NO;
            [animations addObject:animation];
        }
        
        _pulseAnimationGroup.animations = animations;
    }
    return _pulseAnimationGroup;
}

#pragma mark - iOS 7

- (CALayer*)whiteDotLayer {
    if(!_whiteDotLayer) {
        _whiteDotLayer = [CALayer layer];
        _whiteDotLayer.bounds = self.bounds;
        _whiteDotLayer.contents = (id)[self circleImageWithColor:[UIColor whiteColor] height:22].CGImage;
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
        _colorDotLayer.bounds = CGRectMake(0, 0, 16, 16);
        _colorDotLayer.allowsGroupOpacity = YES;
        _colorDotLayer.backgroundColor = self.annotationColor.CGColor;
        _colorDotLayer.cornerRadius = 8;
        _colorDotLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];

                CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
                animationGroup.duration = self.pulseAnimationDuration;
                animationGroup.repeatCount = INFINITY;
                animationGroup.removedOnCompletion = NO;
                animationGroup.autoreverses = YES;
                animationGroup.beginTime = 1;
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
        _colorHaloLayer.bounds = CGRectMake(0, 0, 120, 120);
        _colorHaloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _colorHaloLayer.contentsScale = [UIScreen mainScreen].scale;
        _colorHaloLayer.backgroundColor = self.annotationColor.CGColor;
        _colorHaloLayer.cornerRadius = 60;
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

#pragma mark - iOS 6

- (CALayer *)shinyDotLayer {
    if(!_shinyDotLayer) {
        _shinyDotLayer = [CALayer layer];
        _shinyDotLayer.bounds = self.bounds;
        _shinyDotLayer.contents = (id)[self dotAnnotationImage].CGImage;
        _shinyDotLayer.position = CGPointMake(self.bounds.size.width/2+0.5, self.bounds.size.height/2+0.5); // 0.5 is for drop shadow
        _shinyDotLayer.contentsGravity = kCAGravityCenter;
        _shinyDotLayer.contentsScale = [UIScreen mainScreen].scale;
    }
    return _shinyDotLayer;
}

- (CALayer *)glowingHaloLayer {
    if(!_glowingHaloLayer) {
        _glowingHaloLayer = [CALayer layer];
        _glowingHaloLayer.bounds = CGRectMake(0, 0, 100, 100);
        _glowingHaloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _glowingHaloLayer.contentsScale = [UIScreen mainScreen].scale;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAAnimationGroup *animationGroup = self.pulseAnimationGroup;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [_glowingHaloLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });
    }
    return _glowingHaloLayer;
}

- (UIImage*)haloImageWithRadius:(CGFloat)radius {
    NSString *key = [NSString stringWithFormat:@"%@-%.0f", self.annotationColor, radius];
    UIImage *ringImage = [[SVPulsingAnnotationView cachedRingImages] objectForKey:key];
    
    if(!ringImage) {
        CGFloat glowRadius = radius/6;
        CGFloat ringThickness = radius/24;
        CGPoint center = CGPointMake(glowRadius+radius, glowRadius+radius);
        CGRect imageBounds = CGRectMake(0, 0, center.x*2, center.y*2);
        CGRect ringFrame = CGRectMake(glowRadius, glowRadius, radius*2, radius*2);
        
        UIGraphicsBeginImageContextWithOptions(imageBounds.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIColor* ringColor = [UIColor whiteColor];
        [ringColor setFill];
        
        UIBezierPath *ringPath = [UIBezierPath bezierPathWithOvalInRect:ringFrame];
        [ringPath appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(ringFrame, ringThickness, ringThickness)]];
        ringPath.usesEvenOddFillRule = YES;
        
        for(float i=1.3; i>0.3; i-=0.18) {
            CGFloat blurRadius = MIN(1, i)*glowRadius;
            CGContextSetShadowWithColor(context, CGSizeZero, blurRadius, self.annotationColor.CGColor);
            [ringPath fill];
        }
        
        ringImage = UIGraphicsGetImageFromCurrentImageContext();
        [[SVPulsingAnnotationView cachedRingImages] setObject:ringImage forKey:key];

        UIGraphicsEndImageContext();
    }
    return ringImage;
}

- (UIImage*)dotAnnotationImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint origin = CGPointMake(0, 0);
    
    //// Color Declarations
    UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    CGFloat routeColorRGBA[4];
    [self.annotationColor getRed: &routeColorRGBA[0] green: &routeColorRGBA[1] blue: &routeColorRGBA[2] alpha: &routeColorRGBA[3]];
    
    UIColor* strokeColor = [UIColor colorWithRed: (routeColorRGBA[0] * 0.9) green: (routeColorRGBA[1] * 0.9) blue: (routeColorRGBA[2] * 0.9) alpha: (routeColorRGBA[3] * 0.9 + 0.1)];
    UIColor* outerShadowColor = [self.annotationColor colorWithAlphaComponent: 0.5];
    UIColor* transparentColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0];
    
    //// Gradient Declarations
    NSArray* glossGradientColors = [NSArray arrayWithObjects:
                                    (id)fillColor.CGColor,
                                    (id)[UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.5].CGColor,
                                    (id)transparentColor.CGColor, nil];
    CGFloat glossGradientLocations[] = {0, 0.49, 1};
    CGGradientRef glossGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)glossGradientColors, glossGradientLocations);
    
    //// Shadow Declarations
    UIColor* innerShadow = fillColor;
    CGSize innerShadowOffset = CGSizeMake(-1.1, -2.1);
    CGFloat innerShadowBlurRadius = 2;
    UIColor* outerShadow = outerShadowColor;
    CGSize outerShadowOffset = CGSizeMake(0.5, 0.5);
    CGFloat outerShadowBlurRadius = 1.5;
    
    //// drop shadow Drawing
    UIBezierPath* dropShadowPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, outerShadowOffset, outerShadowBlurRadius, outerShadow.CGColor);
    [strokeColor setFill];
    [dropShadowPath fill];
    CGContextRestoreGState(context);
    
    //// fill Drawing
    UIBezierPath* fillPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
    [self.annotationColor setFill];
    [fillPath fill];
    
    //// Group
    {
        CGContextSaveGState(context);
        CGContextSetAlpha(context, 0.5);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);
        CGContextBeginTransparencyLayer(context, NULL);
        
        //// Clip mask 3
        UIBezierPath* mask3Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
        [mask3Path addClip];
        
        
        //// bottom inner light Drawing
        UIBezierPath* bottomInnerLightPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+3, origin.y+3, 14, 14)];
        CGContextSaveGState(context);
        [bottomInnerLightPath addClip];
        CGContextDrawRadialGradient(context, glossGradient,
                                    CGPointMake(origin.x+10, origin.y+10), 0.54,
                                    CGPointMake(origin.x+10, origin.y+10), 5.93,
                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextRestoreGState(context);
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
    //// bottom circle inner light
    {
        CGContextSaveGState(context);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);
        CGContextBeginTransparencyLayer(context, NULL);
        
        //// Clip mask 4
        UIBezierPath* mask4Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
        [mask4Path addClip];
        
        
        //// bottom circle inner light 2 Drawing
        UIBezierPath* bottomCircleInnerLight2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x-1.5, origin.y-0.5, 16, 16)];
        [transparentColor setFill];
        [bottomCircleInnerLight2Path fill];
        
        ////// bottom circle inner light 2 Inner Shadow
        CGRect bottomCircleInnerLight2BorderRect = CGRectInset([bottomCircleInnerLight2Path bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
        bottomCircleInnerLight2BorderRect = CGRectOffset(bottomCircleInnerLight2BorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
        bottomCircleInnerLight2BorderRect = CGRectInset(CGRectUnion(bottomCircleInnerLight2BorderRect, [bottomCircleInnerLight2Path bounds]), -1, -1);
        
        UIBezierPath* bottomCircleInnerLight2NegativePath = [UIBezierPath bezierPathWithRect: bottomCircleInnerLight2BorderRect];
        [bottomCircleInnerLight2NegativePath appendPath: bottomCircleInnerLight2Path];
        bottomCircleInnerLight2NegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            CGFloat xOffset = innerShadowOffset.width + round(bottomCircleInnerLight2BorderRect.size.width);
            CGFloat yOffset = innerShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        innerShadowBlurRadius,
                                        innerShadow.CGColor);
            
            [bottomCircleInnerLight2Path addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(bottomCircleInnerLight2BorderRect.size.width), 0);
            [bottomCircleInnerLight2NegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [bottomCircleInnerLight2NegativePath fill];
        }
        CGContextRestoreGState(context);
        
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
    //// bottom circle inner light 3
    {
        CGContextSaveGState(context);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);
        CGContextBeginTransparencyLayer(context, NULL);
        
        //// Clip mask 2
        UIBezierPath* mask2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
        [mask2Path addClip];
        
        
        //// bottom circle inner light 4 Drawing
        UIBezierPath* bottomCircleInnerLight4Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x-1.5, origin.y-0.5, 16, 16)];
        [transparentColor setFill];
        [bottomCircleInnerLight4Path fill];
        
        ////// bottom circle inner light 4 Inner Shadow
        CGRect bottomCircleInnerLight4BorderRect = CGRectInset([bottomCircleInnerLight4Path bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
        bottomCircleInnerLight4BorderRect = CGRectOffset(bottomCircleInnerLight4BorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
        bottomCircleInnerLight4BorderRect = CGRectInset(CGRectUnion(bottomCircleInnerLight4BorderRect, [bottomCircleInnerLight4Path bounds]), -1, -1);
        
        UIBezierPath* bottomCircleInnerLight4NegativePath = [UIBezierPath bezierPathWithRect: bottomCircleInnerLight4BorderRect];
        [bottomCircleInnerLight4NegativePath appendPath: bottomCircleInnerLight4Path];
        bottomCircleInnerLight4NegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            CGFloat xOffset = innerShadowOffset.width + round(bottomCircleInnerLight4BorderRect.size.width);
            CGFloat yOffset = innerShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        innerShadowBlurRadius,
                                        innerShadow.CGColor);
            
            [bottomCircleInnerLight4Path addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(bottomCircleInnerLight4BorderRect.size.width), 0);
            [bottomCircleInnerLight4NegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [bottomCircleInnerLight4NegativePath fill];
        }
        CGContextRestoreGState(context);
        
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
    //// fill 2 Drawing
    
    
    //// glosses
    {
        CGContextSaveGState(context);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);
        CGContextBeginTransparencyLayer(context, NULL);
        
        //// Clip mask
        UIBezierPath* maskPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
        [maskPath addClip];
        
        
        //// white gloss glow 2 Drawing
        UIBezierPath* whiteGlossGlow2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+1.5, origin.y+0.5, 7.5, 7.5)];
        CGContextSaveGState(context);
        [whiteGlossGlow2Path addClip];
        CGContextDrawRadialGradient(context, glossGradient,
                                    CGPointMake(origin.x+5.25, origin.y+4.25), 0.68,
                                    CGPointMake(origin.x+5.25, origin.y+4.25), 2.68,
                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextRestoreGState(context);
        
        
        //// white gloss glow 1 Drawing
        UIBezierPath* whiteGlossGlow1Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+1.5, origin.y+0.5, 7.5, 7.5)];
        CGContextSaveGState(context);
        [whiteGlossGlow1Path addClip];
        CGContextDrawRadialGradient(context, glossGradient,
                                    CGPointMake(origin.x+5.25, origin.y+4.25), 0.68,
                                    CGPointMake(origin.x+5.25, origin.y+4.25), 1.93,
                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextRestoreGState(context);
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
    //// white gloss Drawing
    UIBezierPath* whiteGlossPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+2, origin.y+1, 6.5, 6.5)];
    CGContextSaveGState(context);
    [whiteGlossPath addClip];
    CGContextDrawRadialGradient(context, glossGradient,
                                CGPointMake(origin.x+5.25, origin.y+4.25), 0.5,
                                CGPointMake(origin.x+5.25, origin.y+4.25), 1.47,
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(context);
    
    
    //// stroke Drawing
    UIBezierPath* strokePath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(origin.x+0.5, origin.y+0.5, 14, 14)];
    [strokeColor setStroke];
    strokePath.lineWidth = 1;
    [strokePath stroke];
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //// Cleanup
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(colorSpace);
    
    return dotImage;
}

@end
