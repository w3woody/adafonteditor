//
//  AXLayoutViewController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXLayoutViewController.h"

@interface AXLayoutViewController ()
@property (weak) IBOutlet NSTextField *firstCode;
@property (weak) IBOutlet NSTextField *lastCode;
@property (weak) IBOutlet NSTextField *yHeight;

@property (weak) IBOutlet NSTextField *ascender;
@property (weak) IBOutlet NSTextField *capHeight;
@property (weak) IBOutlet NSTextField *xHeight;
@property (weak) IBOutlet NSTextField *descHeight;
@end

@implementation AXLayoutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.firstCode.integerValue = self.document.first;
	self.lastCode.integerValue = self.document.last;
	self.yHeight.integerValue = self.document.yHeight;

	self.ascender.integerValue = self.document.ascender;
	self.capHeight.integerValue = self.document.capHeight;
	self.xHeight.integerValue = self.document.xHeight;
	self.descHeight.integerValue = self.document.descHeight;
}

- (IBAction)doUpdate:(id)sender
{
	uint8_t f = self.firstCode.integerValue;
	uint8_t l = self.lastCode.integerValue;
	uint8_t y = self.yHeight.integerValue;

	uint8_t a = self.ascender.integerValue;
	uint8_t c = self.capHeight.integerValue;
	uint8_t x = self.xHeight.integerValue;
	uint8_t d = self.descHeight.integerValue;

	[self.document setFontWithFirstCode:f lastCode:l yHeight:y ascender:a capHeight:c xHeight:x descHeight:d];

	if (self.close) self.close();
}

- (IBAction)doCancel:(id)sender
{
	if (self.close) self.close();
}

@end
