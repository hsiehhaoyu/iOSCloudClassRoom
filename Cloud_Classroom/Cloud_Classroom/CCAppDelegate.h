//
//  CCAppDelegate.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/8.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCMessageCenter.h"

@interface CCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, atomic) CCMessageCenter *serverMessageCenter;

@property (strong, nonatomic) void (^receivedPushNotificationBlock)(NSDictionary *receivedMessage);

@property (strong, nonatomic) NSString *deviceToken;

@end
