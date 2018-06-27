//
//  AXDocument.m
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXDocument.h"
#import "AXFontBitmapBuilder.h"

@interface AXDocument ()
@property (strong) NSMutableArray<AXCharacter *> *characters;
@property (assign) uint8_t first;
@property (assign) uint8_t last;
@property (assign) uint8_t yHeight;
@property (strong) NSURL *export;
@end

@implementation AXDocument

- (instancetype)init
{
    self = [super init];
    if (self) {
		self.first = 32;
		self.last = 126;
		self.yHeight = 8;

		self.characters = [[NSMutableArray alloc] init];
		for (uint8_t i = 32; i <= 126; ++i) {
			[self.characters addObject:[[AXCharacter alloc] init]];
		}
    }
    return self;
}

- (instancetype)initWithFont:(NSFont *)font first:(uint8_t)first last:(uint8_t)last
{
    self = [super init];
    if (self) {
		AXFontBitmapBuilder *builder = [[AXFontBitmapBuilder alloc] initWithFont:font start:first end:last];

		self.first = builder.first;
		self.last = builder.last;
		self.yHeight = builder.yHeight;
		self.characters = builder.characters;

		[self updateChangeCount:NSChangeDone];
    }
    return self;
}

+ (BOOL)autosavesInPlace
{
	return YES;
}

- (void)makeWindowControllers
{
	// Override to return the Storyboard file name of the AXDocument.
	[self addWindowController:[[NSStoryboard storyboardWithName:@"Editor" bundle:nil] instantiateInitialController]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	/*
	 *	Format the data as a dictionary for JSON
	 */

	NSMutableArray *ach = [[NSMutableArray alloc] init];
	for (AXCharacter *ch in self.characters) {
		[ach addObject:[ch json]];
	}

	NSString *exportPath = self.export.absoluteString;
	if (exportPath == nil) exportPath = @"";
	NSDictionary *d = @{ @"export": exportPath,
						 @"characters": ach,
						 @"first": @(self.first),
						 @"last": @(self.last),
						 @"yHeight": @(self.yHeight) };
	return [NSJSONSerialization dataWithJSONObject:d  options:NSJSONWritingPrettyPrinted error:nil];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data  options:0 error:nil];

	self.first = [(NSNumber *)d[@"first"] integerValue];
	self.last = [(NSNumber *)d[@"last"] integerValue];
	self.yHeight = [(NSNumber *)d[@"yHeight"] integerValue];
	NSArray<NSDictionary *> *a = (NSArray<NSDictionary *> *)d[@"characters"];

	NSString *exportPath = (NSString *)d[@"export"];
	if (exportPath.length == 0) {
		self.export = nil;
	} else {
		self.export = [NSURL URLWithString:exportPath];
	}

	self.characters = [[NSMutableArray alloc] init];
	for (NSDictionary *d in a) {
		[self.characters addObject:[[AXCharacter alloc] initWithJson:d]];
	}

	/*
	 *	Sanity check: make sure the count is right.
	 */

	NSInteger ct = self.last - self.first + 1;
	if (ct != self.characters.count) {
		if (outError) {
			NSDictionary *d = @{ NSLocalizedDescriptionKey: @"Font file format error" };
			*outError = [NSError errorWithDomain:@"AXDocument" code:1 userInfo:d];
		}
		return NO;
	}

	return YES;
}

/*
 *	Export URL management
 */

- (NSURL *)exportURL
{
	if (self.export == nil) {
		NSURL *name = [self.fileURL URLByDeletingPathExtension];
		if (name == nil) {
			NSString *str = [@"~/untitled.h" stringByExpandingTildeInPath];
			name = [NSURL fileURLWithPath:str isDirectory:NO];
		} else {
			name = [name URLByAppendingPathExtension:@"h"];
		}
		self.export = name;
	}
	return self.export;
}

- (void)setExportURL:(NSURL *)url
{
	if (![self.export isEqualTo:url]) {
		self.export = url;
		[self updateChangeCount:NSChangeDone];		// Force update count for save
	}
}



/*
 *	Character contents
 */

- (AXCharacter *)characterAtCode:(uint8_t)index
{
	if (index < self.first) return nil;
	if (index > self.last) return nil;
	return self.characters[index - self.first];
}

- (void)setCharacter:(AXCharacter *)ch atCode:(uint8_t)index
{
	if (index < self.first) return;
	if (index > self.last) return;

	AXCharacter *oldChar = self.characters[index - self.first];
	[[self.undoManager prepareWithInvocationTarget:self] setCharacter:oldChar atCode:index];
	[self.undoManager setActionName:@"Replace Character"];

	self.characters[index - self.first] = [[AXCharacter alloc] initWithCharacter:ch];

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(index) }];
}

/*
 *	Document settings
 */

- (void)setFontWithFirstCode:(uint8_t)code lastCode:(uint8_t)ecode yHeight:(uint8_t)height array:(NSArray<AXCharacter *> *)chars
{
	[[self.undoManager prepareWithInvocationTarget:self] setFontWithFirstCode:self.first lastCode:self.last yHeight:self.yHeight array:self.characters];
	[self.undoManager setActionName:@"Update Font Parameters"];

	/*
	 *	Now replace the values
	 */

	self.first = code;
	self.last = ecode;
	self.yHeight = height;
	if (chars != nil) {
		self.characters = [chars mutableCopy];
	}

	/*
	 *	And send notifications
	 */

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_DOCUMENTCHANGED object:self];
}

- (void)setFontWithFirstCode:(uint8_t)code lastCode:(uint8_t)ecode yHeight:(uint8_t)height
{
	/*
	 *	This actually builds the replacement array then invokes our private
	 *	update method
	 */

	NSMutableArray<AXCharacter *> *chars = nil;
	if ((self.first != code) || (self.last != ecode)) {
		chars = [[NSMutableArray alloc] init];
		for (uint16_t x = code; x <= ecode; ++x) {
			AXCharacter *ch = [self characterAtCode:x];
			if (ch == nil) {
				ch = [[AXCharacter alloc] init];
			} else {
				ch = [[AXCharacter alloc] initWithCharacter:ch];
			}
			[chars addObject:ch];
		}
	}

	[self setFontWithFirstCode:code lastCode:ecode yHeight:height array:chars];
}

/*
 *	Character settings
 */

- (void)setCharacter:(uint8_t)code bitmapWidth:(uint8_t)width height:(uint8_t)height xAdvance:(uint8_t)adv xOffset:(int8_t)xoff yOffset:(int8_t)yoff
{
	AXCharacter *ch = [self characterAtCode:code];
	if (ch == nil) return;

	[[self.undoManager prepareWithInvocationTarget:self] setCharacter:code bitmapWidth:ch.width height:ch.height xAdvance:ch.xAdvance xOffset:ch.xOffset yOffset:ch.yOffset];
	[self.undoManager setActionName:@"Update Character Parameters"];

	[ch setWidth:width height:height];
	[ch setXAdvance:adv xOffset:xoff yOffset:yoff];

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(code) }];
}

- (void)replaceCharacter:(AXCharacter *)ch atIndex:(uint8_t)index actionName:(NSString *)actionName
{
	AXCharacter *oldChar = [self characterAtCode:index];
	[[self.undoManager prepareWithInvocationTarget:self] replaceCharacter:oldChar atIndex:index actionName:actionName];
	[self.undoManager setActionName:actionName];
	self.characters[index - self.first] = ch;

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(index) }];
}

- (void)clearCharacterAtCode:(uint8_t)code
{
	AXCharacter *ch = [self characterAtCode:code];
	if (ch == nil) return;

	AXCharacter *clearChar = [[AXCharacter alloc] initWithCharacter:ch];
	[clearChar clearBits];
	[self replaceCharacter:clearChar atIndex:code actionName:@"Clear Character"];
}

- (void)setBit:(uint8_t)code withValue:(BOOL)value atX:(uint8_t)x y:(uint8_t)y
{
	AXCharacter *ch = [self characterAtCode:code];
	if (ch == nil) return;

	[[self.undoManager prepareWithInvocationTarget:self] setBit:code withValue:[ch getBitAtX:x y:y] atX:x y:y];
	[self.undoManager setActionName:@"Change Bit"];

	[ch setBit:value atX:x y:y];

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(code) }];
}

// Engine replaces all characters with a new array.
- (void)replaceBitmapsWithBitmap:(NSMutableArray<AXCharacter *> *)ch description:(NSString *)desc
{
	[[self.undoManager prepareWithInvocationTarget:self] replaceBitmapsWithBitmap:ch description:desc];
	[self.undoManager setActionName:desc];

	self.characters = ch;

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_ALLCHANGED object:self];
}

- (void)trimFontBitmaps
{
	/*
	 *	Build new trimmed bitmaps
	 */

	NSMutableArray<AXCharacter *> *chars = [[NSMutableArray alloc] init];
	for (AXCharacter *ch in self.characters) {
		AXCharacter *trimCh = [ch trim];
		[chars addObject:trimCh];
	}
	[self replaceBitmapsWithBitmap:chars description:@"Trim Bitmaps"];
}

@end
