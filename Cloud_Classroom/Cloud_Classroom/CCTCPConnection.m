//
//  CCTCPConnection.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/8.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

/*
 * Reference:
 * http://www.raywenderlich.com/3932/networking-tutorial-for-ios-how-to-create-a-socket-based-iphone-app-and-server
 * https://developer.apple.com/library/ios/documentation/cocoa/Conceptual/Streams/Articles/NetworkStreams.html
 * https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Streams/Articles/WritingOutputStreams.html
 */

#import "CCTCPConnection.h"

@interface CCTCPConnection ()

@property (strong,atomic) NSInputStream *inputStream;
@property (strong,atomic) NSOutputStream *outputStream;

@property (strong,nonatomic) NSString *urlString;
@property (nonatomic) NSInteger port;

//Blocks
@property (strong,atomic) void (^completionBlockOfTryToConnect)(TryToConnectResult);
@property (strong,atomic) void (^hasSpaceToSendBlock)();
@property (strong,atomic) void (^hasBytesAvailableBlock)(NSData *);
@property (strong,atomic) void (^hasErrorOccurredBlock)();
@property (strong,atomic) void (^hasEndEncounteredBlock)();

//used in stream:handleEvent
//@property (atomic) BOOL hasOpenCompletedEventCalled;
@property (atomic) BOOL hasErrorOccurredEventCalled;

/* 
 * Indicate whether is connected.
 */
@property (atomic,readwrite) BOOL isConnected;

/* Indicate whether is trying to connect now.*/
@property (atomic) BOOL isTryingToConnect;

/* 
 * No real usage, just for user to know whether this connection
 * has tried to connect. (not necessary have to be successfully
 * connected before)
 */
@property (nonatomic,readwrite) BOOL hasTriedToConnect;
/* The same, no real usage */
@property (nonatomic,readwrite) BOOL hasSuccessfullyConnected;

/* Indicate whether there is space available to send*/
@property (atomic,readwrite) BOOL hasSpaceToSend;

@end

@implementation CCTCPConnection

/* 
 * try to establish the connection
 * Note: will also call completion in stream:handleEvent
 * on success and failure
 */
-(void)tryToEstablishConnectionAndOnCompletion:(void (^)(TryToConnectResult result))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    if(!self.urlString){
        
        NSLog(@"Not init yet!");
        completion(TryToConnectResultNotInited);
        
    }else if(self.isConnected){
        
        NSLog(@"Already connected");
        completion(TryToConnectResultAlreadyConnected);
    
    }else if(self.isTryingToConnect) {
    
        NSLog(@"Already trying to connect, please wait.");
        completion(TryToConnectResultAlreadyTrying);
    
    }else{
        
        self.isTryingToConnect = YES;
        self.hasTriedToConnect = YES;
        self.hasSpaceToSend = NO;
        
        //self.hasOpenCompletedEventCalled = NO;
        self.hasErrorOccurredEventCalled = NO;
        
        //completion will be called in stream:handleEvent
        self.completionBlockOfTryToConnect = completion;
        
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        /* CF: Core Foundation
         * __bridge cast please refer to:
         * https://developer.apple.com/library/ios/documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html
         * http://stackoverflow.com/questions/9859639/ios-bridge-vs-bridge-transfer
         * http://stackoverflow.com/questions/7036350/arc-and-bridged-cast
         */
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.urlString, (UInt32)self.port, &readStream, &writeStream);
        self.inputStream = (__bridge_transfer NSInputStream *)readStream;
        self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
        
        self.inputStream.delegate = self;
        self.outputStream.delegate = self;
        
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        
        [self.inputStream open];
        [self.outputStream open];
        
        
        NSLog(@"Start trying to estalish the connection.");
        
    }
}

//send a string
//return NO if not connected
-(void)sendString:(NSString *)string onCompletion:(void (^)(SendDataResult))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    if(!string){
        
        completion(SendDataResultNilData);
        
    }else if([string isEqualToString:@""]){
        
        completion(SendDataResultEmptyData);
    
    }else{
    
        NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
        
        [self sendData:data onCompletion:^(SendDataResult result) {
            completion(result);
        }];
        
    }
}


//send data
-(void)sendData:(NSData *)data onCompletion:(void (^)(SendDataResult))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    //put into sharedSendingQueue to send
    //Note that sometimes this function will be called in
    //main thread (if isConnected when sending), and some
    //time this will be called in sharedNetworkQueue(if
    //is triggered by stream:handleEvent:, e.g.
    //stream:handleEvent: -> hasSpaceToSendBlock -> ...)
    //Therefore, to avoid block the main thread, use
    //dispatch again(but won't affect if already in shared queue)
    dispatch_async([CCTCPConnection sharedNetworkQueue], ^{
    
        if(!self.isConnected){
            completion(SendDataResultNotConnected);
        }else if(!data){
            completion(SendDataResultNilData);
        }else if([data length] == 0){
            completion(SendDataResultEmptyData);
        }else if(!self.hasSpaceToSend){
            completion(SendDataResultHasNoSpaceToSend);
        }else{
            
            NSInteger sentBytes;
            
            /*
             * For any result, this should set to NO
             * Also, put right before write action, since I want to reduce the
             * possibility that NSStreamEventHasSpaceAvailable being called during
             * the execution of this function and affect accuracy of hasSpaceToSend.
             * (May or may not occur, but in case) The worst case is that if I put
             * this line after write action, and the event is triggered between
             * write action and set to NO. Thus in the end although there's space,
             * but hasSpaceToSend is NO, and since the event won't be called again 
             * if value isn't changed, this connection can't send data anymore.
             * If we put before, the worest case is that no space but hasSpace to 
             * send is YES. This will just cause SendDataResultErrorOccurred or
             * SendDataResultReceiverHasNoCapacity.
             */
            self.hasSpaceToSend = NO;
            
            sentBytes = [self.outputStream write:[data bytes] maxLength:[data length]];
            
            NSLog(@"SentBytes: %ld", (long)sentBytes);
            
            if (sentBytes == -1) {
                completion(SendDataResultErrorOccurred);
            }else if(sentBytes == 0){
                completion(SendDataResultReceiverHasNoCapacity);
            }else{
                completion(SendDataResultSucceeded);
            }
            
        }

    });

}


/* 
 * Handle events
 * Note: When establishing a connection is going to failed, there're 3 possible
 * cases could happen:
 * 1. When url is nil, the NSStreamEventOpenCompleted(2) will be called first, and
      then EndEncountered(1) will be called immediately. This is kind of weird,
      but I have eliminated this case in initWithURL:andPort:
   2. If URL is correct, which means the machine with that URL does exist and 
      reachable, but the port is not opened, the ErrorOccurred(2) will be called
      immediately.
   3. If URL is incorrect or unreachable, the ErrorOccurred(2) will be called 
      after timeout.
 * 
 * If connection established succeesfully, OpenCompleted(2) will be called immediately.
 *
 * (number) means how many times it will be called. It seems except EndEncountered is 
 * only called once, OpenCompleted and ErrorOccurred are both called twice everytime,
 * probably because there're two stream: inputStream and outputStream.
 */
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{

    //put into sharedNetworkQueue to send
    //Please refer to the note in the CCMessageCenter's
    //processReadyToSendMessage function for why I
    //put dispatch here and the mechanism of
    //this stream:handleEvent function regarding to
    //thread.
    dispatch_async([CCTCPConnection sharedNetworkQueue], ^{
        
        switch (eventCode) {
            case NSStreamEventOpenCompleted:
                
                NSLog(@"Connection established!");
                
                //Can't execute block here, since block may start to send something but
                //Space is not Available yet (and thus when doing outputStream write will
                //stuck there. When stucking there, even has space available, it cannot
                //call event, and therefore can't use)
                //Thus I decide to move all successfully handle events to hasSpaceAvailable
                
                //Since this will be called twice, only do things on the second call
                //if (self.hasOpenCompletedEventCalled == NO) {
                //    self.hasOpenCompletedEventCalled = YES;
                //}else{
                    //self.isConnected = YES;
                    //self.isTryingToConnect = NO;
                    //self.hasSuccessfullyConnected = YES;
                    
                    //self.completionBlockOfTryToConnect(TryToConnectResultSucceeded);
                    //self.completionBlockOfTryToConnect = nil; //release the block
                //}
                break;
                
            case NSStreamEventErrorOccurred://Any kind of failed, including can't establish connection
                
                NSLog(@"Connection failed!");
                
                if (self.isTryingToConnect) { //failed when trying to establish connection
                    //Since this will be called twice, only do things on the second call
                    if (self.hasErrorOccurredEventCalled == NO) {
                        self.hasErrorOccurredEventCalled = YES;
                    }else{
                        [self closeConnection];
                        //self.isConnected = NO; //already in closeConnection function
                        self.isTryingToConnect = NO;
                        self.completionBlockOfTryToConnect(TryToConnectResultFailed);
                        self.completionBlockOfTryToConnect = nil; //release the block, or retain cycle might occur
                    }
                }else{ //Connected before, but failed due to some reason
                    [self closeConnection];
                    if(self.hasErrorOccurredBlock){
                        self.hasErrorOccurredBlock();
                    }
                }
                
                [self releaseBlocks];
                break;
                
            case NSStreamEventHasBytesAvailable:
                
                NSLog(@"Got some data!");
                
                if(aStream == self.inputStream){
                    
                    NSLog(@"Got some data from inputStream");
                    
                    //unit: byte
                    uint8_t buffer[READ_BUFFER_SIZE];
                    NSInteger readLength;
                    
                    while([self.inputStream hasBytesAvailable]){
                        
                        NSLog(@"inputStream has bytes Available");
                        
                        readLength = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                        
                        NSLog(@"read length: %ld", (long)readLength);
                        
                        if(readLength > 0){ //got some data (will be 0 if nothing left)
                            
                            NSData *readData = [[NSData alloc] initWithBytes:buffer length:readLength];
                            
                            /* NSString *readString = [[NSString alloc] initWithBytes:buffer
                                                                            length:readLength
                                                                          encoding:NSASCIIStringEncoding];
                            */
                             
                            if(readData){ //did get something, not nil
                                if(self.hasBytesAvailableBlock){
                                    self.hasBytesAvailableBlock(readData);
                                }
                            }else{
                                NSLog(@"Weird! readLength > 0 but cannot get data!");
                            }
                        }
                    }
                    
                }
                
                break;
                
            case NSStreamEventHasSpaceAvailable:
                //Note: This will only be called once for a value change, so use
                //flag hasSpaceToSend to memorize whether there is a space.
                
                NSLog(@"Has space available called!");
                
                //Handle successfully connect events here
                if(self.isTryingToConnect){ //first time called after connect
                
                    self.isConnected = YES;
                    self.isTryingToConnect = NO;
                    self.hasSuccessfullyConnected = YES;
                    self.hasSpaceToSend = YES; //need before executing completion block
                    self.completionBlockOfTryToConnect(TryToConnectResultSucceeded);
                    self.completionBlockOfTryToConnect = nil; //release the block, or retain cycle might occur
                
                }else{ //usual cases
                    
                    self.hasSpaceToSend = YES;
                    
                }
                
                /* 
                 * Allowed to be nil, and can change to use KVO as well
                 * KVO might be more complex.
                 * Use block then need to make sure
                 * either block set to nil, or wrapped with other class, or don't use that class' stuff
                 Todo: add comparison between KVO and block
                 * In this block, if you're going to send anything, check BOOL hasSpaceToSend again before
                 * start to send.
                 * Space might have been used before here, so need to check self.hasSpaceToSend again. For
                 * example, user send something in completionBlockOfTryToConnect, or use KVO so that there 
                 * are possibilities that right
                 * after self.hasSpaceToSend being set, something being sent.
                 */
                if(self.hasSpaceToSendBlock && self.hasSpaceToSend){
                    self.hasSpaceToSendBlock();
                }
                
                break;
                
            case NSStreamEventEndEncountered:
                
                //[aStream close];
                //[aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                //Since this event will only be call once, I use closeConnection to close both stream
                [self closeConnection];
                
                //self.isConnected = NO; //already in closeConnection function
                self.isTryingToConnect = NO; //May not be necessary, but in case
                
                if(self.hasEndEncounteredBlock){
                    self.hasEndEncounteredBlock();
                }
                
                [self releaseBlocks];
                NSLog(@"Connection closed.");
                
                break;
                
            default:
                NSLog(@"Unknow event occurred! eventCode: %d", (int)eventCode);
                break;
        }
    });
}

//For user to end connection manually
-(void)endConnection{
    [self closeConnection];
    [self releaseBlocks];
}

//closeConnection(can be called again even has been closed)
//Not visible to user
-(void)closeConnection{
    
    if(self.inputStream){
        [self.inputStream close];
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    if(self.outputStream){
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    self.inputStream = nil;
    self.outputStream = nil;
    
    self.isConnected = NO;
    self.hasSpaceToSend = NO;
    
    NSLog(@"Close connection done.");
}

//release blocks (Whenever connection closed, clears all saved blocks to avoid possible retain cycle and other errors
-(void)releaseBlocks{
    self.hasSpaceToSendBlock = nil;
    self.hasBytesAvailableBlock = nil;
    self.hasErrorOccurredBlock = nil;
    self.hasEndEncounteredBlock = nil;
    //self.completionBlockOfTryToConnect = nil; //Not necessary. Also, if user close connection connection manually on success of try to estalish connection, this will be execute during the block is executing. I'm not sure what will happen, so don't put this line.
}

//Can set to nil (only can be set when is connected and will be set to nil when disconnected for any reason)
-(BOOL)setWhatToDoWhenHasSpaceToSendWithBlock:(void (^)())block{
    if(self.isConnected){
        self.hasSpaceToSendBlock = block;
        return YES;
    }else{
        return NO;
    }
}
-(BOOL)setWhatToDoWhenHasBytesAvailableWithBlock:(void (^)(NSData *))block{
    if(self.isConnected){
        self.hasBytesAvailableBlock = block;
        return YES;
    }else{
        return NO;
    }
}
-(BOOL)setWhatToDoWhenHasErrorOccurredWithBlock:(void (^)())block{
    if(self.isConnected){
        self.hasErrorOccurredBlock = block;
        return YES;
    }else{
        return NO;
    }
}
-(BOOL)setWhatToDoWhenHasEndEncounteredWithBlock:(void (^)())block{
    if(self.isConnected){
        self.hasEndEncounteredBlock = block;
        return YES;
    }else{
        return NO;
    }
}

//Shared dispatch queue.
//Therefore most socket network tasks are running in the same thread.
//
//Reference: http://stackoverflow.com/questions/19421283/do-2-objects-creating-serial-queues-with-the-same-name-share-the-same-queue
+(dispatch_queue_t)sharedNetworkQueue
{
    static dispatch_queue_t sharedNetworkQueue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedNetworkQueue = dispatch_queue_create("edu.columbia.sharedNetworkQueue", NULL);
    });
    
    return sharedNetworkQueue;
}


/*
 * The only valid init function.
 * If argument is invalid, will return nil.
 * Note: once inited, the url and port cannot change
 * anymore. If want to change, need to create
 * a new one.
 */
-(instancetype)initWithURL:(NSURL *)url andPort:(NSInteger)port{

    self = [super init];
    
    if(self){
        
        if(!url){
            NSLog(@"Invalid URL");
            return nil;
        }else{
            if(![url host]){ //the case without e.g. "http://"
                self.urlString = [url absoluteString];
            }else{ //the case with e.g. "http://"
                self.urlString = [url host];
            }
        }
        
        if (port < 0 || port > MAX_PORT_NUM) {
            NSLog(@"Invalid port number");
            return nil;
        }else{
            self.port = port;
        }
        
        self.isConnected = NO;
        self.isTryingToConnect = NO;
        self.hasTriedToConnect = NO;
        self.hasSuccessfullyConnected = NO;
        self.hasSpaceToSend = NO;
        
        [self releaseBlocks];
    
    }
    
    return self;
}

-(instancetype)init{
    [NSException raise:NSInternalInconsistencyException
                format:@"Need to use initWithURL:..."];
    
    return nil;
}

@end

