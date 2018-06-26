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

	NSDictionary *d = @{ @"characters": ach,
						 @"first": @(self.first),
						 @"last": @(self.last),
						 @"yHeight": @(self.yHeight) };
	return [NSJSONSerialization dataWithJSONObject:d  options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data  options:0 error:nil];

	self.first = [(NSNumber *)d[@"first"] integerValue];
	self.last = [(NSNumber *)d[@"last"] integerValue];
	self.yHeight = [(NSNumber *)d[@"yHeight"] integerValue];
	NSArray<NSDictionary *> *a = (NSArray<NSDictionary *> *)d[@"characters"];

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
 *	Character contents
 */

- (AXCharacter *)characterAtIndex:(uint8_t)index
{
	if (index < self.first) return nil;
	if (index > self.last) return nil;
	return self.characters[index - self.first];
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
		for (uint8_t x = code; x <= ecode; ++x) {
			AXCharacter *ch = [self characterAtIndex:x];
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
	AXCharacter *ch = [self characterAtIndex:code];
	if (ch == nil) return;

	[[self.undoManager prepareWithInvocationTarget:self] setCharacter:code bitmapWidth:ch.width height:ch.height xAdvance:ch.xAdvance xOffset:ch.xOffset yOffset:ch.yOffset];
	[self.undoManager setActionName:@"Update Character Parameters"];

	[ch setWidth:width height:height];
	[ch setXAdvance:adv xOffset:xoff yOffset:yoff];

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(code) }];
}

- (void)replaceCharacter:(AXCharacter *)ch atIndex:(uint8_t)index actionName:(NSString *)actionName
{
	AXCharacter *oldChar = [self characterAtIndex:index];
	[[self.undoManager prepareWithInvocationTarget:self] replaceCharacter:oldChar atIndex:index actionName:actionName];
	[self.undoManager setActionName:actionName];
	self.characters[index - self.first] = ch;

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(index) }];
}

- (void)clearCharacterAtIndex:(uint8_t)code
{
	AXCharacter *ch = [self characterAtIndex:code];
	if (ch == nil) return;

	AXCharacter *clearChar = [[AXCharacter alloc] initWithCharacter:ch];
	[clearChar clearBits];
	[self replaceCharacter:clearChar atIndex:code actionName:@"Clear Character"];
}

- (void)setBit:(uint8_t)code withValue:(BOOL)value atX:(uint8_t)x y:(uint8_t)y
{
	AXCharacter *ch = [self characterAtIndex:code];
	if (ch == nil) return;

	[[self.undoManager prepareWithInvocationTarget:self] setBit:code withValue:[ch getBitAtX:x y:y] atX:x y:y];
	[self.undoManager setActionName:@"Change Bit"];

	[ch setBit:value atX:x y:y];

	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CHARACTERCHANGED object:self userInfo:@{ @"char": @(code) }];
}


@end
