//
//  CCAppDelegate.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/8.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCAppDelegate.h"

@implementation CCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //===== for push notification =====
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
    
    //clear badge number if any
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    //=================================
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


#pragma below_is_for_push_notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
    NSString *deviceTokenString = [NSString stringWithFormat:@"%@", deviceToken];
    NSLog(@"Raw device token string: %@", deviceTokenString);
    

    deviceTokenString = [deviceTokenString substringFromIndex:1];
    deviceTokenString = [deviceTokenString substringToIndex:deviceTokenString.length-1];
    
    self.deviceToken = [deviceTokenString stringByReplacingOccurrencesOfString:@" "
                                                                    withString:@""];
    
    NSLog(@"Processed device token: %@", self.deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Remote notification error:%@", [error localizedDescription]);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	NSLog(@"Received notification: %@", userInfo);
    if(self.receivedPushNotificationBlock){
        self.receivedPushNotificationBlock(userInfo);
    }
    
    //clear badge number
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	
}

@end
