//
//  AXAttributesViewController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXAttributesViewController.h"

@interface AXAttributesViewController ()
@property (weak) IBOutlet NSTextField *width;
@property (weak) IBOutlet NSTextField *height;
@property (weak) IBOutlet NSTextField *xAdvance;
@property (weak) IBOutlet NSTextField *xOffset;
@property (weak) IBOutlet NSTextField *yOffset;
@end

@implementation AXAttributesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	AXCharacter *ch = [self.document characterAtIndex:self.charIndex];
    self.width.integerValue = ch.width;
    self.height.integerValue = ch.height;
    self.xAdvance.integerValue = ch.xAdvance;
    self.xOffset.integerValue = ch.xOffset;
    self.yOffset.integerValue = ch.yOffset;
}

- (IBAction)doUpdate:(id)sender
{
	uint8_t w = self.width.integerValue;
	uint8_t h = self.height.integerValue;
	uint8_t ad = self.xAdvance.integerValue;
	uint8_t x = self.xOffset.integerValue;
	uint8_t y = self.yOffset.integerValue;

	[self.document setCharacter:self.charIndex bitmapWidth:w height:h xAdvance:ad xOffset:x yOffset:y];

	if (self.close) self.close();
}

- (IBAction)doCancel:(id)sender
{
	if (self.close) self.close();
}

@end
