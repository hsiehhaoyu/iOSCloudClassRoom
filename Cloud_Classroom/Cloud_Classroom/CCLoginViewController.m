//
//  CCLoginViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCLoginViewController.h"
#import "CCAppDelegate.h"
#import "CCConfiguration.h"
#import "CCMiscHelper.h"
#import "CCClassTableViewController.h"
#import "UIBarButtonItem+Image.h"
#import "CCSettingTableViewController.h"

@interface CCLoginViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *userIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong,atomic) CCMessageCenter *serverMC;



@end

@implementation CCLoginViewController

- (IBAction)loginButtonClicked:(UIButton *)sender {
    
    if([CCMiscHelper isStringEmpty:self.userIDTextField.text] ||
       [CCMiscHelper isStringEmpty:self.passwordTextField.text]){
    
        [CCMiscHelper showAlertWithTitle:@"Empty text field"
                              andMessage:@"Please input both User Name and Password."];
        return;
    
    }
    
    [self.serverMC loginWithUserID:self.userIDTextField.text
                       andPassword:self.passwordTextField.text
                     andDeviceType:IOS
                      onCompletion:^(SendMessageResult sentResult, NSString *status) {
                          
                          dispatch_async(dispatch_get_main_queue(), ^{
                              
                              
                              if(sentResult == SendMessageResultSucceeded){
                                  if([status isEqualToString:LOGGED_IN]){
                                  
                                      [self performSegueWithIdentifier:@"Login" sender:self];
                                  
                                  }else{
                              
                                      NSLog(@"Login faild. status: %@", status);
                                      
                                      NSString *failedReason;
                                      
                                      if([status isEqualToString:DUPLICATE]){
                                      
                                          failedReason = @"You have another login session on another device. Please logout it first.";
                                          
                                      }else if([status isEqualToString:LOGIN_FAIL] || [status isEqualToString:INVALID_USER]){
                                          
                                          failedReason = @"Incorrect user name or password.";
                                      
                                      }else{
                                      
                                          failedReason = @"Unknown reason";
                                      }
                    
                                      [CCMiscHelper showAlertWithTitle:@"Login Failed" andMessage:failedReason];
                                      
                                  }
                              }else{
                                  
                                  NSLog(@"Conneciotn failed, send result code: %d", (int)sentResult);
                                  
                                  [CCMiscHelper showAlertWithTitle:@"Connection failed"
                                                        andMessage:@"Couldn't connect to server. Please check your network availability and server setting."];
                                  
                              }
                              
                              
                          });
                      }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"Login"]){
        if([segue.destinationViewController isKindOfClass:[CCClassTableViewController class]]){
            
            CCClassTableViewController *classTVC = (CCClassTableViewController *)segue.destinationViewController;
            classTVC.userID = self.userIDTextField.text;
            
        }
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if([identifier isEqualToString:@"Login"]){
        if (sender == self) {
            return YES;
        }
    }else if([identifier isEqualToString:@"Settings"]){
        return YES;
    }
    return NO;
}

//Let keyboard disappear when user click enter
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

//Used to resign keyboard when touch out side of textFields
//Reference: http://stackoverflow.com/questions/5306240/iphone-dismiss-keyboard-when-touching-outside-of-textfield
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}

//handle received messages that is NOT a response for a request we sent
-(void)handleReceivedRequestWithCommand:(NSString *)command andArguments:(NSArray *)arguments{

    NSLog(@"handleReceivedRequestWithCommand called");
    
    if([command isEqualToString:CHANGE_PRESENT_TOKEN_REQ]){
    
    }else if([command isEqualToString:PUSH_CONTENT_NOTIFY]){
    
    }else{
        NSLog(@"Unknow message received in handleReceivedRequestWithCommand!");
        return;
    }
}

//Don't call this function directly. Call logout function in serverMC, since that function
//will also handle cookie issue
-(void)handleLogoutForControllers{

    NSLog(@"handleLogoutForControllers called");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //if current view is not login page, pop to login page
        if(![[CCMiscHelper getTopViewController] isMemberOfClass:[CCLoginViewController class]] ){
            
            [self dismissViewControllerAnimated:YES completion:^{
            
                [CCMiscHelper showAlertWithTitle:@"Logged out"
                                      andMessage:@"You have been logged out."];
                
            }];
            
        }
        
    });
}

-(void)setupServerMC{

    //init the CCMessageCenter in AppDelegate(not connect now)
    self.serverMC = [[CCMessageCenter alloc] init];
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.serverMessageCenter = self.serverMC;
    
    //set call back blocks in the CCMessageCenter
    //I use this controller as control center since
    //this will not be terminate unless app closed
    //(p.s. may change to delegate in the future)
    __weak CCLoginViewController *weakSelf = self;
    
    self.serverMC.logoutBlock = ^(){
        [weakSelf handleLogoutForControllers];
    };

}



-(void)viewWillAppear:(BOOL)animated{
    
    //for any reason that back to login page, try to logout first
    //so that can be recovered from error states if any
    [self.serverMC logoutAndTriggerLogoutBlock:NO onCompletion:nil];
    
    //not sure whether the inputStream/outputStream will be
    //automactically removed from runloop after no reference
    //count or not, so we still do this manually first
    [self.serverMC closeServerConnection];
    
    //we do this every time login view show up
    //so that the system can recover from unexpected
    //error states (if any)
    [self setupServerMC];
}


-(void)viewDidLoad{
    
    [super viewDidLoad];
    
    
    
    self.userIDTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    
    
}


@end
