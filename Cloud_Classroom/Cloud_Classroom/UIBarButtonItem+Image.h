//
//  UIBarButtonItem+Image.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/5/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//
//Used to create a bar button item with touch event
//Reference: http://stackoverflow.com/questions/13122817/ios-navigation-bar-with-images-for-buttons


#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Image)

- (id)initWithImageOnly:(UIImage*)image target:(id)target action:(SEL)action;

@end
