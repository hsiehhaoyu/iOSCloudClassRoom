//
//  CCS3ServerManager.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCS3ServerManager : NSObject

-(void)downloadFromS3WithFileName:(NSString *)fileName
                     onCompletion:(void (^)(BOOL success,
                                            NSData *downloadData))completion;

-(void)uploadToS3WithFileName:(NSString *)fileName
                       andData:(NSData *)data
                  onCompletion:(void (^)(BOOL success))completion;

@end
