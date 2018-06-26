//
//  AXFontView.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontView.h"

@interface AXFontView ()
@property (strong) NSFont *curFont;
@end

@implementation AXFontView

- (BOOL)isFlipped
{
	return YES;
}

- (void)setFont:(NSFont *)font
{
	self.curFont = font;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] setFill];
	NSRectFill(self.bounds);

	[[NSColor blackColor] setFill];

	if (self.curFont == nil) return;

	NSString *str = @"ABCabcOo01ILl\nThe quick brown fox jumped over the lazy dog";

	NSDictionary *d = @{ NSFontAttributeName: self.curFont,
						 NSForegroundColorAttributeName: [NSColor blackColor] };

	CGFloat width = self.bounds.size.width - 40;
	CGRect size = [str boundingRectWithSize:CGSizeMake(width, 9999) options:NSStringDrawingUsesLineFragmentOrigin attributes:d];

	CGRect r = self.bounds;
	r.origin.x += floor((r.size.width - size.size.width)/2);
	r.origin.y += floor((r.size.height - size.size.height)/2);
	r.size.width = ceil(size.size.width);
	r.size.height = ceil(size.size.height);
	if (r.origin.y < 0) r.origin.y = 0;

	[str drawWithRect:r options:NSStringDrawingUsesLineFragmentOrigin attributes:d context:nil];
}

@end
