//
//  AXFontEditView.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontEditView.h"

@interface AXFontEditView ()
@property (strong) AXDocument *document;
@property (strong) AXCharacter *character;
@property (assign) uint8_t charIndex;
@end

@implementation AXFontEditView

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if (nil != (self = [super initWithCoder:decoder])) {
		[self internalInit];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	if (nil != (self = [super initWithFrame:frame])) {
		[self internalInit];
	}
	return self;
}

- (void)internalInit
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCharacter:) name:NOTIFY_CHARACTERCHANGED object:nil];
}

- (void)reloadCharacter:(NSNotification *)n
{
	NSNumber *num = n.userInfo[@"char"];

	if (num.integerValue == self.charIndex) {
		self.character = [self.document characterAtIndex:self.charIndex];
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[super resizeSubviewsWithOldSize:oldSize];
	[self setNeedsDisplay:YES];
}

- (NSInteger)pixelSize
{
	if (self.character == nil) return 32;

	CGSize size = self.bounds.size;

	NSInteger pixSize = size.width / self.character.width;
	NSInteger pixSizeY = size.height / self.character.height;
	if (pixSize > pixSizeY) pixSize = pixSizeY;

	if (pixSize > 32) pixSize = 32;
	if (pixSize < 2) pixSize = 2;

	return pixSize;
}

- (void)clearCharacter
{
	if (self.character == nil) return;

	[self.document clearCharacterAtIndex:self.charIndex];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

	[[NSColor whiteColor] setFill];
	NSRectFill(self.bounds);

    if (self.character == nil) return;

	/*
	 *	Pixels
	 */

    uint8_t width = self.character.width;
    uint8_t height = self.character.height;
	CGSize size = self.bounds.size;
	NSInteger pix = [self pixelSize];
	NSInteger left = (size.width - pix * width)/2;
	NSInteger top = (size.height - pix * height)/2;

	/*
	 *	Draw pixels
	 */

	[[NSColor blackColor] setFill];
    for (uint8_t x = 0; x < width; ++x) {
    	for (uint8_t y = 0; y < height; ++y) {
    		BOOL flag = [self.character getBitAtX:x y:y];
    		CGRect r = CGRectMake(x * pix + left, y * pix + top, pix, pix);
    		if (flag) {
    			NSRectFill(r);
			}
		}
	}

    /*
     *	Draw grid
     */

	NSBezierPath *path = [[NSBezierPath alloc] init];
	for (NSInteger i = 0; i <= width; ++i) {
		[path moveToPoint:NSMakePoint(left + i * pix + 0.5, top)];
		[path lineToPoint:NSMakePoint(left + i * pix + 0.5, top + height * pix)];
	}
	for (NSInteger i = 0; i <= height; ++i) {
		[path moveToPoint:NSMakePoint(left, top + i * pix + 0.5)];
		[path lineToPoint:NSMakePoint(left + width * pix, top + i * pix + 0.5)];
	}
	[[NSColor lightGrayColor] setStroke];
	[path stroke];

	/*
	 *	Draw xoffset/yoffset origin if visible
	 */

	int8_t xOff = self.character.xOffset;
	int8_t yOff = self.character.yOffset;
	if ((xOff >= 0) && (yOff >= 0)) {
		if ((xOff <= width) && (yOff <= height)) {
			/*
			 *	Origin is visible
			 */

			CGRect r = CGRectMake(left + pix * xOff - 4, top + pix * yOff - 4, 8, 8);
			[[NSColor blueColor] setFill];
			NSBezierPath *p = [[NSBezierPath alloc] init];
			[p appendBezierPathWithOvalInRect:r];

			[p fill];
		}
	}

	/*
	 *	Draw resize thumb
	 */

	CGRect th = CGRectMake(left + pix * width - 5, top + pix * height - 5, 10, 10);
	[[NSColor lightGrayColor] setFill];
	NSRectFill(th);
}

- (void)setCharacter:(AXCharacter *)ch atIndex:(uint8_t)ix
{
	self.character = ch;
	self.charIndex = ix;
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
}

- (void)mouseUp:(NSEvent *)event
{
	if (self.character == nil) return;

	CGPoint loc = [self convertPoint:event.locationInWindow fromView:nil];

    uint8_t width = self.character.width;
    uint8_t height = self.character.height;
	CGSize size = self.bounds.size;
	NSInteger pix = [self pixelSize];
	NSInteger left = (size.width - pix * width)/2;
	NSInteger top = (size.height - pix * height)/2;

    for (uint8_t x = 0; x < width; ++x) {
    	for (uint8_t y = 0; y < height; ++y) {
    		CGRect r = CGRectMake(x * pix + left, y * pix + top, pix, pix);
    		if (CGRectContainsPoint(r, loc)) {
    			/*
    			 *	Flip bit
    			 */

    			BOOL flag = [self.character getBitAtX:x y:y];
    			[self.document setBit:self.charIndex withValue:!flag atX:x y:y];
    			return;
			}
		}
	}
}

- (void)mouseDragged:(NSEvent *)event
{
}

@end
