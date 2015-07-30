//
//  NSData+Hex.m
//  Gateway
//
//  Created by Deepak Shukla on 23/04/2014.
//  Copyright (c) 2014 Powa. All rights reserved.
//

#import "PPRDNSData+Hex.h"

@implementation NSData (PPRDNSDataHex)

- (NSString *)dataToHex:(NSData *)data;
{
    NSMutableString *string = [NSMutableString string];
    
    if(data == nil)
    {
        [string appendString:@""];
    }

    const char *bytes = [(NSData*)data bytes];
    
    
    for (int i = 0; i < [data length]; i++)
    {
        [string appendFormat:@"%02X", (UInt8)bytes[i]];
    }
    
    return  [[string copy] autorelease];
}

@end
