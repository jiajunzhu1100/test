//
//  NSString+Hex.h
//  PowaPOS SDK
//
//  Created by Abel Duarte on 3/19/14.
//  Copyright (c) 2014 Smart Business Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PPRDNStringHex)

- (NSData *)stringToHex:(NSString *)string;

- (UInt8)integerFromHexCharacter:(unichar)character;

@end
