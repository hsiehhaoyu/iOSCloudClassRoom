//
//  CCClassTableViewController.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCClassTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>


//current logged in user name
@property (strong,nonatomic) NSString *userID;



@end
