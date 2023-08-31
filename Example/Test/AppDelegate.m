//
//  AppDelegate.m
//  Test
//
//  Created by 王碧野 on 2022/9/6.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <YHRouter/YHRouter.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    BOOL result = [[YHRouter sharedInstance] application:application willFinishLaunchingWithOptions:launchOptions];
    return result;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ViewController *vc = [[ViewController alloc] init];
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = navc;
    [YHRouter.sharedInstance setupTruthCustomRootVC:vc];
    [self.window makeKeyAndVisible];
    return YES;
}


@end
