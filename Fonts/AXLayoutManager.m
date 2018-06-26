//
//  AXLayoutManager.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXLayoutManager.h"

@implementation AXLayoutManager

- (void)showCGGlyphs:(const CGGlyph *)glyphs
           positions:(const NSPoint *)positions
               count:(NSUInteger)glyphCount
                font:(NSFont *)font
              matrix:(NSAffineTransform *)textMatrix
          attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
           inContext:(NSGraphicsContext *)graphicsContext
{
	/*
	 *	Make sure we have an array
	 */

	if (self.axGlyphs == nil) {
		self.axGlyphs = [[NSMutableArray alloc] init];
	}

	/*
	 *	For each glyph we grab a few bits of information:
	 *
	 *		The path
	 *		The width of the glyph (the advance from the origin to adjacent
	 *	origin)
     *
     *	Note the path is not advanced; we're interested in the glyph shape
     *	not the position.
	 */

	NSUInteger ix;
	for (ix = 0; ix < glyphCount; ++ix) {
		AXGlyphAttributes *glyph = [[AXGlyphAttributes alloc] init];

		NSBezierPath *path = [[NSBezierPath alloc] init];
		[path moveToPoint:NSMakePoint(0, 0)];
		[path appendBezierPathWithGlyph:glyphs[ix] inFont:font];

		NSSize size = [font advancementForGlyph:glyphs[ix]];

		glyph.offset = positions[ix];
		glyph.advance = size.width;
		glyph.bounds = [font boundingRectForGlyph:glyphs[ix]];
		glyph.path = path;

		[self.axGlyphs addObject:glyph];
	}
}

@end
