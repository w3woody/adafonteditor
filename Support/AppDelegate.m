//
//  AppDelegate.m
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (strong) NSWindowController *createFont;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


- (IBAction)newDocumentFromFont:(id)sender
{
	// NewFontWindow
	if (self.createFont == nil) {
		self.createFont = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"NewFontWindow"];
	}
	[self.createFont showWindow:nil];
}

@end

