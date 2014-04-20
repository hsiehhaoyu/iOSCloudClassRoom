//
//  CCMessage.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/17.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCMessage.h"


@interface CCMessage ()

@property (nonatomic,strong,readwrite) NSString *command;

@property (nonatomic,strong,readwrite) NSArray *arguments;

//What to do when send completion (could be fail or other cases)
@property (nonatomic,strong,readwrite) void (^sendCompletionBlock)(SendMessageResult result);

//What to do when receive a response from server
@property (nonatomic,strong,readwrite) void (^receiveResponseBlock)(NSString *command, NSArray *arguments);

@property (nonatomic,strong,readwrite) NSDate *generatedTime;

@end


@implementation CCMessage

-(instancetype)initWithCommand:(NSString *)command
                  andArguments:(NSArray *)arguments
        andSendCompletionBlock:(void (^)(SendMessageResult))sendCompletionBlock
       andReceiveResponseBlock:(void (^)(NSString *, NSArray *))receiveResponseBlock{
    
    self = [super init];
    
    if(self){
        
        //this cannot be nil, or an invalid message
        if(!command){
            return nil;
        }
        
        self.command = command;
        self.arguments = arguments;
        self.sendCompletionBlock = sendCompletionBlock;
        self.receiveResponseBlock = receiveResponseBlock;
        self.generatedTime = [NSDate date];
    }
    
    return self;
}

//Don't use this one
-(instancetype)init{
    [NSException raise:NSInternalInconsistencyException
                format:@"Need to use initWithCommand:..."];
    
    return nil;
}


@end
