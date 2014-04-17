//
//  CCCommunicationHandler.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//
/*
 * This class will help handle login/logout and
 * reconnect stuffs. Execpt those, other are treated
 * as normal message sending/receiving
 */

#import "CCCommunicationHandler.h"
#import "CCConfiguration.h"

@interface CCCommunicationHandler ()

@property (strong,atomic) CCTCPConnection *serverConnection;

//Will be nil if not logged in
@property (strong,atomic) NSString *cookieID;

//Blocks
@property (strong,atomic) void (^completionBlockOfLogin)(LoginResult);



@end

@implementation CCCommunicationHandler

//-(void)testFunction{
//    if([self isConnectedToServer]){
//        [self.serverConnection sendString:@"Test message"];
//    }else{
//        [self.serverConnection tryToEstablishConnectionAndOnCompletion:^(TryToConnectResult result) {
//            [self.serverConnection sendString:@"Test2 message"];
//        }];
//    }
//}

/* 
 * BOOL in completion block will be YES if login successfully
 * Will logout first if already logged in
 */
-(void)loginWithUserID:(NSString *)userID andPassword:(NSString *)password onCompletion:(void (^)(LoginResult))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    if(self.isLoggedIn){
        [self logout];
    }
    
    [self sendMessageToServerWithCommand:LOGIN_REQ andArguments:@[userID,password] onCompletion:^(SendMessageResult result) {
        if (result == SendMessageResultSucceeded) {
            self.completionBlockOfLogin = completion;
        }else if (result == SendMessageResultIsAlreadyTryingToConnect){
            completion(LoginResultIsAlreadyTryingToConnect);
        }else if (result == SendMessageResultHasNoSpaceToSend){
            completion(LoginResultHasNoSpaceToSend);
        }else if (result == SendMessageResultCanNotConnect){
            completion(LoginResultCanNotConnect);
        }else{
            NSLog(@"Impossible result occurred when login. Check your code. Result: %ld", result);
        }
    }];
}

/* 
 * Send request/response to server.
 * Note that all arguments should be
 * NSString, or Action will be abort.
 * Note that even sent successfully 
 * does NOT gurantee server will receive it.
 */
//completion block can be nil
-(void)sendMessageToServerWithCommand:(NSString *)command
                         andArguments:(NSArray *)arguments
                         onCompletion:(void (^)(SendMessageResult))completion{
    
    if(!self.isServerInfoSet){
        
        if(completion)
            completion(SendMessageResultServerInfoNotSet);
    
    }else if(!self.isConnectedToServer){
        [self tryToConnectServerAndOnCompletion:^(TryToConnectResult result) {
            //Already connect could happen, since someone might be trying when we exam self.isConnectedToServer
            if(result == TryToConnectResultSucceeded || result == TryToConnectResultAlreadyConnected){
                //send again
                [self sendMessageToServerWithCommand:command andArguments:arguments onCompletion:^(SendMessageResult result) {
                    if(completion)
                        completion(result);
                }];
            }else if(result == TryToConnectResultAlreadyTrying){
                if(completion)
                    completion(SendMessageResultIsAlreadyTryingToConnect);
            }else{ //failed
                if (completion)
                    completion(SendMessageResultCanNotConnect);
            }
        }];
    }else{
        
        //start to combind all stuffs into one string
        NSString *message;
        if (command) { // is not nil
            message = [NSString stringWithFormat:@"%@\n",command];
        }else{
            
            NSLog(@"Need a command!");
            
            if(completion)
                completion(SendMessageResultNoCommand);
            
            return;
        }
        
        if(arguments){ //something in the argument array(Note: it's allowed to be nil)
            for(id arg in arguments){
                if([arg isKindOfClass:[NSString class]]){ //don't know why but isMemberOfClass doesn't work
                    message = [NSString stringWithFormat:@"%@:%@\n", message, (NSString *)arg];
                    //NSLog(@"Argument: %@", arg);
                }else{
                    NSLog(@"At least an argument is not NSString!");
                    if(completion)
                        completion(SendMessageResultInvalidArguments);
                    return;
                }
            }
        }
        
        message = [NSString stringWithFormat:@"%@END\n",message];
        
        NSLog(@"message: %@",message);
        
        [self.serverConnection sendString:message onCompletion:^(SendDataResult result) {
            if (result == SendDataResultSucceeded) {
                if(completion)
                    completion(SendMessageResultSucceeded);
            }else if(result == SendDataResultHasNoSpaceToSend){
                if(completion)
                    completion(SendMessageResultHasNoSpaceToSend);
            }else{ //all other cases treat as failed
                if(completion)
                    completion(SendMessageResultFailed);
            }
        }];
    }
}

//What to do when received data
//In our case, only string
-(void)receivedData:(NSData *)data{
    
    NSLog(@"receivedData Called.");
    
    NSString *receivedString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    NSArray *message = [self decodeStringToMessage:receivedString];
    
    //Recieve Login_RES
    if([[message firstObject]  isEqual: LOGIN_RES]){
        
        if(self.completionBlockOfLogin){
            
            if([[message objectAtIndex:1] isEqualToString:INVALID_USER]){
                self.completionBlockOfLogin(LoginResultInvalidUser);
            }else if ([[message objectAtIndex:1] isEqualToString:LOGIN_FAIL]){
                self.completionBlockOfLogin(LoginResultFailed);
            }else{
                self.cookieID = [message objectAtIndex:2];
                self.completionBlockOfLogin(LoginResultSucceeded);
            }
            
            self.completionBlockOfLogin = nil; //release it
            
        }else{
            NSLog(@"No Completion block but receive LOGIN_RES !! Weird! Action abort");
        }
        
    }else{ //other types of message
    
        if(self.receivedMessageBlock){
            self.receivedMessageBlock(message);
        }else{
            NSLog(@"Received message but no block can be called!");
        }
        
    }
}

//Decode to command and arguments
-(NSArray *)decodeStringToMessage:(NSString *)string{
    //todo: handle multiple message case, include fragment(seperate with END\n?)
    NSArray *originMsg = [string componentsSeparatedByString:@"\n"];
    
    NSMutableArray *treatedMsg = [originMsg mutableCopy];
    //handle : before arguments
    for (int i=1; i < treatedMsg.count - 1; i++) { //start from second object, ignore END
        [treatedMsg setObject:[treatedMsg[i] substringFromIndex:1] atIndexedSubscript:i];
    }
    [treatedMsg removeObjectAtIndex:[treatedMsg count]-1]; //remove @""
    [treatedMsg removeObjectAtIndex:[treatedMsg count]-1]; //remove @"END"
    return [treatedMsg copy];
}


-(void)tryToConnectServerAndOnCompletion:(void (^)(TryToConnectResult))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    [self.serverConnection tryToEstablishConnectionAndOnCompletion:^(TryToConnectResult result) {
        if (result == TryToConnectResultSucceeded) {
            //Register call back blocks
            __weak CCCommunicationHandler *weakSelf = self;
            [self.serverConnection setWhatToDoWhenHasBytesAvailableWithBlock:^(NSData *readData) {
                [weakSelf receivedData:readData];
            }];
            
            [self.serverConnection setWhatToDoWhenHasSpaceToSendWithBlock:^{
                if(weakSelf.hasSpaceToSendBlock)
                    weakSelf.hasSpaceToSendBlock();
            }];
            
        }
        completion(result);
    }];

}

//check whether server url and port has been set
-(BOOL)isServerInfoSet{
    return (self.serverConnection) ? YES : NO;
}

//check whether is conncted to server
-(BOOL)isConnectedToServer{
    if(self.serverConnection){
        return self.serverConnection.isConnected;
    }else{
        return NO;
    }
}

//use cookieID to verify, which will be nil if not logged in
-(BOOL)isLoggedIn{
    return (self.cookieID) ? YES : NO;
}

//logout (will connect to server to logout if not connected)
//we ignore the response msg from server, since that doesn't
//affect the result in our case
-(void)logout{
    
    if(!self.isLoggedIn){
        NSLog(@"Not logged in while trying to logout");
    }else{
    
        [self sendMessageToServerWithCommand:LOGOUT_REQ andArguments:@[self.cookieID] onCompletion:^(SendMessageResult result) {
            
            //We don't do any thing if cannot sucessfully send msg,
            //since it doesn't affect much (won't lead to error
            //state in our design)
            if(result != SendMessageResultSucceeded){
                NSLog(@"Can't send log out msg!");
            }
        }];
        
        self.cookieID = nil;
        
        NSLog(@"Logged out");
    
    }
}


//return YES if init (not connect) the serverConnection successfully
//will set to logout state, close existing connection, and init a new TCPConnection
-(BOOL)setServerURL:(NSURL *)url andPort:(NSInteger)port{
    
    if(self.isConnectedToServer){
        if (self.isLoggedIn) {
            [self logout];
        }
        [self.serverConnection endConnection]; //can't put below, since it may be nil
    }else{
        //we don't use logout function if not connected, since it will connection to server again
        //which is not necessary and also may cause problem (e.g. connection could be nil at this time)
        self.cookieID = nil;
    }
    
    self.serverConnection = [[CCTCPConnection alloc] initWithURL:url andPort:port];
    
    if (self.serverConnection) { //init successfully
        return YES;
    }else{
        NSLog(@"Cannot initial the server connection!");
        return NO;
    }
}

/* 
 * Won't return nil if cannot init (not connect) the serverConnection
 * with given arguments.
 */
-(instancetype)initWithServerURL:(NSURL *)url andPort:(NSInteger)port{
    
    self = [self init];
    
    if(self){
        [self setServerURL:url andPort:port];
    }
    
    return self;
}

-(instancetype)init{
    self = [super init];
    
    if (self) {
        self.cookieID = nil;
    }
    
    return self;
}

@end
