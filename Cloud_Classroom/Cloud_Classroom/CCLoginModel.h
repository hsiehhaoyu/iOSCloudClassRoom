//
//  CCLoginModel.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCCommunicationHandler.h"


@interface CCLoginModel : NSObject

-(void)loginWithUserID:(NSString *)userID andPassword:(NSString *)password
          onCompletion:(void (^)(LoginResult result))completion;


-(void)sendMessage;

@end
