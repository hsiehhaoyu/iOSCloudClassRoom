//
//  CCLoginViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCLoginViewController.h"
#import "CCLoginModel.h"

@interface CCLoginViewController ()

@property (strong,nonatomic) CCLoginModel *loginModel;

@property (weak, nonatomic) IBOutlet UITextField *userIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation CCLoginViewController

- (IBAction)loginButtonClicked:(UIButton *)sender {
    [self.loginModel loginWithUserID:self.userIDTextField.text
                         andPassword:self.passwordTextField.text
                        onCompletion:nil];
}

- (IBAction)createButtonClicked:(UIButton *)sender {
    
    [self.loginModel sendMessage];
}


-(void)viewDidLoad{
    
    [super viewDidLoad];
    
    self.loginModel = [[CCLoginModel alloc] init];

}

@end
