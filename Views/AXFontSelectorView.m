//
//  AXFontSelectorView.m
//  AdaFontEditor
//
//  Created by William Woody on 6/27/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontSelectorView.h"
#import "AXDocument.h"
#import "AXExtendedASCII.h"

#define CELLWIDTH		50
#define CELLHEIGHT		70
#define CELLSPACING		5
#define LABELHEIGHT		20

@interface AXFontSelectorView ()
{
	// Layout parameters
	CGFloat cachedWidth;
	NSInteger firstChar;
	NSInteger numChar;
	NSInteger xOffset;
	NSInteger columns;

	// Selection
	NSInteger curSelection;
}

@property (strong) AXDocument *doc;
@property (weak) IBOutlet NSLayoutConstraint *heightConstraint;
@end

@implementation AXFontSelectorView

- (void)internalInit
{
	curSelection = -1;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if (nil != (self = [super initWithCoder:decoder])) {
		[self internalInit];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if (nil != (self = [super initWithFrame:frameRect])) {
		[self internalInit];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 *	Layout
 */

- (void)layout
{
	[super layout];

	/*
	 *	Get the document parameters and layout if we have changed our width.
	 */

	if (self.doc == nil) return;
	if (cachedWidth == self.bounds.size.width) return;
	cachedWidth = self.bounds.size.width;
	[self calcLayout];
}

- (void)calcLayout
{
	CGSize size = self.bounds.size;

	// Get the old selection character if we have a selection
	NSInteger oldSelect = self.selected;
	if (oldSelect >= 0) oldSelect += firstChar;

	// Number of cells across
	columns = (size.width - CELLSPACING)/(CELLSPACING + CELLWIDTH);
	if (columns < 1) columns = 1;

	// Offset from left to center our cells
	xOffset = (size.width + CELLSPACING - (CELLSPACING + CELLWIDTH) * columns)/2;

	// Character range
	firstChar = self.doc.first;
	numChar = self.doc.last - self.doc.first + 1;

	// Resize height of view. (This triggers a layout, but we prevent this
	// routine from being called again by screening by width in -layout.)
	NSInteger rows = (numChar + columns - 1)/columns;
	CGFloat h = CELLSPACING + rows * (CELLSPACING + CELLHEIGHT);
	self.heightConstraint.constant = h;

	// Now update our selection
	if (oldSelect >= 0) {
		NSInteger newSelect = oldSelect - firstChar;
		if ((newSelect < 0) || (newSelect > numChar)) newSelect = -1;

		[self setSelected:newSelect];
	}

	// And force redraw
	[self setNeedsDisplay:YES];
}

- (void)setDocument:(AXDocument *)document
{
	self.doc = document;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_DOCUMENTCHANGED object:self.doc];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_ALLCHANGED object:self.doc];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCharacter:) name:NOTIFY_CHARACTERCHANGED object:self.doc];

	[self calcLayout];		// This forces a relayout.
}

- (void)reloadDocument:(NSNotification *)n
{
	[self calcLayout];		// force layout and red
}

- (void)reloadCharacter:(NSNotification *)n
{
	// Force redraw of character cell only
	NSNumber *ch = n.userInfo[@"char"];
	NSInteger index = ch.integerValue - firstChar;
	[self setNeedsDisplayInRect:[self calcLocationOfIndex:index]];
}

/*
 *	Drawing support
 */

- (CGRect)calcLocationOfIndex:(NSInteger)index
{
	CGRect r;

	NSInteger x = index % columns;
	NSInteger y = index / columns;

	r.origin.x = xOffset + x * (CELLWIDTH + CELLSPACING);
	r.origin.y = CELLSPACING + y * (CELLHEIGHT + CELLSPACING);
	r.size.width = CELLWIDTH;
	r.size.height = CELLHEIGHT;

	return r;
}

- (void)drawCharacterAtIndex:(NSInteger)index selected:(BOOL)sel atLocation:(CGRect)r
{
	NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
	BOOL dark = [osxMode isEqualToString:@"Dark"];

	NSColor *lcolor;
	if (sel) {
		lcolor = [NSColor colorWithDeviceRed:0.640 green:0.720 blue:0.800 alpha:1.0];
	} else {
		if (dark) {
			lcolor = [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:1.0];
		} else {
			lcolor = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:1.0];
		}
	}
	[lcolor setStroke];
	[lcolor setFill];

	/*
	 *	Draw borders
	 */

	CGRect tmp = CGRectInset(r, 0.5, 0.5);
	NSFrameRect(tmp);

	tmp = r;
	tmp.size.height = LABELHEIGHT;
	NSRectFill(tmp);

	/*
	 *	Draw label
	 */

	uint8_t ch = (uint8_t)(index + firstChar);

	NSString *label;
	if (ch < 32) {
		label = [NSString stringWithFormat:@"$%02X",ch];
	} else if (ch == 32) {
		label = @"sp";
	} else {
		label = [NSString stringWithFormat:@"%C",AXExtendedASCIIToUnicode(ch)];
	}

	NSColor *letterColor = dark ? [NSColor whiteColor] : [NSColor blackColor];
	NSFont *font = [NSFont systemFontOfSize:12];
	NSDictionary *d = @{ NSFontAttributeName: font,
						 NSForegroundColorAttributeName: letterColor };
	CGSize size = [label sizeWithAttributes:d];

	tmp.origin.y += (tmp.size.height - size.height)/2;
	tmp.origin.x += 5;
	[label drawInRect:tmp withAttributes:d];

	/*
	 *	Draw character image
	 */

	AXCharacter *character = [self.doc characterAtCode:ch];
	NSImage *image = character.bitmapImage;
	CGSize imageSize = image.size;

	tmp = r;
	tmp.origin.y += LABELHEIGHT;
	tmp.size.height -= LABELHEIGHT;
	tmp = CGRectInset(tmp, 3, 3);

	if (imageSize.width > tmp.size.width) {
		imageSize.height *= tmp.size.width / imageSize.width;
		imageSize.width = tmp.size.width;
	}
	if (imageSize.height > tmp.size.height) {
		imageSize.width *= tmp.size.height / imageSize.height;
		imageSize.height = tmp.size.height;
	}

	tmp.origin.x += floor((tmp.size.width - imageSize.width)/2);
	tmp.origin.y += floor((tmp.size.height - imageSize.height)/2);
	tmp.size = imageSize;

	[image drawInRect:tmp];
}

/*
 *	Entry points
 */

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

	NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
	BOOL dark = [osxMode isEqualToString:@"Dark"];

	if (dark) {
	    [[NSColor colorWithWhite:0.1 alpha:1.0] setFill];
	} else {
	    [[NSColor whiteColor] setFill];
	}
    NSRectFill(self.bounds);

    for (NSInteger i = 0; i < numChar; ++i) {
		CGRect r = [self calcLocationOfIndex:i];
		if (CGRectIntersectsRect(dirtyRect, r)) {
			[self drawCharacterAtIndex:i selected:(i == curSelection) atLocation:r];
		}
	}
}

- (NSInteger)selected
{
	return curSelection;
}

- (void)setSelected:(NSInteger)charIndex
{
	if (charIndex != curSelection) {
		curSelection = charIndex;
		[self setNeedsDisplay:YES];

		if (self.updateSelection) self.updateSelection(curSelection);
	}
}

/*
 *	Mouse events
 */

- (void)mouseDown:(NSEvent *)event
{
}

- (void)mouseUp:(NSEvent *)event
{
	if (self.doc == nil) return;

	CGPoint loc = [self convertPoint:event.locationInWindow fromView:nil];

	/*
	 *	Find x,y
	 */

	NSInteger x = (loc.x - xOffset)/(CELLWIDTH + CELLSPACING);
	if ((x < 0) || (x >= columns)) return;

	NSInteger y = (loc.y - CELLSPACING)/(CELLHEIGHT + CELLSPACING);
	if (y < 0) return;

	NSInteger selIndex = x + y * columns;
	if ((selIndex < 0) || (selIndex >= numChar)) return;

	[self setSelected:selIndex];
}

- (void)mouseDragged:(NSEvent *)event
{
}


@end
