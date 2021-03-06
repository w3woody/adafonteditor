//
//  AXFontExport.m
//  AdaFontEditor
//
//  Created by William Woody on 6/26/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontExport.h"
#import "AXDocument.h"

@interface AXFontExport ()
{
	NSURL *exportURL;
	AXDocument *doc;
	NSString *fontName;
}
@end

@implementation AXFontExport

- (instancetype)initWithDocument:(AXDocument *)d url:(NSURL *)url
{
	if (nil != (self = [super init])) {
		char buffer[256];
		int fontRef = 0;

		doc = d;
		exportURL = url;

		/*
		 *	Derive font name
		 */

		NSString *fileName = [url lastPathComponent];
		NSInteger i,len = fileName.length;
		for (i = 0; i < len; ++i) {
			unichar ch = [fileName characterAtIndex:i];
			if (ch == '.') break;

			if (!isalnum(ch) && (ch != '_')) continue;
			buffer[fontRef++] = (char)ch;
			if (fontRef >= 255) break;
		}
		if (fontRef == 0) {
			strcpy(buffer,"font");
		} else {
			buffer[fontRef] = 0;
		}
		fontName = [NSString stringWithUTF8String:buffer];
	}
	return self;
}

- (void)dealloc
{
}

- (void)exportHeader:(NSURL *)url
{
	NSString *fileName = [url lastPathComponent];
	FILE *file = fopen([url fileSystemRepresentation],"w");
	if (file == NULL) return;

	fprintf(file,"/*  %s\n",fileName.UTF8String);
	fprintf(file," *\n");
	fprintf(file," *      %s automatically generated by AdaFontEditor\n",fontName.UTF8String);
	fprintf(file," */\n");
	fprintf(file,"\n");
	fprintf(file,"#include <Adafruit_GFX.h>\n");
	fprintf(file,"\n\n");
	fprintf(file,"extern const GFXfont %s PROGMEM;\n\n",fontName.UTF8String);

	fclose(file);
}

- (void)exportSource:(NSURL *)url headerName:(NSString *)header
{
	NSString *fileName = [url lastPathComponent];
	FILE *file = fopen([url fileSystemRepresentation],"w");
	if (file == NULL) return;

	/*
	 *	Print a standard header.
	 */

	fprintf(file,"/*  %s\n",fileName.UTF8String);
	fprintf(file," *\n");
	fprintf(file," *      %s automatically generated by AdaFontEditor\n",fontName.UTF8String);
	fprintf(file," */\n");
	fprintf(file,"\n");
	fprintf(file,"#include \"%s\"\n",header.UTF8String);
	fprintf(file,"\n\n");

	/*
	 *	Construct the bitmap data
	 */

	uint8_t pos = 0;
	BOOL first = YES;
	fprintf(file, "const uint8_t %s_bitmap[] PROGMEM = {\n",fontName.UTF8String);

	for (uint16_t ch = doc.first; ch <= doc.last; ++ch) {
		AXCharacter *c = [doc characterAtCode:ch];
		const uint8_t *data = [c rawBitmap];
		uint16_t len = [c rawBitmapSize];
		for (uint16_t i = 0; i < len; ++i) {
			uint8_t byte = *data++;

			// hack to flip bits in byte
			byte = ((byte & 0x55) << 1) | ((byte & 0xAA) >> 1);
			byte = ((byte & 0x33) << 2) | ((byte & 0xCC) >> 2);
			byte = ((byte & 0x0F) << 4) | ((byte & 0xF0) >> 4);

			if (first) {
				fprintf(file,"    ");
				first = NO;
			} else {
				if (pos > 7) {
					pos = 0;
					fprintf(file,",\n    ");
				} else {
					fprintf(file,", ");
				}
			}

			fprintf(file,"0x%02X",byte);
			++pos;
		}
	}

	fprintf(file, "\n};\n\n");

	/*
	 *	Now construct the internal structures.
	 */

	fprintf(file,"const GFXglyph %s_glyphs[] PROGMEM = {\n",fontName.UTF8String);

	uint16_t offset = 0;
	for (uint16_t ch = doc.first; ch <= doc.last; ++ch) {
		AXCharacter *c = [doc characterAtCode:ch];
		fprintf(file,"    { %5d, %3d, %3d, %3d, %3d, %3d }",offset,c.width,c.height,c.xAdvance,-c.xOffset,-c.yOffset);
		if (ch < doc.last) {
			fprintf(file,",");
		} else {
			fprintf(file," ");
		}

		if ((ch < 32) || (ch >= 127)) {
			fprintf(file,"  // $%02X\n",ch);
		} else if (ch == 32) {
			fprintf(file,"  // sp\n");
		} else {
			fprintf(file,"  // '%c'\n",(char)ch);
		}

		offset += c.rawBitmapSize;
	}

	fprintf(file,"};\n\n");

	/*
	 *	Print the font record
	 */

	fprintf(file,"const GFXfont %s PROGMEM = {\n",fontName.UTF8String);
	fprintf(file,"    %s_bitmap,\n",fontName.UTF8String);
	fprintf(file,"    %s_glyphs,\n",fontName.UTF8String);
	fprintf(file,"    %d,\n",doc.first);
	fprintf(file,"    %d,\n",doc.last);
	fprintf(file,"    %d\n",doc.yHeight);
	fprintf(file,"};\n");

	fclose(file);
}

- (void)export
{
	/*
	 *	Create the directory we write our stuff into
	 */

	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoryAtURL:exportURL withIntermediateDirectories:YES attributes:nil error:nil];

	/*
	 *	Now write the contents
	 */

	NSString *filename = [[exportURL lastPathComponent] stringByDeletingPathExtension];
	NSString *header = [filename stringByAppendingPathExtension:@"h"];
	NSURL *url = [exportURL URLByAppendingPathComponent:header];
	[self exportHeader:url];

	NSString *tmp = [filename stringByAppendingPathExtension:@"cpp"];
	url = [exportURL URLByAppendingPathComponent:tmp];
	[self exportSource:url headerName:header];
}

@end
