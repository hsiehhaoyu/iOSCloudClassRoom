//
//  CCCommunicationHandler.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCTCPConnection.h"
#import "CCMessage.h"
#import "CCMessageCenter.h"


@interface CCCommunicationHandler : NSObject

@property (nonatomic,weak) CCMessageCenter *serverMC;

@property (nonatomic,readonly) BOOL isConnectedToServer;
@property (nonatomic,readonly) BOOL isServerInfoSet;

//Blocks
@property (strong,atomic) void (^receivedMessageBlock)(NSArray *receivedMessage);
//@property (strong,atomic) void (^hasSpaceToSendBlock)();


-(instancetype)init;
-(instancetype)initWithServerURL:(NSURL *)url andPort:(NSInteger)port;

-(BOOL)setServerURL:(NSURL *)url andPort:(NSInteger)port;

//-(void)tryToConnectServerAndOnCompletion:(void (^)(TryToConnectResult result))completion;

//-(void)sendMessageToServerWithCommand:(NSString *)command
//                         andArguments:(NSArray *)arguments
//                         onCompletion:(void (^)(SendMessageResult result))completion;

-(void)sendToServerWithMessage:(CCMessage *)message;

-(void)makeAllMessagesInQueueCompletedWithResult:(SendMessageResult)result;

-(void)makeMessage:(CCMessage *)message completedWithResult:(SendMessageResult)result;

-(void)removeMessageFromQueue:(CCMessage *)message;

-(void)closeServerConnection;

-(BOOL)isQueueEmpty;

@end
