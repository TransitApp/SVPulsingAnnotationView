//
//  SPRealTimeVehicleAnnotationView.m
//  Transit
//
//  Created by Sam Vermette on 01.03.13.
//
//

#import "SVPulsingAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

@interface SVPulsingAnnotationView ()

@property (nonatomic, strong) CALayer *dotLayer;
@property (nonatomic, strong) CALayer *haloLayer;
@property (nonatomic, readwrite) CGSize dotAnnotationSize;

@end

@implementation SVPulsingAnnotationView

@synthesize annotation = _annotation;

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.bounds = CGRectMake(0, 0, 23, 23);
        self.dotAnnotationSize = CGSizeMake(16, 16);
        self.pulseAnimationDuration = 1;
        self.delayBetweenPulseCycles = 1;
    }
    return self;
}

- (void)rebuildLayers {
    [_haloLayer removeFromSuperlayer];
    _haloLayer = nil;
    
    [_dotLayer removeFromSuperlayer];
    _dotLayer = nil;
    
    [self.layer addSublayer:self.haloLayer];
    [self.layer addSublayer:self.dotLayer];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(newSuperview)
        [self rebuildLayers];
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

#pragma mark - Getters

- (CALayer *)dotLayer {
    if(!_dotLayer) {
        _dotLayer = [CALayer layer];
        _dotLayer.bounds = self.bounds;
        _dotLayer.contents = (id)[self dotAnnotationImage].CGImage;
        _dotLayer.position = CGPointMake(self.bounds.size.width/2+0.5, self.bounds.size.height/2+0.5); // 0.5 is for drop shadow
        _dotLayer.contentsGravity = kCAGravityCenter;
        _dotLayer.contentsScale = [UIScreen mainScreen].scale;
    }
    return _dotLayer;
}

- (CALayer *)haloLayer {
    if(!_haloLayer) {
        _haloLayer = [CALayer layer];
        _haloLayer.bounds = CGRectMake(0, 0, 100, 100);
        _haloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _haloLayer.contentsScale = [UIScreen mainScreen].scale;

        CAMediaTimingFunction *linear = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        CAMediaTimingFunction *easeIn = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        CAMediaTimingFunction *easeOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = self.pulseAnimationDuration + self.delayBetweenPulseCycles;
        animationGroup.repeatCount = INFINITY;
        animationGroup.timingFunction = linear;
        
        CAKeyframeAnimation *imageAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        imageAnimation.values = @[
                                  (id)[[self haloImageWithRadius:20] CGImage],
                                  (id)[[self haloImageWithRadius:35] CGImage],
                                  (id)[[self haloImageWithRadius:50] CGImage]
                                  ];
        imageAnimation.duration = self.pulseAnimationDuration;
        imageAnimation.calculationMode = kCAAnimationDiscrete;
        
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
        pulseAnimation.fromValue = @0.0;
        pulseAnimation.toValue = @1.0;
        pulseAnimation.duration = self.pulseAnimationDuration;
        pulseAnimation.timingFunction = easeOut;
        
        CABasicAnimation *fadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOutAnim.fromValue = @1.0;
        fadeOutAnim.toValue = @0.0;
        fadeOutAnim.duration = self.pulseAnimationDuration;
        fadeOutAnim.timingFunction = easeIn;
        fadeOutAnim.removedOnCompletion = NO;
        fadeOutAnim.fillMode = kCAFillModeForwards;
        
        animationGroup.animations = @[imageAnimation, pulseAnimation, fadeOutAnim];
        
        [_haloLayer addAnimation:animationGroup forKey:@"pulse"];
    }
    return _haloLayer;
}


#pragma mark - CG Drawing

- (UIImage*)haloImageWithRadius:(CGFloat)radius {
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
    
    UIImage *ringImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return ringImage;
}


- (UIImage*)dotAnnotationImage {
    UIGraphicsBeginImageContextWithOptions(self.dotAnnotationSize, NO, 0);

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
