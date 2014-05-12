//
//  UIBarButtonItem+Image.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/5/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "UIBarButtonItem+Image.h"

@implementation UIBarButtonItem (Image)

//Reference: http://stackoverflow.com/questions/13122817/ios-navigation-bar-with-images-for-buttons
- (id)initWithImageOnly:(UIImage *)image target:(id)target action:(SEL)action {
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    frame = CGRectInset(frame, -5, 0);
    
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [self initWithCustomView:button];
}

@end
