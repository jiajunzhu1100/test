//
//  NetLogger.h
//  Debug Server
//
//  Created by Abel Duarte on 6/10/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PPRDTCPClient.h"
#import "PPRDTCPServer.h"

void NLog(NSString *format, ...);
void NLogData(NSString *message, NSData *data);

@interface RemoteLogger : NSObject <PPRDTCPClientDelegate, PPRDTCPServerDelegate>
{
}

+ (RemoteLogger *)sharedLogger;

- (void)logString:(NSString *)format;
- (void)logString:(NSString *)format arguments:(va_list)arglist;
- (void)logStringArray:(NSArray *)stringArray;

@end
