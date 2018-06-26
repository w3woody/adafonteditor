//
//  AXCharacter.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXCharacter.h"

@interface AXCharacter ()
{
	uint8_t *bitmap;
}

@property (assign) uint8_t width;
@property (assign) uint8_t height;
@property (assign) uint8_t xAdvance;
@property (assign) uint8_t xOffset;
@property (assign) uint8_t yOffset;
@end

/*	SizeOfBitmap
 *
 *		Find the size of this bitmap, aligned to a 32-byte boundary
 */

static uint32_t SizeOfBitmap(uint8_t width, uint8_t height)
{
	uint32_t size = width * height;
	if (size == 0) size = 1;
	if (size % 256) size += 256 - size % 256;
	return size/8;
}

@implementation AXCharacter

- (instancetype)init
{
	if (nil != (self = [super init])) {
		self.width = 6;
		self.height = 8;
		self.xAdvance = 6;
		self.xOffset = 0;
		self.yOffset = 7;

		uint32_t size = SizeOfBitmap(self.width, self.height);
		bitmap = (uint8_t *)malloc(size);
		memset(bitmap,0,size);

		/*
		 *	Now draw a box from the upper left corner to the lower right
		 */

		for (int i = 1; i < self.width-1; ++i) {
			[self setBit:YES atX:i y:1];
			[self setBit:YES atX:i y:self.height-2];
		}
		for (int i = 1; i < self.height-1; ++i) {
			[self setBit:YES atX:1 y:i];
			[self setBit:YES atX:self.width-2 y:i];
		}
	}

	return self;
}

- (instancetype)initWithCharacter:(AXCharacter *)ch
{
	if (nil != (self = [super init])) {
		self.width = ch.width;
		self.height = ch.height;
		self.xAdvance = ch.xAdvance;
		self.xOffset = ch.xOffset;
		self.yOffset = ch.yOffset;

		uint32_t size = SizeOfBitmap(self.width, self.height);
		bitmap = (uint8_t *)malloc(size);
		memmove(bitmap,ch->bitmap,size);
	}

	return self;
}

- (instancetype)initWithJson:(NSDictionary *)d
{
	if (nil != (self = [super init])) {
		self.width = [(NSNumber *)d[@"width"] integerValue];
		self.height = [(NSNumber *)d[@"height"] integerValue];
		self.xAdvance = [(NSNumber *)d[@"xAdvance"] integerValue];
		self.xOffset = [(NSNumber *)d[@"xOffset"] integerValue];
		self.yOffset = [(NSNumber *)d[@"yOffset"] integerValue];

		NSString *c = d[@"bitmap"];

		uint32_t size = SizeOfBitmap(self.width, self.height);
		bitmap = (uint8_t *)malloc(size);
		memset(bitmap,0,size);

		uint32_t nbits = self.width;
		nbits *= self.height;
		for (uint32_t i = 0; i < nbits; ++i) {
			uint32_t bit = i;
			uint32_t byte = bit >> 3;
			bit &= 0x07;
			bit = 1 << bit;

			unichar ch = [c characterAtIndex:i];
			if (ch != ' ') {
				bitmap[byte] |= bit;
			} else {
				bitmap[byte] &= ~bit;
			}
		}
	}
	return self;
}

- (NSDictionary *)json
{
	NSMutableString *str = [[NSMutableString alloc] init];
	uint32_t nbits = self.width;
	nbits *= self.height;
	for (uint32_t i = 0; i < nbits; ++i) {
		uint32_t bit = i;
		uint32_t byte = bit >> 3;
		bit &= 0x07;
		bit = 1 << bit;

		if (bitmap[byte] & bit) {
			[str appendString:@"1"];
		} else {
			[str appendString:@" "];
		}
	}

	return @{ @"bitmap": str,
			  @"width": @(self.width),
			  @"height": @(self.height),
			  @"xAdvance": @(self.xAdvance),
			  @"xOffset": @(self.xOffset),
			  @"yOffset": @(self.yOffset) };
}


- (void)dealloc
{
	if (bitmap) free(bitmap);
}

- (AXCharacter *)copyWithZone:(NSZone *)zone
{
	return [[AXCharacter allocWithZone:zone] initWithCharacter:self];
}


/*
 *	Attributes
 */

- (void)setXAdvance:(uint8_t)xAdv xOffset:(int8_t)xoff yOffset:(int8_t)yoff
{
	self.xAdvance = xAdv;
	self.xOffset = xoff;
	self.yOffset = yoff;
}

/*
 *	Bitmap manipulation
 */

- (BOOL)getBitAtX:(uint8_t)x y:(uint8_t)y
{
	if ((x >= self.width) || (y >= self.height)) return NO;

	uint32_t bit = x + y * self.width;
	uint32_t byte = bit >> 3;
	bit &= 0x07;
	bit = 1 << bit;

	return (bitmap[byte] & bit) ? YES : NO;
}

- (void)setBit:(BOOL)flag atX:(uint8_t)x y:(uint8_t)y
{
	if ((x >= self.width) || (y >= self.height)) return;

	uint32_t bit = x + y * self.width;
	uint32_t byte = bit >> 3;
	bit &= 0x07;
	bit = 1 << bit;

	if (flag) {
		bitmap[byte] |= bit;
	} else {
		bitmap[byte] &= ~bit;
	}
}

- (void)clearBits
{
	uint32_t size = SizeOfBitmap(self.width, self.height);
	memset(bitmap,0,size);
}

- (void)setWidth:(uint8_t)width height:(uint8_t)height
{
	if ((self.width == width) && (self.height == height)) return;

	/*
	 *	We need to create a new bitmap and copy the bits
	 */

	uint32_t size = SizeOfBitmap(width,height);
	uint8_t *newBitmap = (uint8_t *)malloc(size);
	if (newBitmap == NULL) return;
	memset(newBitmap,0,size);

	uint8_t maxWidth = (width > self.width) ? self.width : width;
	uint8_t maxHeight = (height > self.height) ? self.height : height;

	for (uint8_t x = 0; x < maxWidth; ++x) {
		for (uint8_t y = 0; y < maxHeight; ++y) {
			/*
			 *	Get from old bit
			 */

			BOOL flag = [self getBitAtX:x y:y];

			/*
			 *	Set at new bit. Do calcs ourselves
			 */

			uint32_t bit = x + y * width;
			uint32_t byte = bit >> 3;
			bit &= 0x07;
			bit = 1 << bit;

			if (flag) {
				newBitmap[byte] |= bit;
			} else {
				newBitmap[byte] &= ~bit;
			}
		}
	}

	/*
	 *	Now replace
	 */

	uint8_t *tmp = bitmap;
	bitmap = newBitmap;
	self.width = width;
	self.height = height;

	free(tmp);
}

/*
 *	Convert bitmap to image for display
 */

- (NSImage *)bitmapImage
{
	/*
	 *	Create a temporary array of bits which we populate.
	 */

	uint32_t byteLen = self.width * self.height * sizeof(uint32_t);
	uint32_t *array = (uint32_t *)malloc(byteLen);

	for (uint8_t x = 0; x < self.width; ++x) {
		for (uint8_t y = 0; y < self.height; ++y) {
			BOOL val = [self getBitAtX:x y:y];
			array[x + y * self.width] = val ? 0xFF000000 : 0xFFFFFFFF;
		}
	}

	/*
	 *	Now convert to CGImage
	 */

    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, array, byteLen, NULL);

	CGImageRef image = CGImageCreate(self.width, self.height, 8, 32, self.width * 4, cspace, kCGBitmapByteOrder32Host * kCGImageAlphaFirst, provider, nil, NO, kCGRenderingIntentDefault);

	CGColorSpaceRelease(cspace);
	CGDataProviderRelease(provider);

	/*
	 *	Convert image ref to image
	 */

	NSImage *ret = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
	CGImageRelease(image);
	return ret;
}

@end
