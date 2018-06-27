//
//  AXFontEditorViewController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontEditorViewController.h"
#import "AXFontEditView.h"
#import "AXFontSelectorView.h"
#import "AXDocument.h"
#import "AXLayoutViewController.h"
#import "AXAttributesViewController.h"
#import "AXExtendedASCII.h"

@interface AXFontEditorViewController ()
@property (weak) IBOutlet AXFontSelectorView *selectorView;
@property (weak) IBOutlet AXFontEditView *fontEditor;
@end

@implementation AXFontEditorViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	/*
	 *	At this point we do some wiring up--we connect our selector view
	 *	to a method to update the font editor contents
	 */

	self.selectorView.updateSelection = ^(NSInteger index) {
		AXDocument *doc = (AXDocument *)self.representedObject;
		AXCharacter *ch = [doc characterAtIndex:index + doc.first];
		[self.fontEditor setCharacter:ch atIndex:index + doc.first];
	};
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.

	/*
	 *	Register the notification listeners.
	 */

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_DOCUMENTCHANGED object:representedObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_ALLCHANGED object:representedObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCharacter:) name:NOTIFY_CHARACTERCHANGED object:representedObject];

	/*
	 *	Let our views know where they're getting their data from
	 */

	[self.fontEditor setDocument:(AXDocument *)representedObject];
	[self.selectorView setDocument:(AXDocument *)representedObject];
}

/*
 *	Menu items
 */

- (IBAction)showFontAttributes:(id)sender
{
	[self performSegueWithIdentifier:@"docLayoutSegue" sender:self];
}

- (IBAction)showCharacterAttributes:(id)sender
{
	if (self.selectorView.selected < 0) return;

	[self performSegueWithIdentifier:@"charAttrSegue" sender:self];
}

- (IBAction)delete:(id)sender
{
	[self.fontEditor clearCharacter];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"docLayoutSegue"]) {
		AXLayoutViewController *lvc = (AXLayoutViewController *)segue.destinationController;
		__weak AXLayoutViewController *wlvc = lvc;
		lvc.document = (AXDocument *)self.representedObject;
		lvc.close = ^{
			[self dismissViewController:wlvc];
		};
	} else if ([segue.identifier isEqualToString:@"charAttrSegue"]) {
		AXDocument *doc = (AXDocument *)self.representedObject;
		NSInteger code = doc.first + self.selectorView.selected;

		AXAttributesViewController *lvc = (AXAttributesViewController *)segue.destinationController;
		__weak AXAttributesViewController *wlvc = lvc;
		lvc.document = doc;
		lvc.charIndex = code;
		lvc.close = ^{
			[self dismissViewController:wlvc];
		};
	}
}

/*
 *	Document Notifications
 */

- (void)reloadDocument:(NSNotification *)n
{
	// ### Note: we do nothing here; our selector view will also reload,
	// and send an update selection notification if necessary
}

- (void)reloadCharacter:(NSNotification *)n
{
	// ### Note: we do nothing here; our selector view responds to this
	// message.
}

/*
 *	Functions
 */

- (IBAction)trimFontBitmaps:(id)sender
{
	[(AXDocument *)self.representedObject trimFontBitmaps];
}

@end
