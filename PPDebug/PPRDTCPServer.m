//
//  TCPServer.m
//  MCU Gateway
//
//  Created by Abel Duarte on 6/5/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import "PPRDTCPServer.h"

@interface PPRDTCPServer()
@property (nonatomic, assign) CFSocketRef serverSocket;
@property (nonatomic, assign) CFRunLoopSourceRef socketSource;
@property (nonatomic, assign) NSUInteger portNumber;
@property (nonatomic, retain) NSMutableArray *clients;
@end

@implementation PPRDTCPServer

#pragma mark - Init and Dealloc

- (id)initWithPortNumber:(NSUInteger)portNumber
{
    self = [super init];
    if(self)
    {
        self.clients = [NSMutableArray array];
        self.portNumber = portNumber;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [self stopServer];
    self.clients = nil;
    self.portNumber = 0;
}

#pragma mark - Start and Stop server

- (void)startServer
{
    CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    self.serverSocket = CFSocketCreate(kCFAllocatorDefault,
                                       PF_INET,
                                       SOCK_STREAM,
                                       IPPROTO_TCP,
                                       kCFSocketAcceptCallBack,
                                       handleConnect,
                                       &socketContext);

    // Make sure that same listening socket address gets reused after every connection
    int option = 1;
    CFSocketNativeHandle sockfd = CFSocketGetNative(self.serverSocket);
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (void *)&option, sizeof(option));

    struct sockaddr_in sin;

    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; /* Address family */
    sin.sin_port = htons(self.portNumber); /* Or a specific port */
    sin.sin_addr.s_addr= INADDR_ANY;

    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));

    CFSocketSetAddress(self.serverSocket, sincfd);
    CFRelease(sincfd);

    self.socketSource = CFSocketCreateRunLoopSource(
                                                    kCFAllocatorDefault,
                                                    self.serverSocket,
                                                    0);

    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       self.socketSource,
                       kCFRunLoopDefaultMode);
}

- (void)stopServer
{
    if(self.socketSource)
    {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                              self.socketSource,
                              kCFRunLoopDefaultMode);

        CFRelease(self.socketSource);
    }

    if(self.serverSocket)
    {
        CFSocketInvalidate(self.serverSocket);
        CFRelease(self.serverSocket);
    }

    for(PPRDTCPClient *client in self.clients)
    {
        [client close];
    }
}

#pragma mark - Accept connection

void handleConnect(CFSocketRef s,
                   CFSocketCallBackType callbackType,
                   CFDataRef address,
                   const void *data,
                   void *info)
{
    PPRDTCPServer *server = (__bridge PPRDTCPServer *)info;
    int sockfd = *(CFSocketNativeHandle *)data;
    [server acceptedConnectionWithNativeSocketHandle:sockfd];
}

- (void)acceptedConnectionWithNativeSocketHandle:(CFSocketNativeHandle)handle
{
    CFWriteStreamRef writeStream = NULL;
    CFReadStreamRef readStream = NULL;

    CFStreamCreatePairWithSocket(kCFAllocatorDefault,
                                 handle,
                                 &readStream,
                                 &writeStream);

    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

    NSInputStream *inputStream = (__bridge NSInputStream *)readStream;
    NSOutputStream *outputStream = (__bridge NSOutputStream *)writeStream;

    PPRDTCPClient *client = [[[PPRDTCPClient alloc] initWithInputStream:inputStream
                                                   outputStream:outputStream] autorelease];
    [self.clients addObject:client];
    [client open];

    if([self.delegate respondsToSelector:@selector(server:acceptedClient:)])
    {
        [self.delegate server:self acceptedClient:client];
    }

    CFRelease(readStream);
    CFRelease(writeStream);
}

#pragma mark - Connected clients

- (NSArray *)connectedClients
{
    return [NSArray arrayWithArray:self.clients];
}

@end
