//
//  AXGlyphAttributes.h
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *	This tracks all the attributes associated with the generated glyph
 */

@interface AXGlyphAttributes : NSObject

@property (strong) NSBezierPath *path;
@property (assign) NSPoint offset;
@property (assign) CGFloat advance;
@property (assign) CGRect bounds;

@end
