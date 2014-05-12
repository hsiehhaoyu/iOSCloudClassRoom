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

//====== Blocks ==========

//What to do after logout
//Since not only when user click logout but also when encountered
//an error state will logout function be executed, this logoutBlock
//is important to clean all memorized stuffs in controller/model
//and go back to login page. Therefore, a purpose of this logoutBlock
//is that program can be recovered from error state.
@property (strong,atomic) void (^logoutBlock)();

//What to do if receive a message from server that is not a response for a request we sent
@property (strong,atomic) void (^receivedKickUserIndBlock)(NSString *status,NSString *classId,NSString *className);
@property (strong,atomic) void (^receivedPushContentNotifyBlock)(NSString *classID,NSString *contentID);
//@property (strong,atomic) void (^receivedCondPushContentGetNotifyBlock)(NSString *command, NSArray *arguments);
@property (strong,atomic) void (^receivedChangePresentTokenReqBlock)(NSString *studentName,NSString *classID);
//@property (strong,atomic) void (^receivedChangePresentTokenIndBlock)(NSString *command, NSArray *arguments);
@property (strong,atomic) void (^receivedRetrievePresentTokenIndBlock)(NSString *classID, NSString *className);

//indicate whether is logged in now
@property (nonatomic,readonly) BOOL isLoggedIn;

//===== Send request-response messages
-(void)loginWithUserID:(NSString *)userID
           andPassword:(NSString *)password
         andDeviceType:(NSString *)deviceType
          onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)logoutAndTriggerLogoutBlock:(BOOL)triggerLogoutBlock
                      onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)createClassWithName:(NSString *)className
              onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                     NSString *classID))completion;

-(void)listClassesAndOnCompletion:(void (^)(SendMessageResult sentResult,
                                            NSString *status, NSInteger numOfClasses,
                                            NSArray *classes))completion;

-(void)deleteClassWithClassID:(NSString *)classID
                 onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)joinClassWithClassID:(NSString *)classID
               onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                      NSString *classID, NSString *className))completion;

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
                 onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

//
//-(void)getPushedContentWithClassID:(NSString *)classID
//                      andContentID:(NSString *)contentID
//                      onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
//                                             NSString *contentID, NSString *contentType,
//                                             NSInteger numOfBytes, NSData *contentData))completion;

//-(void)conditionalPushContentWithClassID:(NSString *)classID
//                            andContentID:(NSString *)contentID
//                            onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;
//

-(void)getPresentTokenWithClassID:(NSString *)classID
                     onCompletion:(void (^)(SendMessageResult sentResult, NSString *status,
                                            NSString *classID, NSString *className))completion;



-(void)retrievePresentTokenWithClassID:(NSString *)classID
                          onCompletion:(void (^)(SendMessageResult sentResult, NSString *status))completion;

-(void)queryLatestContentWithClassID:(NSString *)classID
                        onCompletion:(void (^)(SendMessageResult sentResult,
                                               NSString *status,
                                               NSString *classID,
                                               NSString *contentID))completion;

//======= Send one way messages (will have no response) ==================
-(void)respondToChangePresenterWithClassID:(NSString *)classID
                       andNewPresenterName:(NSString *)newPresenter
                               andDecision:(NSString *)decision
                              onCompletion:(void (^)(SendMessageResult sentResult))completion;

//======= Others ==========
-(void)setAllBlocksToNilExceptLogoutBlock;
-(void)closeServerConnection;
-(void)removeMessageFromSentMessages:(CCMessage *)message;
-(BOOL)isSentMessagesEmpty;
@end
