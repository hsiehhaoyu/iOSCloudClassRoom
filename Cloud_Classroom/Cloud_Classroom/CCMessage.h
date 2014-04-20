//
//  CCMessage.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/17.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SendMessageResult) {
    SendMessageResultServerInfoNotSet,
    //SendMessageResultIsAlreadyTryingToConnect, //some one else is already try to connect now.
    SendMessageResultCanNotConnect,
    SendMessageResultNoCommand,
    SendMessageResultSucceeded,
    SendMessageResultInvalidArguments,
    //SendMessageResultHasNoSpaceToSend,
    SendMessageResultFailed,
    SendMessageResultTimeOut
};

@interface CCMessage : NSObject

@property (nonatomic,strong,readonly) NSString *command;

@property (nonatomic,strong,readonly) NSArray *arguments;

@property (nonatomic,strong,readonly) void (^sendCompletionBlock)(SendMessageResult result);

@property (nonatomic,strong,readonly) void (^receiveResponseBlock)(NSString *command, NSArray *arguments);

@property (nonatomic,strong,readonly) NSDate *generatedTime;

-(instancetype)initWithCommand:(NSString *)command
                  andArguments:(NSArray *)arguments
        andSendCompletionBlock:(void (^)(SendMessageResult result))sendCompletionBlock
       andReceiveResponseBlock:(void (^)(NSString *command, NSArray *arguments))receiveResponseBlock;

@end
