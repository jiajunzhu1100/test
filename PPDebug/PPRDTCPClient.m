//
//  TCPClient.m
//  MCU Gateway
//
//  Created by Abel Duarte on 6/4/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import "PPRDTCPClient.h"

@interface PPRDTCPClient()
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, retain) NSMutableData *writeBuffer;
@property (nonatomic, retain) NSMutableData *readBuffer;
@end

@implementation PPRDTCPClient

#pragma mark - Init

- (id)initWithHost:(NSString *)host port:(NSUInteger)port
{
    CFWriteStreamRef writeStream = NULL;
    CFReadStreamRef readStream = NULL;

    CFStreamCreatePairWithSocketToHost(CFAllocatorGetDefault(),
                                       (CFStringRef)host,
                                       (UInt32)port,
                                       &readStream,
                                       &writeStream);

    NSInputStream *inputStream = (__bridge NSInputStream *)readStream;
    NSOutputStream *outputStream = (__bridge NSOutputStream *)writeStream;

    return [self initWithInputStream:inputStream outputStream:outputStream];
}

- (id)initWithInputStream:(NSInputStream *)inputStream
             outputStream:(NSOutputStream *)outputStream
{
    self = [super init];
    if(self)
    {
        self.writeBuffer = [NSMutableData data];
        self.readBuffer = [NSMutableData data];

        self.inputStream = inputStream;
        self.inputStream.delegate = self;

        self.outputStream = outputStream;
        self.outputStream.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [self close];
    self.inputStream = nil;
    self.outputStream = nil;
    [super dealloc];
}

#pragma mark - Open / Close

- (void)open
{
    [self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
}

- (void)close
{
    [self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
                                 forMode:NSDefaultRunLoopMode];

    [self.inputStream close];
    [self.outputStream close];
}

- (BOOL)isClosed
{
    if(!self.inputStream && !self.outputStream)
        return YES;

    return NO;
}

#pragma mark - Read / Write

- (void)writeData:(NSData *)data
{
    [self.writeBuffer appendBytes:data.bytes length:data.length];
    [self writeData];
}

- (void)writeData
{
    while(self.outputStream.hasSpaceAvailable && self.writeBuffer.length > 0)
    {
        NSInteger bytesWritten = [self.outputStream write:self.writeBuffer.bytes
                                                maxLength:self.writeBuffer.length];

        // Writing error
        if(bytesWritten == -1)
        {
            return;
            break;
        }
        else if(bytesWritten > 0)
        {
            // Remove written data from write buffer
            [self.writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        }
    }
}

- (void)readData
{
    while(self.inputStream.hasBytesAvailable)
    {
        UInt8 buffer[1024];
        NSUInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
        [self.readBuffer appendBytes:buffer length:bytesRead];

        if([self.delegate respondsToSelector:@selector(client:receivedData:)])
        {
            [self.delegate client:self
                     receivedData:[NSData dataWithBytes:buffer length:bytesRead]];
        }
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventHasSpaceAvailable:
        {
            [self writeData];
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            [self readData];
            break;
        }
        case NSStreamEventOpenCompleted:
        {
            break;
        }
        default:
            break;
    }
}

@end
