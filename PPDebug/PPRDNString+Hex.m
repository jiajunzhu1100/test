//
//  NSString+Hex.m
//  PowaPOS SDK
//
//  Created by Abel Duarte on 3/19/14.
//  Copyright (c) 2014 Smart Business Technology. All rights reserved.
//

#import "PPRDNString+Hex.h"

@implementation NSString (PPRDNStringHex)

- (NSData *)stringToHex:(NSString *)string
{
    NSMutableData *mutableData = [NSMutableData data];
    
    NSUInteger index = 0;
    
    for(index = 0; index < string.length; index += 2)
    {
        unichar byte1 = [string characterAtIndex:index];
        unichar byte2 = [string characterAtIndex:index + 1];
        
        UInt8 hex1 = [self integerFromHexCharacter:byte1];
        UInt8 hex2 = [self integerFromHexCharacter:byte2];
        UInt8 result = ((hex1 << 4) | hex2);
        
        [mutableData appendBytes:(const void *)&result length:1];
    }
    
    return  mutableData;
}

- (UInt8)integerFromHexCharacter:(unichar)character
{
    if(character == '0')
        return 0;
    if(character == '1')
        return 1;
    if(character == '2')
        return 2;
    if(character == '3')
        return 3;
    if(character == '4')
        return 4;
    if(character == '5')
        return 5;
    if(character == '6')
        return 6;
    if(character == '7')
        return 7;
    if(character == '8')
        return 8;
    if(character == '9')
        return 9;
    if(character == 'A' || character == 'a')
        return 10;
    if(character == 'B' || character == 'b')
        return 11;
    if(character == 'C' || character == 'c')
        return 12;
    if(character == 'D' || character == 'd')
        return 13;
    if(character == 'E' || character == 'e')
        return 14;
    if(character == 'F' || character == 'f')
        return 15;
    
    return 0;
}

@end
