//
//  AXCharacterViewItem.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXCharacterViewItem.h"
#import "AXColorView.h"

@interface AXCharacterViewItem ()

@end

@implementation AXCharacterViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[(AXColorView *)self.view setSelected:selected];
}

@end
