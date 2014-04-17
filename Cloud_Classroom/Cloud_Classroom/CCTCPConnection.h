//
//  CCTCPConnection.h
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/8.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>


#define READ_BUFFER_SIZE 1024
#define WRITE_BUFFER_SIZE 1024
#define MAX_PORT_NUM 65535

typedef NS_ENUM(NSInteger, TryToConnectResult) {
    TryToConnectResultNotInited,
    TryToConnectResultAlreadyConnected,
    TryToConnectResultAlreadyTrying,
    TryToConnectResultSucceeded,
    TryToConnectResultFailed
};

/* 
 * The possible results when trying to send data
 * Note that the differece between ReceiverHasNoCapacity means
 * when actually trying to write the outputStream, returned value
 * is zero. On the other hand, HasNoSpaceToSend use the BOOL
 * hasSpaceToSend, which will be YES if NSStreamEventHasSpaceAvailable
 * has been triggered, to verity whether available to send. (I think
 * this event indicates the condition of local buffer, but no suer.)
 */
typedef NS_ENUM(NSInteger, SendDataResult) {
    SendDataResultNilData,
    SendDataResultEmptyData, //data.length == 0 or e.g. for string, it means empty string
    SendDataResultErrorOccurred,
    SendDataResultReceiverHasNoCapacity,
    SendDataResultSucceeded,
    SendDataResultNotConnected,
    SendDataResultHasNoSpaceToSend
};

@interface CCTCPConnection : NSObject <NSStreamDelegate>


@property (atomic,readonly) BOOL isConnected;

@property (nonatomic,readonly) BOOL hasTriedToConnect;
@property (nonatomic,readonly) BOOL hasSuccessfullyConnected;

@property (atomic,readonly) BOOL hasSpaceToSend;

-(instancetype)initWithURL:(NSURL *)url andPort:(NSInteger)port;

-(void)tryToEstablishConnectionAndOnCompletion:(void (^)(TryToConnectResult result))completion;

-(void)sendString:(NSString *)string onCompletion:(void (^)(SendDataResult result))completion;

-(void)endConnection;

-(void)sendData:(NSData *)data onCompletion:(void (^)(SendDataResult result))completion;

-(BOOL)setWhatToDoWhenHasSpaceToSendWithBlock:(void (^)())block;
-(BOOL)setWhatToDoWhenHasBytesAvailableWithBlock:(void (^)(NSData *readData))block;
-(BOOL)setWhatToDoWhenHasErrorOccurredWithBlock:(void (^)())block;
-(BOOL)setWhatToDoWhenHasEndEncounteredWithBlock:(void (^)())block;

@end
