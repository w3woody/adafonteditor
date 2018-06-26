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
@end

@implementation AXLayoutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.firstCode.integerValue = self.document.first;
	self.lastCode.integerValue = self.document.last;
	self.yHeight.integerValue = self.document.yHeight;
}

- (IBAction)doUpdate:(id)sender
{
	uint8_t f = self.firstCode.integerValue;
	uint8_t l = self.lastCode.integerValue;
	uint8_t y = self.yHeight.integerValue;

	[self.document setFontWithFirstCode:f lastCode:l yHeight:y];

	if (self.close) self.close();
}

- (IBAction)doCancel:(id)sender
{
	if (self.close) self.close();
}

@end
