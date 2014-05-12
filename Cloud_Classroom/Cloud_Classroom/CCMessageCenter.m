//
//  CCMessageCenter.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/18.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCMessageCenter.h"
#import "CCCommunicationHandler.h"
#import "CCConfiguration.h"
#import "CCClass.h"
#import "CCAppDelegate.h"


@interface CCMessageCenter ()

//Will be nil if not logged in
@property (strong,atomic) NSString *cookieID;

//Blocks
//@property (strong,atomic) void (^completionBlockOfLogin)(LoginResult);

@property (strong,atomic) CCCommunicationHandler *serverCH;

//Used to store sent messages so that it can be retreived when receiving corresponding response
@property (strong,atomic) NSMutableArray *sentMessages; //of CCMessages

//@property (strong,atomic) NSString *tokenOfAPN;

#ifdef USE_ALERT_BLOCKING
//Used to block user interface if need to wait for response
@property (strong,atomic) UIAlertView *blockingAlert;
@property (strong,atomic) CCMessage *blockingMessage;
#endif

#ifdef USE_PUSH_NOTIFICATION_RELOGIN
@property (strong,nonatomic) NSString *userID;
@property (strong,nonatomic) NSString *password;
#endif

@end

@implementation CCMessageCenter

-(void)processReadyToSendMessage:(CCMessage *)message expectAResponse:(BOOL)hasResponse{
    
    if(!message){
        NSLog(@"Got a nil message in processReadyToSend, action abort");
        return;
    }
    
#ifdef USE_PUSH_NOTIFICATION_RELOGIN
    if(!self.serverCH.isConnectedToServer){
        if(![message.command isEqualToString:LOGIN_REQ] &&
           ![message.command isEqualToString:LOGOUT_REQ]){
            
            [self loginWithUserID:self.userID
                      andPassword:self.password
                    andDeviceType:IOS
                     onCompletion:^(SendMessageResult sentResult,
                                    NSString *status) {
                         
                    
                         //dispatch_async(dispatch_get_main_queue(), ^{
                             
                             
                             if(sentResult == SendMessageResultSucceeded){
                                 if([status isEqualToString:LOGGED_IN]){
                                     
                                     NSLog(@"Logged in before sending message");
                                     
                                 }else{
                                     
                                     //NSLog(@"Login faild while trying to . status: %@", status);
                                     
                                     NSString *failedReason;
                                     
                                     if([status isEqualToString:DUPLICATE]){
                                         
                                         failedReason = @"You have another login session on another device. Please logout it first.";
                                         
                                     }else if([status isEqualToString:LOGIN_FAIL] || [status isEqualToString:INVALID_USER]){
                                         
                                         failedReason = @"Incorrect user name or password.";
                                         
                                     }else{
                                         
                                         failedReason = @"Unknown reason";
                                     }
                                     
                                     NSLog(@"Login Failed before sending message, reason: %@", failedReason);
                                     
                                 }
                             }else{
                                 
                                 NSLog(@"Conneciotn failed before login for sending message, send result code: %d", (int)sentResult);
                                 
                             }
                             
                             
                        // });
                         
                     }];
        
        }
    }
#endif
    
    //save it if there should be a response come from server
    if(hasResponse){
        [self.sentMessages addObject:message];
        [self removeMessage:message fromSentMessagesAfter:DEFAULT_SENT_MESSAGES_TIMEOUT];
#ifdef USE_ALERT_BLOCKING
        self.blockingAlert= [[UIAlertView alloc]
                             initWithTitle:nil
                             message:@"Waiting for response ..."
                             delegate:self
                             cancelButtonTitle:@"Cancel"
                             otherButtonTitles: nil];
        self.blockingAlert.tag = 1;
        [self.blockingAlert show];
        self.blockingMessage = message;
#endif
    }
    
    //Note: No need and cannot put into dispatch_async here.
    //I have handle sending and receiving in different thread
    //in CCTCPConnction.
    //The reason why cannot dispatch_async should put there
    //is because it's like a queue. dispatch a block into
    //that thread, after all block have been executed, that
    //thread will be terminated. However in TCPConnection there
    //are runLoop that the thread need to be exist, and will
    //use the same thread as runloop to call the stream:handleEvent.
    //Therefore, my strategy is that I put the streams in the main
    //thread, and whenever receive event occurs or want to send
    //data, dispatch to another thread.
    //Reference:
    //http://stackoverflow.com/questions/7759688/objective-c-issues-with-threading-and-streams
    //https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Streams/Articles/WritingOutputStreams.html
    //https://developer.apple.com/library/ios/documentation/cocoa/reference/NSStreamDelegate_Protocol/Reference/Reference.html
    [self.serverCH sendToServerWithMessage:message];
    
}

#ifdef USE_ALERT_BLOCKING
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1){ //user clicked cancel for a request waiting for response
        if(buttonIndex == 0){
            NSLog(@"User cancelled the request");
            [self removeMessageFromSentMessages:self.blockingMessage];
            self.blockingAlert = nil;
            self.blockingMessage = nil;

    #ifdef USE_PUSH_NOTIFICATION
            if(self.sentMessages.count == 0 && self.serverCH.isQueueEmpty)
                [self closeServerConnection];
    #endif
        }
    }
}
#endif

//remove message after certain time
//Reference: http://stackoverflow.com/questions/4139219/how-do-you-trigger-a-block-after-a-delay-like-performselectorwithobjectafter
-(void)removeMessage:(CCMessage *)message fromSentMessagesAfter:(NSInteger)delaySeconds{
    
    __weak CCMessageCenter *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC),dispatch_get_main_queue(), ^{
        if(weakSelf){
            if([weakSelf isMessageInSentMessages:message]){
                [weakSelf removeMessageFromSentMessages:message];
                
#ifdef USE_ALERT_BLOCKING
                if([weakSelf.blockingMessage isEqual:message]){
                    [weakSelf dismissBlockingAlert];
                }
#endif
                
                if(message.sendCompletionBlock)
                    message.sendCompletionBlock(SendMessageResultTimeOut);
                
                //may or may not in its queue
                if(weakSelf.serverCH)
                    [weakSelf.serverCH removeMessageFromQueue:message];
                
                NSLog(@"Message timeout, removed from sentMessages. Command: %@", message.command);
                
#ifdef USE_PUSH_NOTIFICATION
                if(weakSelf.sentMessages.count == 0 && weakSelf.serverCH.isQueueEmpty)
                    [weakSelf closeServerConnection];
#endif
            }
        }
    });
}

-(void)removeMessageFromSentMessages:(CCMessage *)message{
    [self.sentMessages removeObject:message];
}

-(BOOL)isMessageInSentMessages:(CCMessage *)message{
    for(CCMessage *msg in self.sentMessages){
    
        if([msg isEqual:message])
            return YES;
    
    }
    
    return NO;
}

/*
 * Will logout first if already logged in
 * status in completion will be nil if sent failed for any reason
 */
-(void)loginWithUserID:(NSString *)userID
           andPassword:(NSString *)password
         andDeviceType:(NSString *)deviceType
          onCompletion:(void (^)(SendMessageResult, NSString *))completion{
    
    if(!completion || !userID || !password || !deviceType){
        //login is the most important action, so can not
        //tolerate any mistake or error state, therefore
        //use raise exception. In other operation, I
        //prefer to use NSLog to show what happend instead
        //so that could be recovered from error state (hopefully)
        //if encountered (though it shouldn't)
        [NSException raise:NSInternalInconsistencyException
                    format:@"Parameters in login function can't be nil!"];
        return;
    }
    
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *tokenOfAPN;
    
    if(!appDelegate.deviceToken){
        NSLog(@"token Of APN is unset. Will set it to empty string now");
        tokenOfAPN = @"";
    }else{
        tokenOfAPN = appDelegate.deviceToken;
    }
    
    if(self.isLoggedIn){
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:LOGIN_REQ
                          andArguments:@[userID, password, deviceType, tokenOfAPN]
                          andSendCompletionBlock:^(SendMessageResult result) {
                              
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send login message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              //p.s. we don't use 'role' info, which is arg[2], for now
                              
                              if([command isEqualToString:LOGIN_RES]){
                                  
                                  //logged in or not
                                  if([arguments[0] isEqualToString:LOGGED_IN]){
                                      
                                      self.cookieID = arguments[1];
                                      
#ifdef USE_PUSH_NOTIFICATION_RELOGIN
                                      self.userID = userID;
                                      self.password = password;
#endif
                                  }else{
                                      self.cookieID = nil; //May not necessary, but in case
                                  }
                                  
                                  completion(SendMessageResultSucceeded, arguments[0]);
                        
                              }else{
                                  NSLog(@"Error! Invoked incorrect sent message for LOGIN_REQ, command: %@", command);
                              }
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
}

//logout (will connect to server to logout if not connected)
//we can ignore the response msg from server, since that doesn't
//affect the result in our case
//Therefore completion can be nil here
//This can be called even if you're not logged in. Perfectly legal.
//triggerLogoutBlock indicate whether you want to execute the
//block which assigned to logoutBlock, which is generally a block
//controlling logout logic in ViewController. Therefore, if this
//is called from ViewController, this value should be NO (or might
//trigger recursive call if you call this in View Did Appear in
//Login Page. Otherwise, should be YES if is called
//inside this module.
-(void)logoutAndTriggerLogoutBlock:(BOOL)triggerLogoutBlock onCompletion:(void (^)(SendMessageResult, NSString *))completion{
    
    if(!self.isLoggedIn){
        NSLog(@"Not logged in while trying to logout");
    }else{
        
        CCMessage *message = [[CCMessage alloc]
                              initWithCommand:LOGOUT_REQ
                              andArguments:@[self.cookieID]
                              andSendCompletionBlock:^(SendMessageResult result) {
                                  if (result != SendMessageResultSucceeded) {
                                      
                                      NSLog(@"try to send logout message failed, code: %d", (int)result);
                                      if(completion)
                                          completion(result, nil);
                                      
                                  }
                                  
                                  //For success case, no need to do anything now, until server
                                  //send response back
            
                                  //Actually, we don't really care whether it sent successfully or not
                              }
                              andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                                  if(![command isEqualToString:LOGOUT_RES]){
                                      NSLog(@"Error! Invoked incorrect sent message for LOGOUT_REQ, command: %@", command);
                                  }else{
                                      
                                      //Not necessary to do anything here
                                      if(completion)
                                          completion(SendMessageResultSucceeded, arguments[0]);
                                  }
                                  
                              }];
        
        [self processReadyToSendMessage:message expectAResponse:YES];
        
        self.cookieID = nil;
        
        NSLog(@"Logged out");
        
        
    }
    
    //Avoid calling an not existing block or retaining the block in
    //the ViewController that should disappear
    [self setAllBlocksToNilExceptLogoutBlock];
    
    //Since not only when user click logout but also when encountered
    //an error state will this function be executed, this logoutBlock
    //is important to clean all memorized stuffs in controller/model
    //and go back to login page. Therefore, a purpose of this logoutBlock
    //is that program can be recovered from error state
    if(self.logoutBlock && triggerLogoutBlock)
        self.logoutBlock();
}

//Could use this as template for addtional general request-response message
-(void)createClassWithName:(NSString *)className onCompletion:(void (^)(SendMessageResult, NSString *, NSString *))completion{

    if(!completion || !className){
        NSLog(@"Parameters can't be nil. create class abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while createClass. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }

    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:CREATE_CLASS_REQ
                          andArguments:@[className,self.cookieID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send create class message failed, code: %d", (int)result);
                                  completion(result, nil, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
    
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:CREATE_CLASS_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for CREATE_CLASS_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0], arguments[1]);
                              }
    
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    
    
}

//could use as template for one way message (not expect a response)
-(void)respondToChangePresenterWithClassID:(NSString *)classID
                       andNewPresenterName:(NSString *)newPresenter
                               andDecision:(NSString *)decision
                              onCompletion:(void (^)(SendMessageResult))completion{

    if(!completion || !classID || !newPresenter || !decision){
        NSLog(@"Parameters can't be nil. respond to change presenter abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while respond to change presenter. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:CHANGE_PRESENT_TOKEN_RES
                          andArguments:@[self.cookieID,classID,newPresenter,decision]
                          andSendCompletionBlock:^(SendMessageResult result) {
                              
                              completion(result);
                              
                          }
                          andReceiveResponseBlock:nil //no response will receive
                          ];
    
    [self processReadyToSendMessage:message expectAResponse:NO];
    

}

-(void)listClassesAndOnCompletion:(void (^)(SendMessageResult, NSString *, NSInteger, NSArray *))completion{

    if(!completion){
        NSLog(@"Parameters can't be nil. list class abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while list class. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:LIST_CLASS_REQ
                          andArguments:@[self.cookieID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send list class message failed, code: %d", (int)result);
                                  completion(result, nil, 0, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:LIST_CLASS_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for LIST_CLASS_REQ, command: %@", command);
                              }else{
                                  if([arguments[0] isEqualToString:SUCCESS]){ //status == SUCCESS
                                      
                                      NSInteger numOfClasses = [arguments[1] integerValue];
                                      
                                      //check whether it match to avoid over range access
                                      if((arguments.count-2)/3 != numOfClasses){
                                          NSLog(@"arguments count and classes number doesn't match! will return 0 class");
                                          completion(SendMessageResultSucceeded, arguments[0], 0, nil);
                                          return;
                                      }
                                      
                                      //start to generate classes array
                                      NSMutableArray *classes = [[NSMutableArray alloc] init];
                                      
                                      for(int i=0; i < numOfClasses; i++){
                                          CCClass *class = [[CCClass alloc] init];
                                          class.classID = arguments[i*3+2];
                                          class.className = arguments[i*3+3];
                                          class.instructorName = arguments[i*3+4];
                                          [classes addObject:class];
                                      }
                                      
                                      completion(SendMessageResultSucceeded, arguments[0], numOfClasses, classes);
                                      
                                  }else{
                                      completion(SendMessageResultSucceeded, arguments[0], 0, nil);
                                  }
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
}

-(void)deleteClassWithClassID:(NSString *)classID
                 onCompletion:(void (^)(SendMessageResult, NSString *))completion{


    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. delete class abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while delete class. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:DEL_CLASS_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send delete class message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:DEL_CLASS_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for DEL_CLASS_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    
}

-(void)joinClassWithClassID:(NSString *)classID
               onCompletion:(void (^)(SendMessageResult, NSString *,
                                      NSString *, NSString *))completion{

    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. join class abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while join class. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:JOIN_CLASS_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send join class message failed, code: %d", (int)result);
                                  completion(result, nil, nil, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:JOIN_CLASS_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for JOIN_CLASS_REQ, command: %@", command);
                              }else if(![arguments[0] isEqualToString:classID]){
                                  NSLog(@"Error! JOIN_CLASS_RES invoked incorrect JOIN_CLASS_REQ. Request classID: %@, received classID: %@",
                                        classID, arguments[0]);
                              }else{
                                  
                                  completion(SendMessageResultSucceeded, arguments[2], arguments[0], arguments[1]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];

}

-(void)queryClassInfoWithClassID:(NSString *)classID
                    onCompletion:(void (^)(SendMessageResult, NSString *, NSString *, NSInteger, NSArray *))completion{


    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. query class info abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while query class info. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:QUERY_CLASS_INFO_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send query class info message failed, code: %d", (int)result);
                                  completion(result, nil, nil, 0, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:QUERY_CLASS_INFO_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for QUERY_CLASS_INFO_REQ, command: %@", command);
                              }else{
                                  if([arguments[0] isEqualToString:SUCCESS]){ //status == SUCCESS
                                      
                                      NSInteger numOfStudents = [arguments[2] integerValue];
                                      
                                      //check whether it match to avoid over range access
                                      if((arguments.count-3) != numOfStudents){
                                          NSLog(@"arguments count and student number doesn't match! will return 0 student");
                                          completion(SendMessageResultSucceeded, arguments[0], nil, 0, nil);
                                          return;
                                      }
                                      
                                      //start to generate student array
                                      NSArray *studentNames = [arguments subarrayWithRange:NSMakeRange(3, numOfStudents)];
                                      
                                      completion(SendMessageResultSucceeded, arguments[0], arguments[1], numOfStudents, studentNames);
                                      
                                  }else{
                                      completion(SendMessageResultSucceeded, arguments[0], nil, 0, nil);
                                  }
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    
}

-(void)quitClassWithClassID:(NSString *)classID
               onCompletion:(void (^)(SendMessageResult, NSString *))completion{

    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. quit class abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while quit class. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:QUIT_CLASS_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send quit class message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:QUIT_CLASS_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for QUIT_CLASS_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    


}

-(void)kickStudentWithClassID:(NSString *)classID
               andStudentName:(NSString *)studentName
                 onCompletion:(void (^)(SendMessageResult, NSString *))completion{

    if(!completion || !classID || !studentName){
        NSLog(@"Parameters can't be nil. kick student abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while kick student. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:KICK_USER_REQ
                          andArguments:@[self.cookieID, classID, studentName] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send kick student message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:KICK_USER_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for KICK_USER_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    

}

//Could use this as template for addtional general request-response message
-(void)pushContentWithClassID:(NSString *)classID
                 andContentID:(NSString *)contentID
               andContentType:(NSString *)contentType
                 onCompletion:(void (^)(SendMessageResult, NSString *))completion{
    
    if(!completion || !classID || !contentID || !contentType){
        NSLog(@"Parameters can't be nil. push content abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while pushing content. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:PUSH_CONTENT_REQ
                          andArguments:@[self.cookieID, classID, contentID, contentType] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send create class message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:PUSH_CONTENT_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for PUSH_CONTENT_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    
    
}


-(void)getPresentTokenWithClassID:(NSString *)classID
                     onCompletion:(void (^)(SendMessageResult, NSString *,
                                            NSString *, NSString *))completion{

    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. getPresentToken abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while getPresentToken. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:GET_PRESENT_TOKEN_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send getPresentToken message failed, code: %d", (int)result);
                                  completion(result, nil, nil, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:GET_PRESENT_TOKEN_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for GET_PRESENT_TOKEN_REQ, command: %@", command);
                              }else if(![arguments[0] isEqualToString:classID]){
                                  NSLog(@"Error! GET_PRESENT_TOKEN_RES invoked incorrect GET_PRESENT_TOKEN_REQ. Request classID: %@, received classID: %@",
                                        classID, arguments[0]);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[2], arguments[0], arguments[1]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    


}

-(void)retrievePresentTokenWithClassID:(NSString *)classID
                          onCompletion:(void (^)(SendMessageResult, NSString *))completion{

    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. retrievePresentToken abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while retrievePresentToken. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:RETRIEVE_PRESENT_TOKEN_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send retrievePresentToken message failed, code: %d", (int)result);
                                  completion(result, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:RETRIEVE_PRESENT_TOKEN_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for RETRIEVE_PRESENT_TOKEN_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    


}

-(void)queryLatestContentWithClassID:(NSString *)classID
                        onCompletion:(void (^)(SendMessageResult,
                                               NSString *, NSString *,
                                               NSString *))completion{
    
    if(!completion || !classID){
        NSLog(@"Parameters can't be nil. query latest content abort.");
        return;
    }
    
    if(!self.isLoggedIn){
        //I don't raise exception here, so that program can be recovered from error
        //state after exec logout
        NSLog(@"Error! Not logged in while createClass. Force to execute logout");
        [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
        return;
    }
    
    CCMessage *message = [[CCMessage alloc]
                          initWithCommand:QUERY_LATEST_CONTENT_REQ
                          andArguments:@[self.cookieID, classID] //Don't forget cookieID
                          andSendCompletionBlock:^(SendMessageResult result) {
                              if (result != SendMessageResultSucceeded) {
                                  
                                  NSLog(@"try to send create class message failed, code: %d", (int)result);
                                  completion(result, nil, nil, nil);
                                  
                              }
                              
                              //For success case, no need to do anything now, until server
                              //send response back
                              
                          }
                          andReceiveResponseBlock:^(NSString *command, NSArray *arguments) {
                              if(![command isEqualToString:QUERY_LATEST_CONTENT_RES]){
                                  NSLog(@"Error! Invoked incorrect sent message for QUERY_LATEST_CONTENT_REQ, command: %@", command);
                              }else{
                                  completion(SendMessageResultSucceeded, arguments[0], arguments[1], arguments[2]);
                              }
                              
                          }];
    
    [self processReadyToSendMessage:message expectAResponse:YES];
    
    
}


//
-(void)setAllBlocksToNilExceptLogoutBlock{
    //self.receivedChangePresentTokenIndBlock = nil;
    self.receivedChangePresentTokenReqBlock = nil;
    //self.receivedCondPushContentGetNotifyBlock = nil;
    self.receivedKickUserIndBlock = nil;
    self.receivedPushContentNotifyBlock = nil;
    self.receivedRetrievePresentTokenIndBlock = nil;
}

//process received messages that is not a respond to a request we sent
-(void)receivedIndependentMessageWithCommand:(NSString *)command andArguments:(NSArray *)arguments{

    if([command isEqualToString:KICK_USER_IND]){
        
        if(self.receivedKickUserIndBlock)
            self.receivedKickUserIndBlock(arguments[0],arguments[1], arguments[2]);
        
    }else if([command isEqualToString:PUSH_CONTENT_NOTIFY]){
        
        if(self.receivedPushContentNotifyBlock)
            self.receivedPushContentNotifyBlock(arguments[0], arguments[1]);
    
    //}else if([command isEqualToString:COND_PUSH_CONTENT_GET_NOTIFY]){
    
    }else if([command isEqualToString:CHANGE_PRESENT_TOKEN_REQ]){
        
        if(self.receivedChangePresentTokenReqBlock)
            self.receivedChangePresentTokenReqBlock(arguments[0],arguments[1]);
    
    //}else if([command isEqualToString:CHANGE_PRESENT_TOKEN_IND]){
    
    }else if([command isEqualToString:RETRIEVE_PRESENT_TOKEN_IND]){
        
        if(self.receivedRetrievePresentTokenIndBlock)
            self.receivedRetrievePresentTokenIndBlock(arguments[0], arguments[1]);
    
    }else{
    
        NSLog(@"Received an independent message but no corresponding handler. Discard it");
        return;
    }
}

-(void)processReceivedMessage:(NSArray *)receivedMessage{

    NSString *command = receivedMessage[0];
    NSArray *arguments = [receivedMessage subarrayWithRange:NSMakeRange(1, receivedMessage.count-1)];
    
    if(![self checkValidityOfCommand:command andArguments:arguments]){
        NSLog(@"Invalid message, discard it");
        return;
    }
    
    NSArray *commandInfo = [CCMessageCenter getInfoOfCommand:command];
    
    if(commandInfo[0] == [NSNull null]){ //is a indepenent message
    
        [self receivedIndependentMessageWithCommand:command andArguments:arguments];
            
    }else{ //is a response of a request we sent
    
        CCMessage *requestMessage = [self getCorrespondingRequestForResponseWithCommand:command
                                                                           andArguments:arguments];
        
        if (!requestMessage) {
            NSLog(@"Cannot find corresponding request for the response, discard it. Command: %@", command);
            return;
        }
#ifdef USE_ALERT_BLOCKING
        if([requestMessage isEqual:self.blockingMessage])
            [self dismissBlockingAlert];
#endif
        if(requestMessage.receiveResponseBlock) //shouldn't be nil, but in case
            requestMessage.receiveResponseBlock(command, arguments);
    }

    //if has STATUS and is NOT_LOGIN, execute logout action
    if(commandInfo[2] != [NSNull null]){
        if([[arguments objectAtIndex:[(NSNumber *)commandInfo[2] integerValue]] isEqualToString:NOT_LOGIN]){
            [self logoutAndTriggerLogoutBlock:YES onCompletion:nil];
            //no need [self closeServerConnection]; since whenever going to login page will reset Message Center
            //Also, closeServerConnetion will call back block, so shouldn't when going to logout
        }
    }

#ifdef USE_PUSH_NOTIFICATION
    if(self.sentMessages.count == 0 && self.serverCH.isQueueEmpty)
        [self closeServerConnection];
#endif

}

//Find the corresponding requst for the response
//Will return nil if cannot find it
-(CCMessage *)getCorrespondingRequestForResponseWithCommand:(NSString *)command andArguments:(NSArray *)arguments{

    //for now argument is not used, but in the future, if we want more
    //acurrate, we can use e.g. generated time sent to and sent back from
    //server to verify whether it's exactly the request for the response
    //Now we only compare the command name, and take the first one we found
    //as the one we need
    CCMessage *requestMessage = nil;
    
    for(CCMessage *message in self.sentMessages){
    
        NSArray *commandInfo = [CCMessageCenter getInfoOfCommand:command];
        if([commandInfo[0] isEqualToString:message.command]){
            if(commandInfo[3] == [NSNull null]){
                requestMessage = message;
                break;
            }else{ // has classID in both response and request
                if([[arguments objectAtIndex:[(NSNumber *)commandInfo[3] integerValue]]
                   isEqualToString:[message.arguments objectAtIndex:[(NSNumber *)commandInfo[4] integerValue]]]){
                    requestMessage = message;
                    break;
                }
            }
        }
    }
    
    //remove from storage
    [self.sentMessages removeObject:requestMessage];
    
    return requestMessage;

}

//check whether command is valid
-(BOOL)checkValidityOfCommand:(NSString *)command andArguments:(NSArray *)arguments{

    NSArray *commandInfo = [CCMessageCenter getInfoOfCommand:command];
    
    if(!commandInfo){
    
        NSLog(@"Command not in the dictionary, unknown command!");
        return NO;
    
    }else{
    
        //Check argument number
        if(commandInfo[1] != [NSNull null]){ //fixed number of arguments
            
            if(arguments.count != [commandInfo[1] integerValue]){
            
                NSLog(@"Incorrect argument count. Command: %@, arguments count: %lu, should be %ld",
                      command, (unsigned long)arguments.count, (long)[commandInfo[1] integerValue]);
                
                return NO;
            }
            
        }else{ //not fixed number of arguments
            
            if([command isEqualToString:LIST_CLASS_RES]){ //I don't handle nCLASS here, which is the content
            
                if(arguments.count < 2 || (arguments.count-2)%3 != 0){
                    NSLog(@"Invalid argument count for LIST_CLASS_RES. argument count: %lu", (unsigned long)arguments.count);
                    return NO;
                }
            
            }else if([command isEqualToString:QUERY_CLASS_INFO_RES]){
            
                if(arguments.count < 3){
                
                    NSLog(@"Invalid argument count for QUERY_CLASS_INFO_RES. argument count: %lu", (unsigned long)arguments.count);
                    return NO;
                    
                }
            
            }else{
            
                NSLog(@"Not fixed number arguments, but not handled in function, command: %@, arguments count: %lu",
                      command, (unsigned long)arguments.count);
                return NO;
            
            }
                
        }
    
    }
    
    return YES;

}

#ifdef USE_ALERT_BLOCKING
-(void)dismissBlockingAlert{
    
    if(self.blockingAlert){
        //dispatch_async(dispatch_get_main_queue(), ^{
            [self.blockingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            self.blockingAlert = nil;
            self.blockingMessage = nil;
        //});
    }
    
}
#endif

-(void)clearSentMessagesWithResult:(SendMessageResult)result{
    
    for(CCMessage *message in self.sentMessages){
#ifdef USE_ALERT_BLOCKING
        if([message isEqual:self.blockingMessage])
            [self dismissBlockingAlert];
#endif
        if(message.sendCompletionBlock)
            message.sendCompletionBlock(result);
        //remove message from its queue so that won't call completion block twice if the msg is there
        [self.serverCH removeMessageFromQueue:message];
        
        
    }
    
    //can not use removeObject:message, since it will generate exception
    //that "NSMutableArray was mutated while being enumerated."
    [self.sentMessages removeAllObjects];
    
}

//Note that this doesn't mean to logout, so will keep cookieID
-(void)closeServerConnection{

    [self clearSentMessagesWithResult:SendMessageResultConnectionClosed];
    [self.serverCH closeServerConnection];

}

-(BOOL)isSentMessagesEmpty{
    return (self.sentMessages.count == 0);
}

//use cookieID to verify, which will be nil if not logged in
-(BOOL)isLoggedIn{
    return (self.cookieID) ? YES : NO;
}


//Get the detail of the command (only possibily
//received commands, not including send)
//Return nil if can't find it in dictionary
+(NSArray *)getInfoOfCommand:(NSString *)command{
    
    static NSDictionary *commandInfoDictionary = nil;
    static NSNull *nothing;
    static dispatch_once_t onceToken;
    
    //only execute once for any number of calls
    dispatch_once(&onceToken, ^{
        
        nothing = [NSNull null];
        
        /* For any command, it corresponds to a NSArray in the
         * dictionary.
         
         * The first arg
         * is either a NSString or a NSNull(since nil can't put in array).
         * If the command is a response to a request, the first arg
         * will be the corresponding request command (NSString), and will
         * be [NSNull null] otherwise. I use [NSNull null] instead of not
         * adding the object because I want to avoid over range access.
         
         * The second value of the array is the command's
         * argument count, which is a NSNumber. If the argument number
         * is not a fixed number, such as LIST_CLASS_RES, it will be
         * [NSNull null], and you should check it seperately
         
         * The third argument indicates the position (NSNumber, and start
         * from 0) of STATUS arg of the
         * command if any, or [NSNull null] otherwise. (For example, 
         * CREATE_CLASS_RES (STATUS, CLASS_ID) will be 0)
         
         * The fourth argument indicate the position of 'classID' 
         * in a response if any. Will be [NSNull null] otherwise
         
         * The fifth is the same as fourth, but in request
         */
        commandInfoDictionary = @{
                        
                 LOGIN_RES  : @[LOGIN_REQ, [NSNumber numberWithInteger:3], [NSNumber numberWithInteger:0], nothing, nothing],
                 LOGOUT_RES : @[LOGOUT_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 CREATE_CLASS_RES : @[CREATE_CLASS_REQ, [NSNumber numberWithInteger:2], [NSNumber numberWithInteger:0],
                                      nothing, nothing],
                 LIST_CLASS_RES : @[LIST_CLASS_REQ, nothing, [NSNumber numberWithInteger:0], nothing, nothing],
                 DEL_CLASS_RES : @[DEL_CLASS_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 JOIN_CLASS_RES : @[JOIN_CLASS_REQ, [NSNumber numberWithInteger:3], [NSNumber numberWithInteger:2],
                                    [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1]],
                 QUERY_CLASS_INFO_RES : @[QUERY_CLASS_INFO_REQ, nothing, [NSNumber numberWithInteger:0], nothing, nothing],
                 QUIT_CLASS_RES : @[QUIT_CLASS_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 KICK_USER_RES : @[KICK_USER_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 KICK_USER_IND : @[nothing, [NSNumber numberWithInteger:3], [NSNumber numberWithInteger:0], nothing, nothing],
                 PUSH_CONTENT_RES : @[PUSH_CONTENT_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 PUSH_CONTENT_NOTIFY : @[nothing, [NSNumber numberWithInteger:2], nothing, nothing, nothing],
                 PUSH_CONTENT_GET_RES : @[PUSH_CONTENT_GET_REQ, [NSNumber numberWithInteger:5], [NSNumber numberWithInteger:0], nothing, nothing],
                 COND_PUSH_CONTENT_RES : @[COND_PUSH_CONTENT_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0],
                                           nothing, nothing],
                 COND_PUSH_CONTENT_GET_NOTIFY : @[nothing, [NSNumber numberWithInteger:2], nothing, nothing, nothing],
                 CHANGE_PRESENT_TOKEN_REQ : @[nothing, [NSNumber numberWithInteger:2], nothing, nothing, nothing],
                 GET_PRESENT_TOKEN_RES : @[GET_PRESENT_TOKEN_REQ, [NSNumber numberWithInteger:3], [NSNumber numberWithInteger:2],
                                           [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1]],
                 CHANGE_PRESENT_TOKEN_IND : @[nothing, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0], nothing, nothing],
                 RETRIEVE_PRESENT_TOKEN_IND : @[nothing, [NSNumber numberWithInteger:2], nothing, nothing, nothing],
                 RETRIEVE_PRESENT_TOKEN_RES : @[RETRIEVE_PRESENT_TOKEN_REQ, [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:0],
                                                nothing, nothing],
                 QUERY_LATEST_CONTENT_RES : @[QUERY_LATEST_CONTENT_REQ, [NSNumber numberWithInteger:3], [NSNumber numberWithInteger:0],
                                              [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:1]]
                 
                 };
    });
    
    return (NSArray *)[commandInfoDictionary objectForKey:command];

}


-(instancetype)init{
    self = [super init];
    
    if (self) {
        self.cookieID = nil;
        self.sentMessages = [[NSMutableArray alloc] init];
        
        //load server setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *serverURL = [userDefaults objectForKey:SERVER_URL];
        NSInteger serverPort = [userDefaults integerForKey:SERVER_PORT];
        
        if(!serverURL){ //cannot find the field
            serverURL = DEFAULT_SERVER_URL;
            serverPort = DEFAULT_SERVER_PORT;
            NSLog(@"App first time loaded. Generate server info in standardUserDefaults.");
            [userDefaults setObject:serverURL forKey:SERVER_URL];
            [userDefaults setInteger:serverPort forKey:SERVER_PORT];
            [userDefaults synchronize];
        }

        self.serverCH = [[CCCommunicationHandler alloc]
                         initWithServerURL:[NSURL URLWithString:serverURL]
                         andPort:serverPort];
        
        self.serverCH.serverMC = self;
        
        __weak CCMessageCenter *weakSelf = self;
        self.serverCH.receivedMessageBlock = ^(NSArray *receivedMessage){
            if(weakSelf)
                [weakSelf processReceivedMessage:receivedMessage];
        };
    }
    
    return self;
}

@end
