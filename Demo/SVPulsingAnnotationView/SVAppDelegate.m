//
//  SVAppDelegate.m
//  SVPulsingAnnotationView
//
//  Created by Sam Vermette on 03.03.13.
//  Copyright (c) 2013 Sam Vermette. All rights reserved.
//

#import "SVAppDelegate.h"

#import "SVViewController.h"

@implementation SVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[SVViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
