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
@property (assign) int8_t xOffset;
@property (assign) int8_t yOffset;
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

- (instancetype)initWithWidth:(uint8_t)width height:(uint8_t)height;
{
	if (nil != (self = [super init])) {
		self.width = width;
		self.height = height;
		self.xAdvance = width;
		self.xOffset = 0;
		self.yOffset = height;

		uint32_t size = SizeOfBitmap(self.width, self.height);
		bitmap = (uint8_t *)malloc(size);
		memset(bitmap,0,size);
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

	uint8_t width = self.width;
	uint8_t height = self.height;
	if (width < 1) width = 1;
	if (height < 1) height = 1;

	uint32_t byteLen = width * height * sizeof(uint32_t);
	uint32_t *array = (uint32_t *)malloc(byteLen);
	memset(array,0xFF,byteLen);

	for (uint8_t x = 0; x < self.width; ++x) {
		for (uint8_t y = 0; y < self.height; ++y) {
			BOOL val = [self getBitAtX:x y:y];
			array[x + y * width] = val ? 0xFF000000 : 0xFFFFFFFF;
		}
	}

	/*
	 *	Now convert to CGImage
	 */

    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, array, byteLen, NULL);

	CGImageRef image = CGImageCreate(width, height, 8, 32, width * 4, cspace, kCGBitmapByteOrder32Host * kCGImageAlphaFirst, provider, nil, NO, kCGRenderingIntentDefault);

	CGColorSpaceRelease(cspace);
	CGDataProviderRelease(provider);

	/*
	 *	Convert image ref to image
	 */

	NSImage *ret = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
	CGImageRelease(image);
	return ret;
}

/*
 *	Trim; this does all the work to trim a bitmap to its smallest size by
 *	deleting blank rows.
 */

- (AXCharacter *)trim
{
	AXCharacter *modCh;

	/*
	 *	Step 1: Find the minimum and maximum set pixels for x and y.
	 */

	uint8_t minX = self.width;		// Start with backwards dimensions
	uint8_t maxX = 0;
	uint8_t minY = self.height;
	uint8_t maxY = 0;

	for (uint8_t x = 0; x < self.width; ++x) {
		for (uint8_t y = 0; y < self.height; ++y) {
			BOOL flag = [self getBitAtX:x y:y];

			if (flag) {
				// Bit is visible, so reset the bounding box
				if (minX > x) minX = x;
				if (maxX < x+1) maxX = x+1;
				if (minY > y) minY = y;
				if (maxY < y+1) maxY = y+1;
			}
		}
	}

	/*
	 *	Fast escape: If we didn't shrink, pass me back
	 */

	if ((minX == 0) && (maxX == self.width) && (minY == 0) && (maxY == self.height)) {
		return self;
	}

	/*
	 *	Fast escape: if empty, then return a 1 pixel blank
	 */

	if ((maxX == 0) || (maxY == 0)) {
		modCh = [[AXCharacter alloc] initWithWidth:0 height:0];
		[modCh setXAdvance:self.xAdvance xOffset:0 yOffset:0];
		return modCh;
	}

	/*
	 *	Step 2: construct a new character with the dimensions specified
	 */

	modCh = [[AXCharacter alloc] initWithWidth:maxX - minX height:maxY - minY];
	[modCh setXAdvance:self.xAdvance xOffset:self.xOffset - minX yOffset:self.yOffset - minY];

	/*
	 *	Step 3: copy the bits
	 */

	for (uint8_t x = minX; x < maxX; ++x) {
		for (uint8_t y = minY; y < maxY; ++y) {
			BOOL flag = [self getBitAtX:x y:y];
			if (flag) {
				[modCh setBit:YES atX:x - minX y:y - minY];
			}
		}
	}

	return modCh;
}


/*
 *	Raw data
 */

- (uint16_t)rawBitmapSize
{
	uint16_t numberBits = self.width * (uint16_t)self.height;
	return (numberBits + 7) >> 3;		// round to whole bytes
}

- (const uint8_t *)rawBitmap
{
	return bitmap;
}

@end
