//
//  AXLayoutViewController.h
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXDocument.h"

@interface AXLayoutViewController : NSViewController

@property (strong) AXDocument *document;
@property (copy) void (^close)(void);

@end
