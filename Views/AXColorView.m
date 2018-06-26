//
//  AXColorView.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXColorView.h"

@interface AXColorView ()
@property (nonatomic, assign) BOOL selected;
@end

@implementation AXColorView

- (void)drawRect:(NSRect)dirtyRect
{
	if (self.selected) {
		[[NSColor colorWithDeviceRed:0.810 green:0.855 blue:0.900 alpha:1.0] setFill];
	} else {
		[[NSColor whiteColor] setFill];
	}
	NSRectFill(self.bounds);
}

- (void)setSelected:(BOOL)flag
{
	_selected = flag;
	[self setNeedsDisplay:YES];
}

@end
