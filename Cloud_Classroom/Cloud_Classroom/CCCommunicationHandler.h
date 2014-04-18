//
//  CCCommunicationHandler.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCTCPConnection.h"

typedef NS_ENUM(NSInteger, SendMessageResult) {
    SendMessageResultServerInfoNotSet,
    //SendMessageResultIsAlreadyTryingToConnect, //some one else is already try to connect now.
    SendMessageResultCanNotConnect,
    SendMessageResultNoCommand,
    SendMessageResultSucceeded,
    SendMessageResultInvalidArguments,
    //SendMessageResultHasNoSpaceToSend,
    SendMessageResultFailed
};

typedef NS_ENUM(NSInteger, LoginResult) {
    LoginResultSucceeded,
    LoginResultInvalidUser,
    LoginResultFailed, //Password incorrect or other reason?
    //LoginResultServerInfoNotSet,
    //LoginResultIsAlreadyTryingToConnect,
    LoginResultCanNotConnect
    //LoginResultHasNoSpaceToSend
};

@interface CCCommunicationHandler : NSObject

@property (nonatomic,readonly) BOOL isLoggedIn;
@property (nonatomic,readonly) BOOL isConnectedToServer;
@property (nonatomic,readonly) BOOL isServerInfoSet;

//Blocks
@property (strong,atomic) void (^receivedMessageBlock)(NSArray *receivedMessage);
//@property (strong,atomic) void (^hasSpaceToSendBlock)();


-(instancetype)init;
-(instancetype)initWithServerURL:(NSURL *)url andPort:(NSInteger)port;

-(BOOL)setServerURL:(NSURL *)url andPort:(NSInteger)port;

//-(void)tryToConnectServerAndOnCompletion:(void (^)(TryToConnectResult result))completion;

-(void)sendMessageToServerWithCommand:(NSString *)command
                         andArguments:(NSArray *)arguments
                         onCompletion:(void (^)(SendMessageResult result))completion;

-(void)loginWithUserID:(NSString *)userID
           andPassword:(NSString *)password
          onCompletion:(void (^)(LoginResult result))completion;

-(void)logout;

-(void)removeAllMessagesInQueue;

-(void)makeAllMessagesInQueueCompletedWithResult:(SendMessageResult)result;

@end
