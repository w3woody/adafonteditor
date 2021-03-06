//
//  AXFontBitmapBuilder.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontBitmapBuilder.h"
#import "AXLayoutManager.h"
#import "AXExtendedASCII.h"

@interface AXFontBitmapBuilder ()
@property (assign) uint8_t yHeight;
@property (assign) uint8_t first;
@property (assign) uint8_t last;

@property (assign) uint8_t ascender;
@property (assign) uint8_t capHeight;
@property (assign) uint8_t xHeight;
@property (assign) uint8_t descHeight;

@property (strong) NSMutableArray<AXCharacter *> *characters;
@end

@implementation AXFontBitmapBuilder

- (instancetype)initWithFont:(NSFont *)font start:(uint8_t)start end:(uint8_t)end
{
	if (nil != (self = [super init])) {
		/*
		 *	Make sure the parameters make sense
		 */

		if (start < 32) start = 32;		// Stuff below 32 doesn't render.
		if (end < start) end = start;
		self.first = start;
		self.last = end;

		self.characters = [[NSMutableArray alloc] init];

		/*
		 *	Get the descent of our font. This is the amount we advance
		 *	the pen as we move to the next line and is taken directly
		 *	from our ascender/descender.
		 */

		self.ascender = ceil(font.ascender);
		self.capHeight = ceil(font.capHeight);
		self.descHeight = ceil(-font.descender);
		self.xHeight = ceil(font.xHeight);

		self.yHeight = self.ascender + self.descHeight + ceil(font.leading);

		/*
		 *	Now build our array of glyphs for all the characters in our font.
		 *	Note we render the glyphs individually. We assume a string with
		 *	one character renders as one glyph.
		 */

		NSImage *tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
		[tmpImage lockFocus];

		NSMutableArray<AXGlyphAttributes *> *glyphs = [[NSMutableArray alloc] init];
		for (uint16_t ix = start; ix <= end; ++ix) {
			@autoreleasepool {
				/*
				 *	Yes, this is a lot of machinery just to render a glyph.
				 *	And I assume a lot of crap gets created in the process.
				 */

				NSString *str = [NSString stringWithFormat:@"%C",AXExtendedASCIIToUnicode(ix)];
				NSTextStorage *textStore = [[NSTextStorage alloc] initWithString:str];
				NSTextContainer *textContainer = [[NSTextContainer alloc] init];
				AXLayoutManager *myLayout = [[AXLayoutManager alloc] init];
				[myLayout addTextContainer:textContainer];
				[textStore addLayoutManager:myLayout];
				[textStore setFont: font];

				NSRange range = [myLayout glyphRangeForTextContainer:textContainer];
				[myLayout drawGlyphsForGlyphRange:range atPoint:NSMakePoint(0, 0)];

				AXGlyphAttributes *g;
				if (myLayout.axGlyphs.count == 0) {
					g = [[AXGlyphAttributes alloc] init];
				} else {
					g = myLayout.axGlyphs[0];
				}

				[glyphs addObject:g];
			}
		}

		[tmpImage unlockFocus];

		/*
		 *	We now have an array of beziers. Turn them into black & white
		 *	bitmaps. The whole point of having an editor is to allow the user
		 *	to subsequently clean up the font before saving
		 *
		 *	This can be a little brute forcey...
		 */

		for (uint16_t ix = start; ix <= end; ++ix) {
			uint8_t width;
			uint8_t height;

			AXGlyphAttributes *g = glyphs[ix-start];
			if (g.path == nil) {
				// We never got a path, so we assume the glyph doesn't exist.
				// Create an empty object based on the font parameters
				width = ceil(font.maximumAdvancement.width);
				height = ceil(font.ascender - font.descender);	// ### TEST

				AXCharacter *empty = [[AXCharacter alloc] initWithWidth:width height:height];
				[empty setXAdvance:width xOffset:0 yOffset:ceil(font.ascender)];

				[self.characters addObject:empty];
			} else {
				@autoreleasepool {
					/*
					 *	We have a path. This determines the bounding box of the
					 *	glyph and renders a bitmap the appropriate size.
					 */

					CGRect r = g.path.controlPointBounds;

					/*
					 *	The origin of our rendering is the origin for our
					 *	bitmap. We build a bitmap that is aligned around
					 *	that origin. So create our boundaries in integer values
					 */

					int16_t left = floor(r.origin.x);
					int16_t bottom = floor(r.origin.y);
					int16_t width = ceil(r.origin.x + r.size.width) - left;
					int16_t height = ceil(r.origin.y + r.size.height) - bottom;

					/*
					 *	Now generate the bitmap
					 */

					AXCharacter *ch = [[AXCharacter alloc] initWithWidth:width height:height];

					/*
					 *	Determine the various offsets. ### TEST
					 */

					uint8_t advance = ceil(g.advance);
					int8_t yOffset = height + bottom;
					int8_t xOffset = left;
					[ch setXAdvance:advance xOffset:xOffset yOffset:yOffset];

					/*
					 *	If we have no bits, skip the rest of this
					 */

					if ((width > 0) && (height > 0)) {

						/*
						 *	Now render into an offscreen bitmap. Note we need to
						 *	offset our rendering so that the origins overlap.
						 */

						CGColorSpaceRef bgColorRef = CGColorSpaceCreateDeviceGray();
						CGContextRef drawContext = CGBitmapContextCreate(nil, width, height, 8, width, bgColorRef, 0);

						NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
						NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithCGContext:drawContext flipped:NO];
						[NSGraphicsContext setCurrentContext:ctx];

						/* Render our bezier */
						[[NSColor whiteColor] setFill];
						NSRectFill(CGRectMake(0, 0, width, height));
						[[NSColor blackColor] setFill];
						NSAffineTransform *transform = [[NSAffineTransform alloc] init];
						[transform translateXBy:-left yBy:-bottom];	// ### TODO
						[g.path transformUsingAffineTransform:transform];
						[g.path fill];
						[NSGraphicsContext setCurrentContext:savedContext];

						/*
						 *	Now grab our B&W data and convert to 1 bit per pixel
						 */

						uint8_t *data = CGBitmapContextGetData(drawContext);
						for (uint8_t x = 0; x < width; ++x) {
							for (uint8_t y = 0; y < height; ++y) {
								uint8_t b = data[x+y*width];
								BOOL flag = (b < 0xC0);
								[ch setBit:flag atX:x y:y];
							}
						}

						/*
						 *	Done; release
						 */

						CGColorSpaceRelease(bgColorRef);
						CGContextRelease(drawContext);
					}

					/*
					 *	Append to our list
					 */

					[self.characters addObject:ch];
				}
			}
		}
	}
	return self;
}

@end

