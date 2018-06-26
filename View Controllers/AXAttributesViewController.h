//
//  AXAttributesViewController.h
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXDocument.h"

@interface AXAttributesViewController : NSViewController

@property (strong) AXDocument *document;
@property (assign) uint8_t charIndex;
@property (copy) void (^close)(void);

@end
