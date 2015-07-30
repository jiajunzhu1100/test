//
//  TCPClient.h
//  MCU Gateway
//
//  Created by Abel Duarte on 6/4/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PPRDTCPClientDelegate;

@interface PPRDTCPClient : NSObject <NSStreamDelegate>
{
}

@property (nonatomic, assign) id <PPRDTCPClientDelegate> delegate;
@property (nonatomic, readonly) NSInputStream *inputStream;
@property (nonatomic, readonly) NSOutputStream *outputStream;

- (id)initWithHost:(NSString *)host port:(NSUInteger)port;
- (id)initWithInputStream:(NSInputStream *)inputStream
             outputStream:(NSOutputStream *)outputStream;

#pragma mark - Open / Close

- (void)open;
- (void)close;
- (BOOL)isClosed;

- (void)writeData:(NSData *)data;

@end

@protocol PPRDTCPClientDelegate <NSObject>
- (void)client:(PPRDTCPClient *)client receivedData:(NSData *)data;
- (void)client:(PPRDTCPClient *)client wroteBytes:(NSUInteger)bytes;
@end
