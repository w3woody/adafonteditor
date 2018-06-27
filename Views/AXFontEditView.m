//
//  AXFontEditView.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontEditView.h"

/*
 *	Internal structures
 */

typedef struct AXDisplayBoundary
{
	// Total area to draw
	int16_t left;
	int16_t top;
	int16_t right;
	int16_t bottom;

	// Bitmap region.
	int16_t width;
	int16_t height;

	// Pixel size
	int16_t pixelSize;

	// Pixel offset from screen
	int16_t xoff;
	int16_t yoff;
} AXDisplayBoundary;

/*
 *	Simple layout calculations
 */

static CGPoint CalcPoint(int16_t x, int16_t y, AXDisplayBoundary b)
{
	CGPoint pt;

	pt.x = b.xoff + (x + b.left) * b.pixelSize;
	pt.y = b.yoff + (y + b.top) * b.pixelSize;

	return pt;
}

static CGRect CalcRect(int16_t x, int16_t y, AXDisplayBoundary b)
{
	CGRect r;

	r.origin = CalcPoint(x, y, b);
	r.size.width = b.pixelSize;
	r.size.height = b.pixelSize;

	return r;
}


/*
 *	Font editor
 */

@interface AXFontEditView ()
{
	/* State for mouse drag */
	NSInteger lastX;
	NSInteger lastY;
	BOOL bitValue;
	BOOL mouseDown;

	NSInteger curX;
	NSInteger curY;
}
@property (strong, nonatomic) AXDocument *document;
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
}

- (void)reloadCharacter:(NSNotification *)n
{
	NSNumber *num = n.userInfo[@"char"];

	if (num.integerValue == self.charIndex) {
		self.character = [self.document characterAtCode:self.charIndex];
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

- (void)setDocument:(AXDocument *)doc
{
	_document = doc;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCharacter:) name:NOTIFY_CHARACTERCHANGED object:doc];
}

/*
 *	Get pixel size, boundaries. This includes the offsets and origin setbacks
 */

- (AXDisplayBoundary)pixelSize
{
	CGSize size = self.bounds.size;

	if ((self.character.width == 0) || (self.character.height == 0)) {
		return (AXDisplayBoundary){ 0,0,0,0,
									0,0,
									32,
									size.width/2,size.height/2 };
	}

	AXDisplayBoundary b;
	int16_t tmp;

	b.left = 0;
	b.top = 0;
	b.right = self.character.width;
	b.bottom = self.character.height;

	b.width = self.character.width;
	b.height = self.character.height;

	/*
	 *	If the character xoffset is less than zero, grow our rectangle
	 */

	if (self.character.xOffset < 0) {
		b.left = self.character.xOffset;
	}
	if (self.character.yOffset < 0) {
		b.top = self.character.yOffset;
	}
	if (self.character.yOffset > b.bottom) {
		b.bottom = self.character.yOffset;
	}

	tmp = self.character.xOffset + self.character.xAdvance;
	if (b.right < tmp) b.right = tmp;

	/*
	 *	Calculate the pixel size
	 */

	NSInteger w = b.right - b.left;
	NSInteger h = b.bottom - b.top;

	NSInteger pixSize = (size.width - 20) / w;
	NSInteger pixSizeY = (size.height - 20) / h;
	if (pixSize > pixSizeY) pixSize = pixSizeY;

	if (pixSize > 32) pixSize = 32;
	if (pixSize < 2) pixSize = 2;

	b.pixelSize = pixSize;

	/*
	 *	Find the x offset and y offset
	 */

	b.xoff = (size.width - pixSize * w)/2;
	b.yoff = (size.height - pixSize * h)/2;

	return b;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

	[[NSColor whiteColor] setFill];
	NSRectFill(self.bounds);

    if (self.character == nil) return;

	/*
	 *	Get pixel information
	 */

	AXDisplayBoundary b = [self pixelSize];

	/*
	 *	Draw pixels
	 */

	[[NSColor blackColor] setFill];
    for (uint8_t x = 0; x < b.width; ++x) {
    	for (uint8_t y = 0; y < b.height; ++y) {
    		BOOL flag = [self.character getBitAtX:x y:y];
    		if (flag) {
	    		CGRect r = CalcRect(x,y,b);
    			NSRectFill(r);
			}
		}
	}

    /*
     *	Draw full grid in very light gray
     */

	NSBezierPath *path = [[NSBezierPath alloc] init];
	for (NSInteger i = b.left; i <= b.right; ++i) {
		CGPoint pt1 = CalcPoint(i, b.top, b);
		CGPoint pt2 = CalcPoint(i, b.bottom, b);

		pt1.x += 0.5;
		pt2.x += 0.5;
		[path moveToPoint:pt1];
		[path lineToPoint:pt2];
	}
	for (NSInteger i = b.top; i <= b.bottom; ++i) {
		CGPoint pt1 = CalcPoint(b.left, i, b);
		CGPoint pt2 = CalcPoint(b.right, i, b);

		pt1.y += 0.5;
		pt2.y += 0.5;
		[path moveToPoint:pt1];
		[path lineToPoint:pt2];
	}
	[[NSColor colorWithWhite:0.93 alpha:1.0] setStroke];
	[path stroke];

	/*
	 *	Draw bitmap visible grid
	 */

	path = [[NSBezierPath alloc] init];
	for (NSInteger i = 0; i <= b.width; ++i) {
		CGPoint pt1 = CalcPoint(i, 0, b);
		CGPoint pt2 = CalcPoint(i, b.height, b);

		pt1.x += 0.5;
		pt2.x += 0.5;
		[path moveToPoint:pt1];
		[path lineToPoint:pt2];
	}
	for (NSInteger i = 0; i <= b.height; ++i) {
		CGPoint pt1 = CalcPoint(0, i, b);
		CGPoint pt2 = CalcPoint(b.width, i, b);

		pt1.y += 0.5;
		pt2.y += 0.5;
		[path moveToPoint:pt1];
		[path lineToPoint:pt2];
	}
	[[NSColor colorWithWhite:0.5 alpha:1.0] setStroke];
	[path stroke];

	/*
	 *	Draw xoffset/yoffset origin if visible
	 */

	int8_t xOff = self.character.xOffset;
	int8_t yOff = self.character.yOffset;

	/*
	 *	Draw the origin and the width of the character as a line to the
	 *	next origin
	 */

	CGPoint ptOrigin = CalcPoint(xOff, yOff, b);
	CGPoint ptNext = CGPointMake(ptOrigin.x + self.character.xAdvance * b.pixelSize, ptOrigin.y);

	[[NSColor blueColor] setFill];

	CGRect r = CGRectMake(ptOrigin.x - 4, ptOrigin.y - 4, 8, 8);
	NSBezierPath *p = [[NSBezierPath alloc] init];
	[p appendBezierPathWithOvalInRect:r];

	r = CGRectMake(ptNext.x - 3, ptNext.y - 3, 6, 6);
	[p appendBezierPathWithOvalInRect:r];

	[p fill];

	p = [[NSBezierPath alloc] init];
	[p moveToPoint:ptOrigin];
	[p lineToPoint:ptNext];
	[p setLineWidth:2];
	[[NSColor blueColor] setStroke];
	[p stroke];
}

- (void)setCharacter:(AXCharacter *)ch atIndex:(uint8_t)ix
{
	self.character = ch;
	self.charIndex = ix;
	[self setNeedsDisplay:YES];
}

- (BOOL)findPosition:(CGPoint)loc
{
    uint8_t width = self.character.width;
    uint8_t height = self.character.height;
	AXDisplayBoundary b = [self pixelSize];

//	pt.x = b.xoff + (x + b.left) * b.pixelSize;
//	pt.y = b.yoff + (y + b.top) * b.pixelSize;
	NSInteger x = (loc.x - b.xoff) / b.pixelSize - b.left;
	NSInteger y = (loc.y - b.yoff) / b.pixelSize - b.top;

	if ((x < 0) || (x >= width)) return NO;
	if ((y < 0) || (y >= height)) return NO;

	curX = x;
	curY = y;
	return YES;
}

- (void)mouseDown:(NSEvent *)event
{
	if (self.character == nil) return;

	mouseDown = NO;
	CGPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
	if (![self findPosition:loc]) return;

	/*
	 *	Determine where we clicked
	 */

	bitValue = ![self.character getBitAtX:curX y:curY];
	lastX = curX;
	lastY = curY;
	mouseDown = YES;

	[self.document setBit:self.charIndex withValue:bitValue atX:curX y:curY];
}

- (void)mouseUp:(NSEvent *)event
{
	mouseDown = NO;
}

- (void)mouseDragged:(NSEvent *)event
{
	if (!mouseDown) return;

	CGPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
	if (![self findPosition:loc]) return;

	if ((lastX == curX) && (lastY == curY)) return;	// drag within pixel
	lastX = curX;
	lastY = curY;

	if (bitValue != [self.character getBitAtX:curX y:curY]) {
		[self.document setBit:self.charIndex withValue:bitValue atX:curX y:curY];
	}
}

@end
