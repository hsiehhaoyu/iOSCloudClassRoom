//
//  CCCommunicationHandler.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/9.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//
/*
 
 */

#import "CCCommunicationHandler.h"
#import "CCMessageQueue.h"
#import "CCConfiguration.h"
#import "CCAppDelegate.h"
#import "CCMiscHelper.h"

@interface CCCommunicationHandler ()

@property (strong,atomic) CCTCPConnection *serverConnection;

@property (strong,atomic) NSMutableArray *unfinishedMessage;

//Message queue
@property (strong,atomic) CCMessageQueue *queue;

@property (atomic) BOOL receivedLastArgumentCompleted;

@end

@implementation CCCommunicationHandler

//-(void)testFunction{
//    if([self isConnectedToServer]){
//        [self.serverConnection sendString:@"Test message"];
//    }else{
//        [self.serverConnection tryToEstablishConnectionAndOnCompletion:^(TryToConnectResult result) {
//            [self.serverConnection sendString:@"Test2 message"];
//        }];
//    }
//}


/* 
 * Send request/response to server.
 * Note that all arguments should be
 * NSString, or Action will be abort.
 * Note that even sent successfully 
 * does NOT gurantee server will receive it.
 */
//completion block can be nil, but not suggested
-(void)sendToServerWithMessage:(CCMessage *)message{
    
    if(!message){
        [NSException raise:NSInternalInconsistencyException
                format:@"Receive a nil message in sentToServerWithMessage:"];
    
        return;
    }

    NSString *command = message.command;
    NSArray *arguments = message.arguments;
    void (^completion)(SendMessageResult) = message.sendCompletionBlock;
    
    
    if(!self.isServerInfoSet){
        
        if(completion)
            completion(SendMessageResultServerInfoNotSet);
    
    }else if(!self.isConnectedToServer){
        [self tryToConnectServerAndOnCompletion:^(TryToConnectResult result) {
            //AlreadyConnected could happen, since someone might be trying when we exam self.isConnectedToServer
            if(result == TryToConnectResultSucceeded ||
               result == TryToConnectResultAlreadyConnected){
                //send again
                [self sendToServerWithMessage:message];
                
            }else if(result == TryToConnectResultAlreadyTrying){
                
                [self.queue pushMessage:message];
                [self removeMessage:message fromQueueAfter:DEFAULT_MESSAGE_QUEUE_TIMEOUT];
                
                NSLog(@"Is already trying to connect when sending message, put it into queue");
//                if(completion)
//                    completion(SendMessageResultIsAlreadyTryingToConnect);
            }else{ //failed
                if (completion)
                    completion(SendMessageResultCanNotConnect);
            }
        }];
    }else{
        
        //start to combind all stuffs into one string
        NSString *messageString;
        if (command) { // is not nil
            messageString = [NSString stringWithFormat:@"%@\n",command];
        }else{
            
            NSLog(@"Need a command!");
            
            if(completion)
                completion(SendMessageResultNoCommand);
            
            return;
        }
        
        if(arguments){ //something in the argument array(Note: it's allowed to be nil)
            for(id arg in arguments){
                if([arg isKindOfClass:[NSString class]]){ //don't know why but isMemberOfClass doesn't work
                    messageString = [NSString stringWithFormat:@"%@:%@\n", messageString, (NSString *)arg];
                    //NSLog(@"Argument: %@", arg);
                }else{
                    NSLog(@"At least an argument is not NSString!");
                    if(completion)
                        completion(SendMessageResultInvalidArguments);
                    return;
                }
            }
        }
        
        messageString = [NSString stringWithFormat:@"%@END\n",messageString];
        
        NSLog(@"messageString: %@",messageString);
        
        //if other messages in queue are still waiting to be sent, put this in the queue
        //(This will generate a new problem, if some other message are already in queue and
        //is going to be send again, they will be put in queue again if still something in
        //the queue!)
        
        
            [self.serverConnection sendString:messageString onCompletion:^(SendDataResult result) {
                if (result == SendDataResultSucceeded) {
                    if(completion)
                        completion(SendMessageResultSucceeded);
                }else if(result == SendDataResultHasNoSpaceToSend){
                    [self.queue pushMessage:message];
                    [self removeMessage:message fromQueueAfter:DEFAULT_MESSAGE_QUEUE_TIMEOUT];
                    
                    NSLog(@"Has no space to send when sending message, put it into queue");
                    
    //                if(completion)
    //                    completion(SendMessageResultHasNoSpaceToSend);
                }else{ //all other cases treat as failed
                    if(completion)
                        completion(SendMessageResultFailed);
                }
            }];
        
    }
}

//remove message after certain time
//Reference: http://stackoverflow.com/questions/4139219/how-do-you-trigger-a-block-after-a-delay-like-performselectorwithobjectafter
-(void)removeMessage:(CCMessage *)message fromQueueAfter:(NSInteger)delaySeconds{
    
    __weak CCCommunicationHandler *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delaySeconds * NSEC_PER_SEC),dispatch_get_main_queue(), ^{
        if(weakSelf){
            if([weakSelf.queue isMessageInQueue:message]){
                [weakSelf removeMessageFromQueue:message];
                if(message.sendCompletionBlock)
                    message.sendCompletionBlock(SendMessageResultTimeOut);
                
                //may or may not in its queue
                if(weakSelf.serverMC)
                    [weakSelf.serverMC removeMessageFromSentMessages:message];
                
                NSLog(@"Message timeout, removed from Queue. Command: %@", message.command);
                
#ifdef USE_PUSH_NOTIFICATION
                if(weakSelf.queue.isEmpty && weakSelf.serverMC.isSentMessagesEmpty)
                    [weakSelf.serverMC closeServerConnection];
#endif
            }
        }
    });
}

//What to do when received data
//In our case, only string
-(void)receivedData:(NSData *)data{
    
    NSLog(@"receivedData Called.");
    
    NSString *receivedString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    [self decodeStringToMessageInArrayFormat:receivedString];
    
    while([self hasENDInUnfinishedMessage]){
        NSArray *messageInArray = [self processUnfinishedMessage];
        
        if(!messageInArray) //not a complete message
            return;
        
        NSLog(@"Received message:");
        for(NSString *line in messageInArray)
            NSLog(@"%@", line);
        
            
        if(self.receivedMessageBlock){
            self.receivedMessageBlock(messageInArray);
        }else{
            NSLog(@"Received message but no block can be called!");
        }
        
    }
}

-(BOOL)hasENDInUnfinishedMessage{

    for(NSString *line in self.unfinishedMessage){
        if([line isEqualToString:@"END"])
            return YES;
    }
    
    return NO;
}


//this function along with receivedData and decodeStringTo...
//may be optimized for efficiency in the future. (but now works well)
-(NSArray *)processUnfinishedMessage{
    
    NSMutableArray *arrayMessage = [[NSMutableArray alloc] init];
    
    NSInteger i = 0;
    BOOL hasEND = NO;
    
    for(NSString *line in self.unfinishedMessage){
        NSString *treatedLine;
        
        if([line rangeOfString:@":"].location == 0)
            treatedLine = [line substringFromIndex:1];
        else
            treatedLine = line;
        
        if([treatedLine isEqualToString:@"END"]){
            hasEND = YES;
            break;
        }else
            [arrayMessage addObject:treatedLine];
        
        i++;
    }
    
    if(hasEND){
        
        for(int j=0; j < i+1; j++)
            [self.unfinishedMessage removeObjectAtIndex:0];
        return [arrayMessage copy];
    }else{
        
        return nil;
    }


}

//Decode to command and arguments
-(void)decodeStringToMessageInArrayFormat:(NSString *)string{
    
    NSArray *originMsg = [string componentsSeparatedByString:@"\n"];
    NSMutableArray *treatedMsg = [originMsg mutableCopy];
    
    if(!self.receivedLastArgumentCompleted){
        if([[treatedMsg firstObject] isEqualToString:@""]){
            
            [treatedMsg removeObjectAtIndex:0];
        
        }else{
            treatedMsg[0] = [NSString stringWithFormat:@"%@%@",
                             [self.unfinishedMessage lastObject],treatedMsg[0]];
            [self.unfinishedMessage removeLastObject];
        }
    
    }
    
//    if([[treatedMsg firstObject] isEqualToString:@""]){
//        
//        if(!self.receivedLastArgumentCompleted){
//            treatedMsg[0] = [NSString stringWithFormat:@"%@%@",
//                             [self.unfinishedMessage lastObject],treatedMsg[0]];
//        }
//        
//        [treatedMsg removeObjectAtIndex:0];
//    }
    
    
    
    if([[string substringFromIndex:[string length]-1] isEqualToString:@"\n"]){ //complete
    
        [treatedMsg removeObjectAtIndex:[treatedMsg count]-1]; //remove @""
        
        self.receivedLastArgumentCompleted = YES;
    
    }else{
    
        NSLog(@"Imcomplete message received");
        self.receivedLastArgumentCompleted = NO;
    
    }
    
    
    
//    if([[treatedMsg lastObject] isEqualToString:@""]){
//        
//        self.receivedLastArgumentCompleted = YES;
//    }else{
//        self.receivedLastArgumentCompleted = NO;
//    }
    
    NSLog(@"Received raw message:");
    for(NSString *line in originMsg)
        NSLog(@"%@", line);
    
    NSLog(@"Received raw message2:");
    for(NSString *line in treatedMsg)
        NSLog(@"%@", line);
    
    //NSMutableArray *treatedMsg = [originMsg mutableCopy];
    
    [self.unfinishedMessage addObjectsFromArray:[treatedMsg copy]];
    
        //handle : before arguments
//    for (int i=1; i < treatedMsg.count - 1; i++) { //start from second object, ignore END
//        [treatedMsg setObject:[treatedMsg[i] substringFromIndex:1] atIndexedSubscript:i];
//    }
//    [treatedMsg removeObjectAtIndex:[treatedMsg count]-1]; //remove @""
//    [treatedMsg removeObjectAtIndex:[treatedMsg count]-1]; //remove @"END"
//    return [treatedMsg copy];
}

//if queue is not empty, try to start to send first one.
//this will trigger further actions of sending the
//rest messages. 
-(void)sendFirstMessageInQueue{
    
    //Don't use while, since the block will also call this again and might be conflict
    if(!self.queue.isEmpty){
        if(self.isConnectedToServer){
            
            if(self.serverConnection.hasSpaceToSend){
                CCMessage *message = [self.queue popMessage];
                
                if(message){
                    [self sendToServerWithMessage:message];
                }else{
                    NSLog(@"Weird, queue is not empty but couldn't pop a valid msg.");
                }
            }
        }else{
            [self tryToConnectServerAndOnCompletion:^(TryToConnectResult result) {
                //make all messages completed with failure of connection if cannot connect
                if(result == TryToConnectResultFailed)
                    [self makeAllMessagesInQueueCompletedWithResult:SendMessageResultCanNotConnect];
                //No need to do things in other cases, since it will automatically
                //trigger this function again.
            }];
        }
    }

}

-(void)makeAllMessagesInQueueCompletedWithResult:(SendMessageResult)result{
    while(!self.queue.isEmpty){
        CCMessage *message = [self.queue popMessage];
        if(message){
            if(message.sendCompletionBlock)
                message.sendCompletionBlock(result);
            
            if(self.serverMC)
                [self.serverMC removeMessageFromSentMessages:message];
        }
    }
}

-(void)makeMessage:(CCMessage *)message completedWithResult:(SendMessageResult)result{
    if(message){
        if([self.queue isMessageInQueue:message]){
            [self.queue removeMessage:message];
            if(message.sendCompletionBlock)
                message.sendCompletionBlock(result);
            
            if(self.serverMC)
               [self.serverMC removeMessageFromSentMessages:message];
        }
    }
}

-(void)removeMessageFromQueue:(CCMessage *)message{
    [self.queue removeMessage:message];
}

-(BOOL)isQueueEmpty{
    return self.queue.isEmpty;
}

-(void)tryToConnectServerAndOnCompletion:(void (^)(TryToConnectResult))completion{
    
    if(!completion){
        [NSException raise:NSInternalInconsistencyException
                    format:@"Completion block can't be nil."];
        return;
    }
    
    [self.serverConnection tryToEstablishConnectionAndOnCompletion:^(TryToConnectResult result) {
        if (result == TryToConnectResultSucceeded) {
            //Register call back blocks
            __weak CCCommunicationHandler *weakSelf = self;
            [self.serverConnection setWhatToDoWhenHasBytesAvailableWithBlock:^(NSData *readData) {
                [weakSelf receivedData:readData];
            }];
            
            [self.serverConnection setWhatToDoWhenHasSpaceToSendWithBlock:^{
                [weakSelf sendFirstMessageInQueue];
            }];
            
            [self.serverConnection setWhatToDoWhenHasErrorOccurredWithBlock:^{
                [weakSelf sendFirstMessageInQueue];
            }];
            
            [self.serverConnection setWhatToDoWhenHasEndEncounteredWithBlock:^{
                [weakSelf sendFirstMessageInQueue];
            }];
            
        }
        completion(result);
    }];

}

//check whether server url and port has been set
-(BOOL)isServerInfoSet{
    return (self.serverConnection) ? YES : NO;
}

//check whether is conncted to server
-(BOOL)isConnectedToServer{
    if(self.serverConnection){
        return self.serverConnection.isConnected;
    }else{
        return NO;
    }
}


-(void)closeServerConnection{
    
    [self makeAllMessagesInQueueCompletedWithResult:SendMessageResultConnectionClosed];
    [self.unfinishedMessage removeAllObjects];
    self.receivedLastArgumentCompleted = YES;

    if(self.serverConnection)
        [self.serverConnection endConnection];

}



//return YES if init (not connect) the serverConnection successfully
//will set to logout state, close existing connection, and init a new TCPConnection
-(BOOL)setServerURL:(NSURL *)url andPort:(NSInteger)port{
    
    [self closeServerConnection];
    
    self.serverConnection = [[CCTCPConnection alloc] initWithURL:url andPort:port];
    
    if (self.serverConnection) { //init successfully
        return YES;
    }else{
        NSLog(@"Cannot initial the server connection!");
        return NO;
    }
}

/* 
 * Won't return nil if cannot init (not connect) the serverConnection
 * with given arguments.
 */
-(instancetype)initWithServerURL:(NSURL *)url andPort:(NSInteger)port{
    
    self = [self init];
    
    if(self){
        [self setServerURL:url andPort:port];
    }
    
    return self;
}

-(instancetype)init{
    self = [super init];
    
    if (self) {
        self.queue = [[CCMessageQueue alloc] init];
        self.unfinishedMessage = [[NSMutableArray alloc] init];
        self.receivedLastArgumentCompleted = YES;
        
        //set what to do when receive push notification
        CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        __weak CCCommunicationHandler *weakSelf = self;
        appDelegate.receivedPushNotificationBlock = ^(NSDictionary *receivedMessage){
            
            if(weakSelf){
                if(receivedMessage){
                    receivedMessage = [receivedMessage objectForKey:@"aps"];
                    if(receivedMessage){
                        NSString *messageString = [receivedMessage objectForKey:@"alert"];
                        if(messageString){
                            if(![CCMiscHelper isStringEmpty:messageString]){
                                NSMutableArray *messageInArray = [[messageString componentsSeparatedByString:@"\n"] mutableCopy];
                                //remove "END"
                                [messageInArray removeLastObject];
                                //remove ":"
                                for(int i=1; i<messageInArray.count; i++){
                                    messageInArray[i] = [(NSString *)messageInArray[i] substringFromIndex:1];
                                }
                                
                                NSLog(@"Received message from APN:");
                                for(NSString *line in messageInArray)
                                    NSLog(@"%@", line);
                                
                                
                                if(weakSelf.receivedMessageBlock){
                                    weakSelf.receivedMessageBlock([messageInArray copy]);
                                }else{
                                    NSLog(@"Received message from APN but no block can be called!");
                                }
                            
                            }
                        }
                    }
                }
                
                //NSLog(@"Receieved Notification from APN but it's in wrong format");
            }
        };
    }
    
    return self;
}

-(void)dealloc{
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.receivedPushNotificationBlock = nil;
}

@end
