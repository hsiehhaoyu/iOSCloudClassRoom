//
//  CCClassTabBarController.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCClass.h"
#import "CCS3ServerManager.h"
#import "CCMessageCenter.h"

@interface CCClassTabBarController : UITabBarController

@property (strong,nonatomic) NSString *userID;
//Note: cannot call it "class", or it will fail silently when you use statement like [CCTabBar... class]
@property (strong,nonatomic) CCClass *classOnGoing;

@property (strong, atomic) CCS3ServerManager *s3SM;

@property (nonatomic) BOOL isPresenter;

@property (strong,atomic) CCMessageCenter *serverMC;

@property (strong,atomic) NSString *latestImageContentID;

@property (strong,atomic) NSString *latestTextContentID;

-(void)classDismissed;

-(void)logout;

-(void)backToClassList;

-(void)quitClass;

-(void)getPresentTokenAndOnCompletion:(void (^)(BOOL isPresenter))completion;

-(void)kickedOut;

-(void)pushContentWithFileName:(NSString *)fileName andType:(NSString *)fileType;

-(void)checkLatestContent;

@end
