//
//  CCMessageCenter.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/18.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMessage.h"


@interface CCMessageCenter : NSObject

//Blocks
//What to do after logout
//Since not only when user click logout but also when encountered
//an error state will logout function be executed, this logoutBlock
//is important to clean all memorized stuffs in controller/model
//and go back to login page. Therefore, a purpose of this logoutBlock
//is that program can be recovered from error state.
@property (strong,atomic) void (^logoutBlock)();
//What to do if receive a message from server that is not a response for a request we sent
@property (strong,atomic) void (^receivedRequestBlock)(NSString *command, NSArray *arguments);

@property (nonatomic,readonly) BOOL isLoggedIn;

-(void)loginWithUserID:(NSString *)userID
           andPassword:(NSString *)password
         andDeviceType:(NSString *)deviceType
          onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)logoutAndOnCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)createClassWithName:(NSString *)className
              onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                     NSString *classID))completion;

-(void)listClassesAndOnCompletion:(void (^)(SendMessageResult sentResult,
                                            NSString *status, NSInteger numOfClasses,
                                            NSArray *classes))completion;

-(void)deleteClassWithClassID:(NSString *)classID
                 onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)joinClassWithClassID:(NSString *)classID
               onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)queryClassInfoWithClassID:(NSString *)classID
                    onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                           NSString *instructorName, NSInteger numOfStudents,
                                           NSArray *studentNames))completion;

-(void)quitClassWithClassID:(NSString *)classID
               onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;


-(void)kickStudentWithClassID:(NSString *)classID
               andStudentName:(NSString *)studentName
                 onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;


-(void)pushContentWithClassID:(NSString *)classID
                 andContentID:(NSString *)contentID
               andContentType:(NSString *)contentType
                andNumOfBytes:(NSInteger)numOfBytes
               andContentData:(NSData *)contentData
                 onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;


-(void)getPushedContentWithClassID:(NSString *)classID
                      andContentID:(NSString *)contentID
                      onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                             NSString *contentID, NSString *contentType,
                                             NSInteger numOfBytes, NSData *contentData))completion;

-(void)conditionalPushContentWithClassID:(NSString *)classID
                            andContentID:(NSString *)contentID
                            onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;


-(void)getPresentTokenWithClassID:(NSString *)classID
                     onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;


-(void)retrievePresentTokenWithClassID:(NSString *)classID
                          onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)respondToChangePresenterWithClassID:(NSString *)classID
                       andNewPresenterName:(NSString *)newPresenter
                               andDecision:(NSString *)decision
                              onCompletion:(void (^)(SendMessageResult sentResult))completion;

@end
