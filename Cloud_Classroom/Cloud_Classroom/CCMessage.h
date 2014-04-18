//
//  CCMessage.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/17.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "CCCommunicationHandler.h"

@interface CCMessage : NSObject

@property (nonatomic,strong,readonly) NSString *command;

@property (nonatomic,strong,readonly) NSArray *arguments;

@property (nonatomic,strong,readonly) void (^completionBlock)(SendMessageResult result);


-(instancetype)initWithCommand:(NSString *)command
                  andArguments:(NSArray *)arguments
            andCompletionBlock:(void (^)(SendMessageResult result))completionBlock;

@end
