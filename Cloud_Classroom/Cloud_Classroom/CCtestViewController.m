//
//  CCtestViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/19.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCtestViewController.h"
#import "CCMessageCenter.h"
#import "CCAppDelegate.h"
#import "CCClass.h"

@interface CCtestViewController ()

@property (strong,atomic) CCMessageCenter *serverMC;

@end

@implementation CCtestViewController

- (IBAction)createClassButtonClicked:(id)sender {
    [self.serverMC createClassWithName:@"New Class 1"
                          onCompletion:^(SendMessageResult sentResult, NSString *status, NSString *classID) {
        
                              if(sentResult == SendMessageResultSucceeded){
                                  
                                  NSLog(@"Received Response. Status: %@, classID: %@", status, classID);
        
                              }else{
        
                                  NSLog(@"Connection has some problem, code: %ld", sentResult);
                              }
                          }];
}

- (IBAction)listClassButtonClicked:(id)sender {
    
    [self.serverMC listClassesAndOnCompletion:^(SendMessageResult sentResult, NSString *status, NSInteger numOfClasses, NSArray *classes) {
       
        if(sentResult == SendMessageResultSucceeded){
            NSLog(@"Number of classes: %ld", numOfClasses);
            for(int i=0; i<numOfClasses; i++){
                CCClass *class = classes[i];
                NSLog(@"Class %d: name: %@, id: %@, instructor: %@", i, class.className, class.classID, class.instructorName);
            }
        }else{
            NSLog(@"Connection has some problem, code: %ld", sentResult);
        }
    }];
}

- (IBAction)respondToChangePresenterButtonClicked:(id)sender {

    [self.serverMC respondToChangePresenterWithClassID:@"Class 1"
                                   andNewPresenterName:@"David"
                                           andDecision:@"OK"
                                          onCompletion:^(SendMessageResult sentResult) {
                                              
                                              NSLog(@"respond to ...message sent result: %ld", sentResult);
    
                                          }];

}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.serverMC = appDelegate.serverMessageCenter;
}

@end
