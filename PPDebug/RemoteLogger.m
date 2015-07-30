//
//  NetLogger.m
//  Debug Server
//
//  Created by Abel Duarte on 6/10/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import "RemoteLogger.h"
#import "PPRDTCPClient.h"
#import "PPRDNSData+Hex.h"

void NLog(NSString *format, ...)
{
    va_list vl;
    va_start(vl, format);

    NSDate *myDate = [[NSDate alloc] init];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"cccc, MMMM dd, YYYY, hh:mm aa"];
    NSString *timeFormat = [dateFormat stringFromDate:myDate];

    NSString *string = [NSString stringWithFormat:@"%@", format];
    [[RemoteLogger sharedLogger] logString:string arguments:vl];

    va_end(vl);
}

void NLogData(NSString *message, NSData *data)
{
    NSDate *myDate = [[NSDate alloc] init];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"cccc, MMMM dd, YYYY, hh:mm aa"];
    NSString *timeFormat = [dateFormat stringFromDate:myDate];



    NSMutableString *dataString = [NSMutableString stringWithFormat:@"\033[1m[%@] [HEX/DATA] %@\033[0m\n", timeFormat, message];

    for(NSUInteger i = 0; i < data.length; i += 16)
    {
        NSUInteger bytesToRead = data.length - i;

        if(bytesToRead >= 16)
            bytesToRead = 16;

        NSData *subdata = [data subdataWithRange:NSMakeRange(i, bytesToRead)];
        [dataString appendFormat:@"%@\n", [subdata dataToHex:subdata]];
    }
    
    NLog(@"%@", [data dataToHex:data]);
}

@interface RemoteLogger()
@property (nonatomic, retain) NSMutableString *log;
@property (nonatomic, retain) PPRDTCPServer *server;
@end

@implementation RemoteLogger

static id sharedLogger = nil;

#pragma mark - Singleton

+ (RemoteLogger *)sharedLogger
{
    if(!sharedLogger)
        sharedLogger = [[RemoteLogger alloc] init];

    return sharedLogger;
}

#pragma mark - Init and Dealloc

- (id)init
{
    self = [super init];
    if(self)
    {
        self.log = [NSMutableString string];
        self.server = [[[PPRDTCPServer alloc] initWithPortNumber:1234] autorelease];
        self.server.delegate = self;
        [self.server startServer];
    }
    return self;
}

- (void)dealloc
{
    [self.server stopServer];
    self.server = nil;
    [super dealloc];
}

#pragma mark - Logging

- (void)logString:(NSString *)format
{
    for(PPRDTCPClient *client in self.server.connectedClients)
    {
        [client writeData:[format dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)logString:(NSString *)format arguments:(va_list)arglist
{
    NSString *formattedString = [[[NSString alloc] initWithFormat:format arguments:arglist] autorelease];
    NSString *string = [NSString stringWithFormat:@"%@\n", formattedString];

    [self.log appendString:string];

    for(PPRDTCPClient *client in self.server.connectedClients)
    {
        [client writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)logStringArray:(NSArray *)stringArray
{
    for(NSString *string in stringArray)
    {
        [self.log appendString:string];
        [self logString:string];
    }
}

#pragma mark - TCPServer

- (void)server:(PPRDTCPServer *)server acceptedClient:(PPRDTCPClient *)client
{
    [client writeData:[self.log dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - TCPClientDelegate

- (void)client:(PPRDTCPClient *)client receivedData:(NSData *)data
{
}

- (void)client:(PPRDTCPClient *)client wroteBytes:(NSUInteger)bytes
{
}

@end
