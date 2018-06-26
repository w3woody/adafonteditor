//
//  AXLayoutManager.h
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXGlyphAttributes.h"

/*
 *	We use this method to hook glyphs so we can convert a string or character
 *	into a bezier for rendering
 */

@interface AXLayoutManager : NSLayoutManager

@property (strong) NSMutableArray<AXGlyphAttributes *> *axGlyphs;

    /* convert the NSString into a NSBezierPath using a specific font. */
- (void)showCGGlyphs:(const CGGlyph *)glyphs
           positions:(const NSPoint *)positions
               count:(NSUInteger)glyphCount
                font:(NSFont *)font
              matrix:(NSAffineTransform *)textMatrix
          attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
           inContext:(NSGraphicsContext *)graphicsContext;

@end
