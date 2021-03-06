//
//  AXWindowController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXWindowController.h"
#import "AXFontEditorViewController.h"
#import "AXFontExport.h"
#import "AXDocument.h"

@interface AXWindowController ()

@end

@implementation AXWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

/*
 *	It appears the proper idiom on macOS to set the document inside my view
 *	controller that is contained in this window controller is to watch for
 *	a 'setDocument' call--and pass it down to the view controller's
 *	'representedObject'. The view controller uses this 'representedObject' as
 *	a reference to the data model that view controller is displaying.
 */

- (void)setDocument:(id)document
{
	[super setDocument:document];

	// Tell my view controller what document it is working with.
	[(AXFontEditorViewController *)(self.window.contentViewController) setRepresentedObject:document];
}

- (IBAction)export:(id)sender
{
	NSSavePanel *panel = [[NSSavePanel alloc] init];
	panel.title = @"Export Font";
	panel.prompt = @"Export Font";
	panel.extensionHidden = NO;
	panel.allowedFileTypes = @[ @"fontsrc" ];

	AXDocument *doc = (AXDocument *)self.document;
	NSURL *url = doc.exportURL;
	panel.nameFieldStringValue = [url lastPathComponent];
	NSURL *dir = [url URLByDeletingLastPathComponent];
	[panel setDirectoryURL:dir];

	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {

			AXFontExport *export = [[AXFontExport alloc] initWithDocument:doc url:panel.URL];
			[export export];

			doc.exportURL = panel.URL;
		}
	}];
}

@end
