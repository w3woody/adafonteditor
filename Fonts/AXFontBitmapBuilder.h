//
//  AXFontBitmapBuilder.h
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AXCharacter.h"

/*
 *	This utility class helps us construct a 1-bit bitmap for the specified
 *	font, along with the proper offsets and the like. This will only render
 *	the characters from 32 to 255, using Windows 1252 mapping.
 *
 *	This is used by our document object to build a font based on the
 *	font parameters provided
 */


@interface AXFontBitmapBuilder : NSObject

- (instancetype)initWithFont:(NSFont *)font start:(uint8_t)start end:(uint8_t)end;

- (uint8_t)yHeight;			// Y height of entire font.
- (uint8_t)first;
- (uint8_t)last;
- (NSMutableArray<AXCharacter *> *)characters;

@end
