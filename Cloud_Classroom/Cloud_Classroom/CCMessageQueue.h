//
//  CCMessageQueue.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/17.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMessage.h"

@interface CCMessageQueue : NSObject

@property (nonatomic,readonly) BOOL isEmpty;

-(CCMessage *)popMessage;

-(void)pushMessage:(CCMessage *)message;

-(void)removeAllMessages;

@end
