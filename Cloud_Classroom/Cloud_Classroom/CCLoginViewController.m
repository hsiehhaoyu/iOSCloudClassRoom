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
#import "CCtestViewController.h"

@interface CCLoginViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *userIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong,atomic) CCMessageCenter *serverMC;

@end

@implementation CCLoginViewController

- (IBAction)loginButtonClicked:(UIButton *)sender {
    
    [self.serverMC loginWithUserID:self.userIDTextField.text
                       andPassword:self.passwordTextField.text
                     andDeviceType:IOS
                      onCompletion:^(SendMessageResult sentResult, NSString *status) {
                          
                          dispatch_async(dispatch_get_main_queue(), ^{
                              
                              UIAlertView *alert;
                              if(sentResult == SendMessageResultSucceeded){
                                  if([status isEqualToString:LOGGED_IN] || [status isEqualToString:DUPLICATE]){
                                  
                                      [self performSegueWithIdentifier:@"Login" sender:self];
                                  
                                  }else{
                              
                                      NSLog(@"Login faild, incorrect ID or password. status: %@", status);
                                      alert= [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                                        message:status
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                                      
                                  }
                              }else{
                                  
                                  NSLog(@"Logged in faild, code: %ld", sentResult);
                                  alert= [[UIAlertView alloc] initWithTitle:@"Login Message Sent Failed"
                                                                    message:@"Please check the Internet connection"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                              }
                              
                              [alert show];
                              alert= nil;
                          });
                      }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"Login"]){
        if([segue.destinationViewController isKindOfClass:[CCtestViewController class]]){
            
            CCtestViewController *testVC = (CCtestViewController *)segue.destinationViewController;
            //Whatever to do
            
        }
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if([identifier isEqualToString:@"Login"]){
        if (sender == self) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    
    return YES;
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

-(void)handleLogoutForControllers{

    NSLog(@"handleLogoutForControllers called");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //jump back to login page?
    });
}

-(void)viewDidLoad{
    
    [super viewDidLoad];
    
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
    
    self.serverMC.receivedRequestBlock=^(NSString *command, NSArray *arguments){
        [weakSelf handleReceivedRequestWithCommand:command andArguments:arguments];
    };
 
}


@end
