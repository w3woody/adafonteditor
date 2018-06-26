//
//  AXFontExport.h
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AXDocument;

/*
 *	Font export engine. This generates the appropriate contents for our
 *	font that works with the Adafruit GFX library (and in the future,
 *	potentially other bitmap libraries).
 */

@interface AXFontExport : NSObject

- (instancetype)initWithDocument:(AXDocument *)doc url:(NSURL *)url;

- (void)export;

@end
