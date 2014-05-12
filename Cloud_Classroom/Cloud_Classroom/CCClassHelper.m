//
//  CCClassHelper.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCClassHelper.h"
#import "CCClassTabBarController.h"
#import "UIBarButtonItem+Image.h"

@implementation CCClassHelper

+(NSArray *)getConstClassRightBarButtonItemsWithSender:(UIViewController *)sender isPresenter:(BOOL)isPresenter{

    //use this instead of @selector so that compiler won't give warning
    SEL getPresentTokenSEL = NSSelectorFromString(@"getPresentToken");
    SEL pushContentSEL = NSSelectorFromString(@"pushContent");
    SEL getLatestContentSEL = NSSelectorFromString(@"getLatestContent");
    
    if ([sender respondsToSelector:getPresentTokenSEL] &&
        [sender respondsToSelector:pushContentSEL] &&
        [sender respondsToSelector:getLatestContentSEL]){
        
        UIBarButtonItem *getPresentTokenBarButton = [[UIBarButtonItem alloc]
                                                     initWithImageOnly:[UIImage imageNamed:@"present24"]
                                                     target:sender
                                                     action:getPresentTokenSEL];
        
        UIBarButtonItem *pushContentBarButton = [[UIBarButtonItem alloc]
                                                 initWithImageOnly:[UIImage imageNamed:@"upload24"]
                                                 target:sender
                                                 action:pushContentSEL];
        
        UIBarButtonItem *getLatestContentBarButton = [[UIBarButtonItem alloc]
                                                      initWithImageOnly:[UIImage imageNamed:@"refresh24"]
                                                      target:sender
                                                      action:getLatestContentSEL];
        
        if(isPresenter){
            return @[getLatestContentBarButton,pushContentBarButton];
        }else{
            return @[getLatestContentBarButton,getPresentTokenBarButton];
        }
    
    }else{
        return @[];
    }
}

//Get const left bar button items: Logout, Back to class list, and Quit class
+(NSArray *)getConstClassLeftBarButtonItemsWithSender:(UIViewController *)sender{
    
//    UIBarButtonItem *logoutBarButton = [[UIBarButtonItem alloc]
//                                        initWithImageOnly:[UIImage imageNamed:@"logout24"]
//                                        target:(CCClassTabBarController *)(sender.tabBarController)
//                                        action:@selector(logout)];
//    
    
    
    
    UIBarButtonItem *backToClassListBarButton = [[UIBarButtonItem alloc]
                                                 initWithImageOnly:[UIImage imageNamed:@"classlist24"]
                                                 target:(CCClassTabBarController *)(sender.tabBarController)
                                                 action:@selector(backToClassList)];
    
    UIBarButtonItem *quitClassBarButton = [[UIBarButtonItem alloc]
                                           initWithImageOnly:[UIImage imageNamed:@"quit24"]
                                           target:(CCClassTabBarController *)(sender.tabBarController)
                                           action:@selector(quitClass)];
    
    //return @[logoutBarButton, quitClassBarButton, backToClassListBarButton];
    
    //for now don't put logout icon in in-class views
    return @[quitClassBarButton, backToClassListBarButton];
    
}

@end
