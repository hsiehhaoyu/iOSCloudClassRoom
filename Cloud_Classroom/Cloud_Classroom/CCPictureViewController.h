//
//  CCPictureViewController.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCPictureViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

-(void)presenterStatusUpdate;

-(void)downloadContentWithFileName:(NSString *)fileName;

@end
