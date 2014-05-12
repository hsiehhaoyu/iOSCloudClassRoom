//
//  CCMessageQueue.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/17.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCMessageQueue.h"

@interface CCMessageQueue ()

@property (strong,atomic) NSMutableArray *queue;

@end

@implementation CCMessageQueue


//return nil if no message in the queue
-(CCMessage *)popMessage{
    if(self.queue.count > 0){
        
        CCMessage *message = [self.queue firstObject];
        
        [self.queue removeObject:message];
        
        return message;
        
    }else{
    
        return nil;
        
    }
}

//won't push if it's nil
-(void)pushMessage:(CCMessage *)message{
    
    if(message){
        [self.queue addObject:message];
    }
}

-(void)removeAllMessages{
    [self.queue removeAllObjects];
}

-(void)removeMessage:(CCMessage *)message{
    [self.queue removeObject:message];
}

-(BOOL)isMessageInQueue:(CCMessage *)message{

    for(CCMessage *msg in self.queue){
        if([msg isEqual:message]){
            return YES;
        }
    }
    return NO;
}

-(BOOL)isEmpty{

    return (self.queue.count == 0);

}

-(instancetype)init{
    self = [super init];
    
    if(self){
        self.queue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end
