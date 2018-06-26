//
//  NSViewController+Document.m
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "NSViewController+Document.h"

@implementation NSViewController (Document)

- (NSDocument *)document
{
	NSWindow *w = self.view.window;
	NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForWindow:w];
	return doc;
}

@end
