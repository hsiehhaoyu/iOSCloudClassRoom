//
//  CCLoginViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCLoginViewController.h"
#import "CCLoginModel.h"

@interface CCLoginViewController () <UITextFieldDelegate>

@property (strong,nonatomic) CCLoginModel *model;

@property (weak, nonatomic) IBOutlet UITextField *userIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UITextField *arg1TextField;

@property (weak, nonatomic) IBOutlet UITextField *arg2TextField;

@property (weak, nonatomic) IBOutlet UITextField *arg3TextField;

@property (weak, nonatomic) IBOutlet UITextField *arg4TextField;

@property (weak, nonatomic) IBOutlet UITextField *arg5TextField;

@end

@implementation CCLoginViewController

- (IBAction)loginButtonClicked:(UIButton *)sender {
    [self.model loginWithUserID:self.userIDTextField.text
                         andPassword:self.passwordTextField.text
                        onCompletion:nil];
}

- (IBAction)createButtonClicked:(UIButton *)sender {
    
    [self.model sendMessageWithArgs:@[self.arg1TextField.text,
                                      self.arg2TextField.text,
                                      self.arg3TextField.text,
                                      self.arg4TextField.text,
                                      self.arg5TextField.text]];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)viewDidLoad{
    
    [super viewDidLoad];
    
    self.model = [[CCLoginModel alloc] init];
 
    self.arg1TextField.delegate = self;
    self.arg2TextField.delegate = self;
    self.arg3TextField.delegate = self;
    self.arg4TextField.delegate = self;
    self.arg5TextField.delegate = self;
}


@end
