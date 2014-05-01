//
//  CCMiscHelper.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMessage.h"

@interface CCMiscHelper : NSObject

+(void)showConnectionFailedAlertWithSendResult:(SendMessageResult)sentResult;

+(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

+(UIViewController*)getTopViewController;

+(BOOL)isStringEmpty:(NSString *)string;

@end
