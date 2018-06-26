//
//  AXFontEditView.h
//  AdaFontEditor
//
//  Created by William Woody on 6/25/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXCharacter.h"
#import "AXDocument.h"

@interface AXFontEditView : NSView

- (void)setDocument:(AXDocument *)doc;
- (void)setCharacter:(AXCharacter *)ch atIndex:(uint8_t)ch;

- (void)clearCharacter;

@end
