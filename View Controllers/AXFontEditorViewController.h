//
//  AXFontEditorViewController.h
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AXDocument;

@interface AXFontEditorViewController : NSViewController

- (IBAction)showFontAttributes:(id)sender;
- (IBAction)showCharacterAttributes:(id)sender;
- (IBAction)delete:(id)sender;

@end

