//
//  AppDelegate.m
//  EMControllerManagerExample
//
//  Created by 缪和光 on 14-7-14.
//  Copyright (c) 2014年 EastMoney. All rights reserved.
//

#import "AppDelegate.h"
#import "EMControllerManager.h"
#import "Test4ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // You can use two kinds of config files, namely plist and JSON.
    EMControllerManager *cm = [EMControllerManager sharedInstance];
//    NSString *path = [[NSBundle mainBundle]pathForResource:@"ViewControllerConfigPlist" ofType:@"plist"];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"ViewControllerConfig" ofType:@"json"];
    NSError *e = nil;
//    [cm loadConfigFileOfPath:path fileType:EMControllerManagerConfigFileTypePlist error:&e];
    [cm loadConfigFileOfPath:path fileType:EMControllerManagerConfigFileTypeJSON error:&e];
    if (e) {
        NSLog(@"%@",[e localizedDescription]);
    }
    

    // Initialize properties using two methods
    UIViewController *vc = [cm createViewControllerInstanceNamed:@"Test1" withPropertyValues:@{@"color":[UIColor redColor],@"number":@(1)}];
    UIViewController *vc2 = [cm createViewControllerInstanceNamed:@"Test2" withPropertyValues:@{@"color":[UIColor blueColor],@"number":@(2)}];
    
    
    // You can also add extra config infomation
    [cm addViewControllerConfigWithBlock:^(NSMutableDictionary *extraNameClassMapping) {
        [extraNameClassMapping setObject:@"Test3ViewController" forKey:@"Test3"];
        
        // This is a better practice, because it can be treated properly when you rename view controllers with Xcode's refactor functionality.
        // You can do this in one paticular place of your program, e.g. application:didFinishLaunchingWithOptions:
        [extraNameClassMapping setObject:NSStringFromClass([Test4ViewController class]) forKey:@"Test4"];
    }];
    
    UIViewController *vc3 = [cm createViewControllerInstanceNamed:@"Test3" withPropertyValues:@{@"dummyInfo":@"aaaa"}];
    UIViewController *vc4 = [cm createViewControllerInstanceNamed:@"Test4" withPropertyValues:@{@"dummyInfo":@"bbbb"}];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
