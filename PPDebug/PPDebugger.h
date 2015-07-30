//
//  TCPClient.h
//  MCU Gateway
//
//  Created by Abel Duarte on 6/4/14.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RemoteLogger.h"

@interface PPDebugger : NSObject
{
}

+ (PPDebugger *)sharedDebugger;

- (void)install;

@end