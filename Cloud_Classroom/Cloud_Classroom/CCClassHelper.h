//
//  CCClassHelper.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCClassHelper : NSObject

+(NSArray *)getConstClassLeftBarButtonItemsWithSender:(UIViewController *)sender;

+(NSArray *)getConstClassRightBarButtonItemsWithSender:(UIViewController *)sender
                                           isPresenter:(BOOL)isPresenter;

@end
