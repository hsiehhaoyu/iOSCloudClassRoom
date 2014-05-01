//
//  CCMiscHelper.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCMiscHelper.h"

@implementation CCMiscHelper


+(void)showConnectionFailedAlertWithSendResult:(SendMessageResult)sentResult{
    
    NSLog(@"Conneciotn failed, send result code: %ld", sentResult);
    
    [CCMiscHelper showAlertWithTitle:@"Connection failed"
                          andMessage:@"Couldn't connect to server, please check your network availability."];
    
}

//used to show alerts that don't care about feedback
+(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{

    UIAlertView *alert= [[UIAlertView alloc]
                         initWithTitle:title
                         message:message
                         delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles: nil];
    [alert show];
    alert= nil;
    
}

//get current displaying view controller
//Reference: http://www.iosrocketsurgery.com/2013/07/get-current-viewcontroller-in-ios.html#.U1jDoeZdURY
+(UIViewController*)getTopViewController{
    
    UIViewController *topVC = ([UIApplication sharedApplication]).keyWindow.rootViewController;
    
    //recursive, since there might be various layers
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    return topVC;
}

//delete whitespace chars on both side and check
+(BOOL)isStringEmpty:(NSString *)string{
    return ([string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0);
}

@end
