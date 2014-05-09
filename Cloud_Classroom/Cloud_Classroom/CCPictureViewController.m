//
//  CCPictureViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCPictureViewController.h"
#import "CCClassTabBarController.h"
#import "CCClassHelper.h"
#import "CCS3ServerManager.h"
#import "CCMessageCenter.h"
#import "CCConfiguration.h"
#import "CCMiscHelper.h"

@interface CCPictureViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *pictureNavigationItem;

@property (weak, nonatomic) CCS3ServerManager *s3SM;

@property (weak,atomic) CCMessageCenter *serverMC;

@property (weak, nonatomic) IBOutlet UIImageView *contentImageView;

@property (strong,nonatomic) NSString *currentContentID;

@end

@implementation CCPictureViewController



-(void)getPresentToken{
    
    [((CCClassTabBarController *)self.tabBarController) getPresentTokenAndOnCompletion:^(BOOL isPresenter) {
        [self presenterStatusUpdate];
    }];

}

-(void)getLatestContent{

    [((CCClassTabBarController *)(self.tabBarController)) checkLatestContent];

}

-(void)pushContent{
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID new] UUIDString]];
    NSLog(@"%@", fileName);
    NSData *imageData = UIImageJPEGRepresentation(self.contentImageView.image, 0.8);
    
    [self.s3SM uploadToS3WithFileName:fileName andData:imageData onCompletion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(success){
                
                NSLog(@"Push text succeeded!");
                //tell our server 
                [((CCClassTabBarController *)(self.tabBarController)) pushContentWithFileName:fileName andType:IMAGE_TYPE];
                
                //May need to change to send out our server succeed
                self.currentContentID = fileName;
                ((CCClassTabBarController *)(self.tabBarController)).latestImageContentID = fileName;
                
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
                
                self.contentImageView.image = [[UIImage alloc] initWithData:downloadData];
                
                self.currentContentID = fileName;
                
            }else{
                
                [CCMiscHelper showAlertWithTitle:@"Failed to download"
                                      andMessage:@"There's a new content, but failed to download it."];
            
            }
            
        });
        
    }];
    
}

-(void)presenterStatusUpdate{
    
    NSArray *defaultRightBarButtonItems = [CCClassHelper
                                           getConstClassRightBarButtonItemsWithSender:self
                                           isPresenter:((CCClassTabBarController *)(self.tabBarController)).isPresenter];
    
    if(((CCClassTabBarController *)(self.tabBarController)).isPresenter){
        
        UIBarButtonItem *pickImageBarButtonItem = [[UIBarButtonItem alloc]
                                        initWithTitle:@"I"
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(pickImage)];

        self.pictureNavigationItem.rightBarButtonItems = [defaultRightBarButtonItems arrayByAddingObject:pickImageBarButtonItem];
        
    }else{
    
        self.pictureNavigationItem.rightBarButtonItems = defaultRightBarButtonItems;
        
    }
    
    

}


//UIImagePicker related delegate functions
//Reference: http://aws.amazon.com/articles/SDKs/iOS/3002109349624271
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    self.contentImageView.image = selectedImage;
    
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)pickImage
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}



- (void)viewWillAppear:(BOOL)animated{
    
    //this might change according to the change in different tab, so put here
    [self presenterStatusUpdate];
    
    
    //check whether we received a new content
    NSString *latestImageContentID =((CCClassTabBarController *)(self.tabBarController)).latestImageContentID;
    
    if(latestImageContentID){//not nil
        if(![latestImageContentID isEqualToString:self.currentContentID]){
            [self downloadContentWithFileName:latestImageContentID];
        }
    }else{
        [self getLatestContent];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add buttons programatically
    self.pictureNavigationItem.leftBarButtonItems = [CCClassHelper getConstClassLeftBarButtonItemsWithSender:self];
    
    self.serverMC = ((CCClassTabBarController *)(self.tabBarController)).serverMC;
    
    self.s3SM = ((CCClassTabBarController *)(self.tabBarController)).s3SM;
    
    self.contentImageView.image = [UIImage imageNamed:@"NoSlideAvailable.jpg"];
    
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
