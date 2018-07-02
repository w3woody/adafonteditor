//
//  AXCharacter.h
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AXGlyphAttributes;

@interface AXCharacter : NSObject <NSCopying>

- (instancetype)init;
- (instancetype)initWithCharacter:(AXCharacter *)ch;
- (instancetype)initWithWidth:(uint8_t)width height:(uint8_t)height;

- (instancetype)initWithJson:(NSDictionary *)json;
- (NSDictionary *)json;

/*
 *	Trim support
 */

- (AXCharacter *)trim;

/*
 *	Character attributes. These must be changed through the document if we
 *	want undo to work.
 */

- (uint8_t)width;
- (uint8_t)height;
- (uint8_t)xAdvance;
- (int8_t)xOffset;
- (int8_t)yOffset;

- (void)setWidth:(uint8_t)width height:(uint8_t)height;
- (void)setXAdvance:(uint8_t)xAdv xOffset:(int8_t)xoff yOffset:(int8_t)yoff;

- (BOOL)getBitAtX:(uint8_t)x y:(uint8_t)y;
- (void)setBit:(BOOL)bit atX:(uint8_t)x y:(uint8_t)y;
- (void)clearBits;

- (NSImage *)bitmapImage;

/*
 *	Character manipulation
 */

- (AXCharacter *)flipHorizontally;
- (AXCharacter *)flipVertically;

/*
 *	For export. Note our raw data is encoded with bits, LSB leftmost. This
 *	means for Adafruit GFX we need to flip the bits in the byte
 */

- (uint16_t)rawBitmapSize;
- (const uint8_t *)rawBitmap;

@end

