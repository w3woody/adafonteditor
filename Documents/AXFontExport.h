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


/*
 *	The Adafruit GFX library has the following format:
 *
 *		typedef struct { // Data stored PER GLYPH
 *			uint16_t bitmapOffset;     // Pointer into GFXfont->bitmap
 *			uint8_t  width, height;    // Bitmap dimensions in pixels
 *			uint8_t  xAdvance;         // Distance to advance cursor (x axis)
 *			int8_t   xOffset, yOffset; // Dist from cursor pos to UL corner
 *		} GFXglyph;
 *
 *		typedef struct { // Data stored for FONT AS A WHOLE:
 *			uint8_t  *bitmap;      // Glyph bitmaps, concatenated
 *			GFXglyph *glyph;       // Glyph array
 *			uint8_t   first, last; // ASCII extents
 *			uint8_t   yAdvance;    // Newline distance (y axis)
 *		} GFXfont;
 */

@interface AXFontExport : NSObject

- (instancetype)initWithDocument:(AXDocument *)doc url:(NSURL *)url;

- (void)export;

@end
