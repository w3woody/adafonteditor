//
//  AXDocument.h
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXCharacter.h"

/*
 *	Document contents changed notifications. We use notifications to indicate
 *	that our document or a character changed so our editors can keep in sync
 *	during editing or during undo.
 */

// Notify that a global document setting has changed. This implies
// NOTIFY_ALLCHANGED below.
#define NOTIFY_DOCUMENTCHANGED	@"NOTIFY_DOCUMENTCHANGED"

// Notify all characters changed. This implies NOTIFY_CHARACTERCHANGED
// for all characters in our font.
#define NOTIFY_ALLCHANGED		@"NOTIFY_ALLCHANGED"

// Notify that a character (bitmap or attributes) has changed. Note that
// the character that changed is given in the @"char" param of the
// user data dictionary.
#define NOTIFY_CHARACTERCHANGED @"NOTIFY_CHARACTERCHANGED"


/*
 *	Document class
 */

@interface AXDocument : NSDocument

- (instancetype)init;
- (instancetype)initWithFont:(NSFont *)font first:(uint8_t)first last:(uint8_t)last;

/*
 *	Document export URL
 */

- (NSURL *)exportURL;
- (void)setExportURL:(NSURL *)url;

/*
 *	Document contents
 */

- (uint8_t)first;
- (uint8_t)last;
- (uint8_t)yHeight;

/*
 *	Document layout parameters
 */

- (uint8_t)ascender;
- (uint8_t)capHeight;
- (uint8_t)xHeight;
- (uint8_t)descHeight;

/*
 *	Character contents
 */

- (AXCharacter *)characterAtCode:(uint8_t)index;
- (void)setCharacter:(AXCharacter *)ch atCode:(uint8_t)index;

/*
 *	Document Settings
 */

- (void)setFontWithFirstCode:(uint8_t)code lastCode:(uint8_t)ecode
		yHeight:(uint8_t)height ascender:(uint8_t)ascender
		capHeight:(uint8_t)capHeight xHeight:(uint8_t)xHeight
		descHeight:(uint8_t)descHeight;

/*
 *	Character manipulation
 */

- (void)setCharacter:(uint8_t)code bitmapWidth:(uint8_t)width height:(uint8_t)height xAdvance:(uint8_t)adv xOffset:(int8_t)xoff yOffset:(int8_t)yoff;
- (void)clearCharacterAtCode:(uint8_t)code;

- (void)trimFontBitmaps;

- (void)flipCharacterHorizontally:(uint8_t)code;
- (void)flipCharacterVertically:(uint8_t)code;

/*
 *	Character editing. Basically we set and clear individual pixels when
 *	we edit characters. This may seem time consuming, but this provides
 *	for
 */

- (void)setBit:(uint8_t)code withValue:(BOOL)value atX:(uint8_t)x y:(uint8_t)y;

@end
