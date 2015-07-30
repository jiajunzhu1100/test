//
//  TCPServer.h
//  MCU Gateway
//
//  Created by Abel Duarte on 6/5/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import "PPRDTCPClient.h"

@protocol PPRDTCPServerDelegate;

@interface PPRDTCPServer : NSObject
{
}

@property (nonatomic, assign) id <PPRDTCPServerDelegate> delegate;
@property (nonatomic, readonly) NSArray *connectedClients;

- (id)initWithPortNumber:(NSUInteger)portNumber;

- (void)startServer;
- (void)stopServer;

@end

@protocol PPRDTCPServerDelegate <NSObject>
- (void)server:(PPRDTCPServer *)server acceptedClient:(PPRDTCPClient *)client;
@end
