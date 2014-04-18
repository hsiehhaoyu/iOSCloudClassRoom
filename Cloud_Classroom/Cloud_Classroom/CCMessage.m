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

@property (nonatomic,strong,readwrite) void (^completionBlock)(SendMessageResult result);

@end


@implementation CCMessage

-(instancetype)initWithCommand:(NSString *)command
                  andArguments:(NSArray *)arguments
            andCompletionBlock:(void (^)(SendMessageResult result))completionBlock{
    
    self = [super init];
    
    if(self){
        self.command = command;
        self.arguments = arguments;
        self.completionBlock = completionBlock;
    }
    
    return self;
}

//Don't use this one
-(instancetype)init{
    [NSException raise:NSInternalInconsistencyException
                format:@"Need to use initWithURL:..."];
    
    return nil;
}


@end
