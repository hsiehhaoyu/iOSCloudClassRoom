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

-(void)sendMessageWithArgs:(NSArray *)args{
    
    
    int i=4;
    for(; i>0; i--){
        if(![args[i]  isEqual: @""])
        {
            break;
        }
    }
    
    NSMutableArray *mutaArgs = [[NSMutableArray alloc] init];
    for(int j=1; j<=i; j++){
        [mutaArgs addObject:args[j]];
    }
        
        
    [self.serverCH sendMessageToServerWithCommand:args[0]
                                     andArguments:[mutaArgs copy]
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
            NSLog(@"Logged in faild, code: %ld", result);
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
    }
    
    return self;
}



@end
