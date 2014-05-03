//
//  CCS3ServerManager.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/30.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//
//Use Amazon iOS SDK 1.7.1

#import "CCS3ServerManager.h"
#import <AWSS3/AWSS3.h>
#import <AWSRuntime/AWSRuntime.h>
#import "CCConfiguration.h"
#import "CCMiscHelper.h"

@interface CCS3ServerManager ()

@property (nonatomic, strong) AmazonS3Client *s3;

@property (nonatomic, strong) NSData *downloadData;

@end

@implementation CCS3ServerManager

//Reference: http://stackoverflow.com/questions/11785872/amazon-s3-iphone-sdk-downloading-images
-(void)downloadFromS3WithFileName:(NSString *)fileName
                     onCompletion:(void (^)(BOOL, NSData *))completion{
    
    if(!fileName || !completion){
    
        [NSException raise:NSInternalInconsistencyException
                    format:@"Parameters in downloadFromS3 function can't be nil!"];
        return;
       
    }
    

    
    if([CCMiscHelper isStringEmpty:fileName] ||
       [CCMiscHelper isStringEmpty:BUCKET_NAME]){
        NSLog(@"File name or bucket name is empty.");
        completion(NO, nil);
        return;
    }
    
    
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc]
                                            initWithKey:fileName
                                            withBucket:BUCKET_NAME];
    
    dispatch_async([CCS3ServerManager sharedS3Queue], ^{
        @try{ //need to catch exception, since if file doesn't exist it will raise an exception
            //start to download
            S3GetObjectResponse *getObjectResponse = [self.s3 getObject:getObjectRequest];
        
            if(!(getObjectResponse.error)){ //no error occurred
                
                if(getObjectResponse.body){ //has gotten something
                    
                    NSData *downloadData = getObjectResponse.body;
                    completion(YES, downloadData);
                    
                }else{
                    
                    NSLog(@"There was no value in the response body (downloadData)");
                    completion(NO, nil);
                }
                
            }else{ // response.error != nil
                
                NSLog(@"There was an error in the response while getting file. error: %@",
                      getObjectResponse.error.description);
                
                completion(NO, nil);
            }
        }@catch(NSException *exception){
            NSLog(@"There was an exception when downloading from s3: %@",exception.description);
            completion(NO, nil);
        }
    });
}


//Reference: http://aws.amazon.com/articles/3002109349624271
//https://github.com/awslabs/aws-sdk-ios-samples
- (void)uploadToS3WithFileName:(NSString *)fileName
                       andData:(NSData *)data
                  onCompletion:(void (^)(BOOL))completion{
    
    if(!fileName || !completion){
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"Parameters in uploadToS3 function can't be nil!"];
        return;
        
    }
    
    //Don't crash if data is nil. Becauese I'm not sure whether there is any unexpected case that will make data = nil
    if(!data){
        
        NSLog(@"Data is nil in uploadToS3! Action abort, check what happened.");
        completion(NO);
        return;
    
    }
    
    //BTW, empty data is allowed, so we don't check it.
    if([CCMiscHelper isStringEmpty:fileName] ||
       [CCMiscHelper isStringEmpty:BUCKET_NAME]){
        NSLog(@"File name or bucket name is empty.");
        completion(NO);
        return;
    }
    
    S3PutObjectRequest *putObjectRequest = [[S3PutObjectRequest alloc]
                                            initWithKey:fileName
                                            inBucket:BUCKET_NAME];
    
    //It seem content type is not necessary in our application
    //putObjectRequest = IMAGE_CONTENT_TYPE;
    
    putObjectRequest.data = data;

    
    dispatch_async([CCS3ServerManager sharedS3Queue], ^{
        @try{
            S3PutObjectResponse *putObjectResponse = [self.s3 putObject:putObjectRequest];
            
            if(!(putObjectResponse.error)){ //no error occurred
                
                completion(YES);
                
            }else{
                
                NSLog(@"There was an error in the response while uploading file. error: %@",
                      putObjectResponse.error.description);
                completion(NO);
            }
            
            //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }@catch(NSException *exception){
            NSLog(@"There was an exception when uploading to s3: %@",exception.description);
            completion(NO);
        }
    });
}

//Reference: http://stackoverflow.com/questions/19421283/do-2-objects-creating-serial-queues-with-the-same-name-share-the-same-queue
+(dispatch_queue_t)sharedS3Queue
{
    static dispatch_queue_t sharedS3Queue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedS3Queue = dispatch_queue_create("edu.columbia.sharedS3Queue", NULL);
    });
    
    return sharedS3Queue;
}


-(instancetype)init{

    self = [super init];
    
    if(self){
        
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:S3_ACCESS_KEY
                                              withSecretKey:S3_SECRET_KEY];
    
    }
    
    return self;
}

@end
