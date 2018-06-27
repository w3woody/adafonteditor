//
//  AXFontSelectorView.h
//  AdaFontEditor
//
//  Created by William Woody on 6/27/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AXDocument;

@interface AXFontSelectorView : NSView

- (void)setDocument:(AXDocument *)document;

@property (copy) void (^updateSelection)(NSInteger index);

- (NSInteger)selected;
- (void)setSelected:(NSInteger)charIndex;

@end
