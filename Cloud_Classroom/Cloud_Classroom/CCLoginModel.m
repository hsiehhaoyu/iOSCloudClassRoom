//
//  CCLoginModel.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCLoginModel.h"
#import "CCCommunicationHandler.h"
#import "CCAppDelegate.h"
#import "CCConfiguration.h"

@interface CCLoginModel ()

@property (strong,atomic) CCCommunicationHandler *serverCH;

@end

@implementation CCLoginModel

-(void)sendMessage{
    
    self.serverCH.receivedMessageBlock = ^(NSArray *receivedMessage){
        
        NSString *string = @"";
        
        for(NSString *line in receivedMessage){
            string = [NSString stringWithFormat:@"%@%@\n", string, line];
        }
        
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Receive msg"
                                                       message:string
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [alert show];
        alert= nil;
    
    };
    
    [self.serverCH sendMessageToServerWithCommand:CREATE_CLASS_REQ
                                     andArguments:@[@"arg1",@"333"]
                                     onCompletion:^(SendMessageResult result) {
        NSLog(@"Msg sent");
    }];

}


-(void)loginWithUserID:(NSString *)userID andPassword:(NSString *)password onCompletion:(void (^)(LoginResult))completion{
    [self.serverCH loginWithUserID:userID andPassword:password onCompletion:^(LoginResult result) {
        UIAlertView *alert;
        if(result == LoginResultSucceeded){
            alert= [[UIAlertView alloc] initWithTitle:@"Receive msg"
                                                           message:@"Login succeeded"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        }else{
            alert= [[UIAlertView alloc] initWithTitle:@"Receive msg"
                                                           message:@"Login failed"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        }
        
        [alert show];
        alert= nil;
    }];
}

-(instancetype)init{

    self = [super init];
    
    if(self){
        //init the handler in app delegate, but not connect now
        self.serverCH = [[CCCommunicationHandler alloc] initWithServerURL:[NSURL URLWithString:SERVER_URL_STRING]
                                                                  andPort:SERVER_PORT_NUM];
        CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.serverCommunicationHandler = self.serverCH;
    }
    
    return self;
}



@end
