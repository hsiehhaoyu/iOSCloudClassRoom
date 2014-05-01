//
//  CCClassTabBarController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCClassTabBarController.h"
#import "CCMessageCenter.h"
#import "CCAppDelegate.h"
#import "CCMiscHelper.h"
#import "CCConfiguration.h"
#import "CCPictureViewController.h"
#import "CCTextViewController.h"

@interface CCClassTabBarController ()



@end

@implementation CCClassTabBarController

//For the case that not user leaves class himself/herself
-(void)classDismissed{
    [CCMiscHelper showAlertWithTitle:@"Class dismissed"
                          andMessage:@"Class has been dismissed by the instructor."];
    
    
    [self backToClassList];
}

-(void)kickedOut{

    [CCMiscHelper showAlertWithTitle:@"Not in class"
                          andMessage:@"You're no longer in the class."];
    
    
    [self backToClassList];

}

-(void)quitClass{

    [self.serverMC quitClassWithClassID:self.classOnGoing.classID
                           onCompletion:^(SendMessageResult sentResult, NSString *status) {
         //Don't really care about the response from server, so just leave this blank
    }];
    
    [self backToClassList];
}

- (void)logout{
    [self.serverMC logoutAndTriggerLogoutBlock:YES onCompletion:nil];
}

-(void)backToClassList{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)pushContentWithFileName:(NSString *)fileName andType:(NSString *)fileType{

    [self.serverMC
     pushContentWithClassID:self.classOnGoing.classID
     andContentID:fileName andContentType:fileType
     onCompletion:^(SendMessageResult sentResult, NSString *status) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if(sentResult == SendMessageResultSucceeded){
                 
                 if([status isEqualToString:SUCCESS] || [status isEqualToString:ALREADY_IN_CLASS]){
                     
                     [CCMiscHelper showAlertWithTitle:@"Content pushed"
                                           andMessage:@"Succeeded"];
                     
                 }else if([status isEqualToString:NOT_LOGIN]){
                     
                     //no need to do things here, will be logged out automatically
                     
                 }else if([status isEqualToString:INVALID_CLASS_ID]){
                     
                     [self classDismissed];
                     
                 }else if([status isEqualToString:NO_PERMISSION]){
                     
                     [CCMiscHelper showAlertWithTitle:@"Can't push the content"
                                           andMessage:@"You are not the presenter"];
                 
                 }else{
                 
                     NSLog(@"Unknown status received when pushing content");
                 
                 }
                 
                 
             }else{
             
                 [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
                 
             }
       
        });
    }];
    
}

-(void)getPresentTokenAndOnCompletion:(void (^)(BOOL))completion{

    if(!completion){
        NSLog(@"No completion block in getPresentToken in TabBar, action abort");
        return;
    }
    
    [self.serverMC
     getPresentTokenWithClassID:self.classOnGoing.classID
     onCompletion:^(SendMessageResult sentResult, NSString *status,
                    NSString *classID, NSString *className) {
     
         dispatch_async(dispatch_get_main_queue(), ^{
             if(sentResult == SendMessageResultSucceeded){
                 if([status isEqualToString:SUCCESS]){
                    
                     self.isPresenter = YES;
                     completion(YES);
                     
                 }else if([status isEqualToString:NOT_LOGIN]){
                     
                     //no need to do things here, will be logged out automatically
                     
                 }else if([status isEqualToString:INVALID_CLASS_ID]){
                     
                     [self classDismissed];
                 
                 }else if([status isEqualToString:NO_PERMISSION] || [status isEqualToString:ALREADY_PRESENTER]){
                 
                     [CCMiscHelper showAlertWithTitle:@"Is presenter"
                                           andMessage:@"You are already the presenter"];
                     
                     self.isPresenter = YES;
                     completion(YES);
                 
                 }else if([status isEqualToString:DENIED]){
                     
                     [CCMiscHelper showAlertWithTitle:@"Denined"
                                           andMessage:@"You cannot to get presentation right"];
                     
                     self.isPresenter = NO;
                     completion(NO);
                     
                 }else if([status isEqualToString:NOT_IN_CLASS]){
                 
                     [self kickedOut];
                 
                 }else{
                     
                     NSLog(@"Unknown status received when getting presentation token");
                     
                 }
                 
             }else{
                 [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
             }
             
         });
         
     }];
    
}

-(void)checkLatestContent{
    
    [self.serverMC
     queryLatestContentWithClassID:self.classOnGoing.classID
     onCompletion:^(SendMessageResult sentResult,
                    NSString *status,
                    NSString *classID,
                    NSString *contentID) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if(sentResult == SendMessageResultSucceeded){
                 if([status isEqualToString:SUCCESS]){
                     
                     [self receivedPushContentNotifyWithClassID:classID
                                                   andContentID:contentID];
                     
                 }else if([status isEqualToString:NOT_LOGIN]){
                     
                     //no need to do things here, will be logged out automatically
                     
                 }else if([status isEqualToString:INVALID_CLASS_ID]){
                     
                     [self classDismissed];
                     
                 }else if([status isEqualToString:NOT_IN_CLASS]){
                     
                     [self kickedOut];
                     
                 }else if([status isEqualToString:NO_CONTENT]){
                     
                     [CCMiscHelper showAlertWithTitle:@"No content"
                                           andMessage:@"Current no content available"];
                     
                 }else{
                     
                     NSLog(@"Unknown status received when querying latest class token");
                     
                 }
                 
             }else{
                 [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
             }
             
         });
         
    
}];
    

}

-(void)receivedPushContentNotifyWithClassID:(NSString *)classID
                               andContentID:(NSString *)contentID{
    
    NSString *contentType = IMAGE_TYPE;
    
    if(![classID isEqualToString:self.classOnGoing.classID]){
        NSLog(@"The push content is not for this class");
        return;
    }
    
    UIViewController *currentVC = [CCMiscHelper getTopViewController];
    
    if([contentType isEqualToString:IMAGE_TYPE]){
        
        self.latestImageContentID = contentID;
        
        if([currentVC isMemberOfClass:[CCPictureViewController class]]){
            
            [((CCPictureViewController *)(currentVC))
             downloadContentWithFileName:contentID];
            
        }
        
        
        
    }else if([contentType isEqualToString:TEXT_TYPE]){
        
        self.latestTextContentID = contentID;
        
        if([currentVC isMemberOfClass:[CCTextViewController class]]){
            
            [((CCTextViewController *)(currentVC))
             downloadContentWithFileName:contentID];
            
        }
        
        
    }else{
        NSLog(@"incorrect content type received.");
    }

}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
    //Get the MessageCenter in AppDelegate
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.serverMC = appDelegate.serverMessageCenter;
    
    self.s3SM = [[CCS3ServerManager alloc] init];
    
    self.isPresenter = NO;
    
    __weak CCClassTabBarController *weakSelf = self;
    
    //Set what to do if receive certain indepentent message from server
    self.serverMC.receivedPushContentNotifyBlock = ^(NSString *classID,NSString *contentID){
        
        [weakSelf receivedPushContentNotifyWithClassID:classID
                                          andContentID:contentID];
        
    };
    
    self.serverMC.receivedKickUserIndBlock = ^(NSString *status,NSString *classId,NSString *className){
        [weakSelf kickedOut];
    };
    
    self.serverMC.receivedRetrievePresentTokenIndBlock = ^(NSString *classID, NSString *className){
        weakSelf.isPresenter = NO;
        
        SEL presenterStatusUpdateSEL = NSSelectorFromString(@"presenterStatusUpdate");
        
        if ([weakSelf.presentedViewController respondsToSelector:presenterStatusUpdateSEL]){
            [weakSelf.presentedViewController performSelector:presenterStatusUpdateSEL];
        }
    };
    
    
}

-(void)dealloc{
    
    [self.serverMC setAllBlocksToNilExceptLogoutBlock];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
