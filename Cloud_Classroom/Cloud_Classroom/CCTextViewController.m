//
//  CCTextViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCTextViewController.h"
#import "CCClassTabBarController.h"
#import "CCClassHelper.h"
#import "CCS3ServerManager.h"
#import "CCMessageCenter.h"
#import "CCConfiguration.h"
#import "CCMiscHelper.h"

@interface CCTextViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *textNavigationItem;

@property (weak, nonatomic) CCS3ServerManager *s3SM;

@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@property (weak, atomic) CCMessageCenter *serverMC;

@property (strong,nonatomic) NSString *currentContentID;

@end

@implementation CCTextViewController

-(void)getPresentToken{
    
    [((CCClassTabBarController *)self.tabBarController) getPresentTokenAndOnCompletion:^(BOOL isPresenter) {
        [self presenterStatusUpdate];
    }];
    
}

-(void)getLatestContent{

    [((CCClassTabBarController *)(self.tabBarController)) checkLatestContent];

}

-(void)pushContent{
    
    NSString *fileName = [NSString stringWithFormat:@"%@.txt",[[NSUUID new] UUIDString]];
    NSLog(@"%@", fileName);
    NSData *textData = [self.contentTextView.text dataUsingEncoding:NSASCIIStringEncoding];
    [self.s3SM uploadToS3WithFileName:fileName andData:textData onCompletion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(success){
                
                NSLog(@"Push text succeeded!");
                //tell our server
                [((CCClassTabBarController *)(self.tabBarController)) pushContentWithFileName:fileName andType:TEXT_TYPE];
                
                //May need to change to send out our server succeed
                self.currentContentID = fileName;
                ((CCClassTabBarController *)(self.tabBarController)).latestTextContentID = fileName;
                
            }else{
            
                [CCMiscHelper showAlertWithTitle:@"Failed to upload"
                                      andMessage:@"Failed when uploading the content."];
                
            }
        });
    }];

}

-(void)downloadContentWithFileName:(NSString *)fileName{

    [self.s3SM downloadFromS3WithFileName:fileName onCompletion:^(BOOL success, NSData *downloadData) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(success){
                self.contentTextView.text = [[NSString alloc] initWithData:downloadData encoding:NSASCIIStringEncoding];
                
                
                self.currentContentID = fileName;
            
            }else{
                [CCMiscHelper showAlertWithTitle:@"Failed to download"
                                      andMessage:@"There's a new content, but failed to download it."];
            }
            
        });
        
    }];

}

-(void)presenterStatusUpdate{
    
    self.textNavigationItem.rightBarButtonItems = [CCClassHelper
                                                   getConstClassRightBarButtonItemsWithSender:self
                                                   isPresenter:((CCClassTabBarController *)(self.tabBarController)).isPresenter];

    self.contentTextView.editable = ((CCClassTabBarController *)(self.tabBarController)).isPresenter;
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    
    [textView resignFirstResponder];

}

//Used to resign keyboard when touch out side of textFields
//Reference: http://stackoverflow.com/questions/5306240/iphone-dismiss-keyboard-when-touching-outside-of-textfield
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated{

    //this might change according to the change in different tab, so put here
    [self presenterStatusUpdate];
    
    //check whether we received a new content
    NSString *latestTextContentID =((CCClassTabBarController *)(self.tabBarController)).latestTextContentID;
    
    if(latestTextContentID){//not nil
        if(![latestTextContentID isEqualToString:self.currentContentID]){
            [self downloadContentWithFileName:latestTextContentID];
        }
    }else{
        [self getLatestContent];
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add buttons programatically
    self.textNavigationItem.leftBarButtonItems = [CCClassHelper getConstClassLeftBarButtonItemsWithSender:self];
    
    self.serverMC = ((CCClassTabBarController *)(self.tabBarController)).serverMC;
    
    self.s3SM = ((CCClassTabBarController *)(self.tabBarController)).s3SM;
    
    self.contentTextView.delegate = self;
    
    NSLog(@"text editor tab loaded");
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
