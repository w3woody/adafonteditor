//
//  AXFontViewController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontViewController.h"
#import "AXFontView.h"
#import "AXDocument.h"

@interface AXFontViewController ()
@property (weak) IBOutlet AXFontView *fontView;
@property (weak) IBOutlet NSPopUpButton *fontPopup;
@property (weak) IBOutlet NSPopUpButton *stylePopup;
@property (weak) IBOutlet NSComboBox *sizePopup;
@property (weak) IBOutlet NSTextField *fromChar;
@property (weak) IBOutlet NSTextField *toChar;

@property (strong) NSArray<NSArray *> *selFontFamily;
@end

@implementation AXFontViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self resetFontList];
    [self resetFontSizes];
    [self updateDisplayedFont];
}

- (IBAction)doClose:(id)sender
{
	[self.view.window close];
}

- (IBAction)doCreate:(id)sender
{
	/*
	 *	Emulate 'new' but with our parameter
	 */

	AXDocument *doc = [[AXDocument alloc] initWithFont:[self currentFont] first:self.fromChar.integerValue last:self.toChar.integerValue];
	[doc makeWindowControllers];
	[doc showWindows];

	[[NSDocumentController sharedDocumentController] addDocument:doc];

	[self.view.window close];
}

/*
 *	Font management
 */

- (void)resetFontList
{
	NSFontManager *m = [NSFontManager sharedFontManager];

	NSArray<NSString *> *families = [m availableFontFamilies];
	[self.fontPopup removeAllItems];
	for (NSString *str in families) {
		[self.fontPopup addItemWithTitle:str];
	}
	[self.fontPopup selectItemWithTitle:@"Helvetica"];

	/*
	 *	Now reset the styles
	 */

	[self resetFontStyles];
}

- (void)resetFontStyles
{
	NSFontManager *m = [NSFontManager sharedFontManager];
	NSString *fontFamily = [self.fontPopup titleOfSelectedItem];

	self.selFontFamily = [m availableMembersOfFontFamily:fontFamily];
	[self.stylePopup removeAllItems];
	for (NSArray *item in self.selFontFamily) {
		NSString *name = item[1];
		[self.stylePopup addItemWithTitle:name];
	}

	/*
	 *	Select the first item
	 */

	[self.stylePopup selectItemAtIndex:0];

	/*
	 *	Reset the font display
	 */

	[self updateDisplayedFont];
}

- (void)resetFontSizes
{
	[self.sizePopup removeAllItems];
	for (NSString *item in @[ @"9", @"10", @"12", @"16", @"20", @"24" ]) {
		[self.sizePopup addItemWithObjectValue:item];
	}

	[self.sizePopup selectItemAtIndex:2];
}

/*
 *	Popup Changes
 */

- (IBAction)fontChanged:(id)sender
{
	[self resetFontStyles];
	[self updateDisplayedFont];
}

- (IBAction)styleChanged:(id)sender
{
	[self updateDisplayedFont];
}

- (IBAction)sizeChanged:(id)sender
{
	[self updateDisplayedFont];
}

/*
 *	Font display
 */

- (NSFont *)currentFont
{
	/*
	 *	The font selection drives the style selection, and the full font
	 *	name is in the style array.
	 */

	NSInteger index = self.stylePopup.indexOfSelectedItem;
	NSArray *name = self.selFontFamily[index];
	NSString *fontName = name[0];

	NSFont *font = [NSFont fontWithName:fontName size:self.sizePopup.integerValue];
	return font;
}

- (void)updateDisplayedFont
{
	[self.fontView setFont:[self currentFont]];
}

@end
