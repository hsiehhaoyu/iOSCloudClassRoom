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
    dispatch_async(dispatch_get_main_queue(), ^{
        [CCMiscHelper showAlertWithTitle:@"Class dismissed"
                              andMessage:@"Class has been dismissed by the instructor."];
    
        
        [self backToClassList];
    });
}

-(void)kickedOut{

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [CCMiscHelper showAlertWithTitle:@"Not in class"
                              andMessage:@"You're no longer in the class."];
    
    
        [self backToClassList];
    });

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
                     self.isPresenter = NO;
                     
                     [self updateCurrentViewControllerPresenterStatus];
                 
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

//Will also download it if new content available
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
                     
//                     if(![contentID isEqualToString:self.latestImageContentID] &&
//                        ![contentID isEqualToString:self.latestTextContentID]){
                     
#warning DoSomeChangeAfterImplementCache
                     //even if the same, we still download it, so that
                     //if user pushed a content, made some
                     //change, and then what to discard the change use
                     //refresh, he can't do it if we use if to
                     //to check latest content ID. If the future if
                     //we implement the cache mechanism, we probably
                     //could change to fetch the image from cache.
                     [self receivedNewContentNotifyWithClassID:classID
                                                      andContentID:contentID];
//                     }
                     
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

-(void)updateCurrentViewControllerPresenterStatus{

    SEL presenterStatusUpdateSEL = NSSelectorFromString(@"presenterStatusUpdate");
    
    UIViewController *currentVC = self.selectedViewController;
    
    if ([currentVC respondsToSelector:presenterStatusUpdateSEL]){
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            ((void (*)(id, SEL))[currentVC methodForSelector:presenterStatusUpdateSEL])(currentVC, presenterStatusUpdateSEL);
        });
    }

}

-(NSString *)determineFileTypeWithFileName:(NSString *)fileName{
    
    NSArray *supportedImageExtensions = @[@".tiff", @".tif", @".jpg", @".jpeg",
                                          @".gif", @".png", @".bmp", @".BMPf",
                                          @".ico", @".cur", @".xbm"];
    
    //check whether is image type
    for(NSString *extension in supportedImageExtensions){
        NSRange extensionRange = [fileName rangeOfString:extension];
        //If the string is at the end of the filaName, it's extension
        if(extensionRange.location + extensionRange.length == fileName.length)
        //if(extensionRange.location != NSNotFound)
            return IMAGE_TYPE;
    }
    
    //Now we treat all other cases are text file
    return TEXT_TYPE;
    

}

//Will also be called after query latest contentID, if new content available
-(void)receivedNewContentNotifyWithClassID:(NSString *)classID
                              andContentID:(NSString *)contentID{
    
    
    if(![classID isEqualToString:self.classOnGoing.classID]){
        NSLog(@"The push content is not for this class");
        return;
    }
    
    NSString *contentType = [self determineFileTypeWithFileName:contentID];
    
    UIViewController *currentVC = self.selectedViewController;
    
    //NOTE: in tab bar controller, the top view controller is always
    //tabBarController, the presentedViewController is always nil,
    //so need to use selectedViewController to get current VC
    /*
    NSLog(@"selectedVC: %@", [[currentVC class] description]);
    NSLog(@"presented VC: %@", [[self.presentedViewController class] description]);
    NSLog(@"topVC: %@", [[[CCMiscHelper getTopViewController] class] description]);
    */
    
    NSLog(@"Has new content received");
    
    if([contentType isEqualToString:IMAGE_TYPE]){
        
        if(![self.latestImageContentID isEqualToString:contentID]){
        
            self.latestImageContentID = contentID;
            
            if([currentVC isMemberOfClass:[CCPictureViewController class]]){
                
                [((CCPictureViewController *)(currentVC))
                 downloadContentWithFileName:contentID];
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.selectedViewController = [self.viewControllers objectAtIndex:0];
                });
            }
            
        }
        
    }else if([contentType isEqualToString:TEXT_TYPE]){
        
        if(![self.latestTextContentID isEqualToString:contentID]){
        
            self.latestTextContentID = contentID;
            
            if([currentVC isMemberOfClass:[CCTextViewController class]]){
                
                [((CCTextViewController *)(currentVC))
                 downloadContentWithFileName:contentID];
                
            }else{
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.selectedViewController = [self.viewControllers objectAtIndex:1];
                });
            }
        
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
        
        [weakSelf receivedNewContentNotifyWithClassID:classID
                                          andContentID:contentID];
        
    };
    
    self.serverMC.receivedKickUserIndBlock = ^(NSString *status,NSString *classId,NSString *className){
        
        if([classId isEqualToString:weakSelf.classOnGoing.classID]){
            [weakSelf kickedOut];
        }
    };
    
    self.serverMC.receivedRetrievePresentTokenIndBlock = ^(NSString *classID, NSString *className){
        weakSelf.isPresenter = NO;
        
        [weakSelf updateCurrentViewControllerPresenterStatus];
    };
    
    //set what to do when receive push notification
    appDelegate.receivedPushNotificationBlock = ^(NSDictionary *receivedMessage){
        //for now we don't care the content of push notification,
        //we check for new class content whenever receive a push notification
        [weakSelf checkLatestContent];
    };

}

-(void)dealloc{
    
    [self.serverMC setAllBlocksToNilExceptLogoutBlock];
    
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.receivedPushNotificationBlock = nil;
    
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
