/*
 *  AppController.m
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-03.
 *  Copyright 2007 namedfork.net. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "AppController.h"
#import <Security/Security.h>
#include <sys/types.h>
#include "bootfile.h"
#include "rle.h"
#include "clut.h"

@implementation AppController

- (void)awakeFromNib {
	#if defined(__ppc__)
	// set file offsets
	bootClutSize = BOOTX_CLUT_SIZE;
	bootIconSize = BOOTX_ICON_SIZE;	
	#elif defined(__i386__)
	// set file offsets
	bootClutSize = BOOTEFI_CLUT_SIZE;
	bootIconSize = BOOTEFI_ICON_SIZE;
	#endif
	currentClut = currentImage = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	bootOffsets = [self getOffsets];
	if ([bootOffsets count] < 2) {
		// offsets not found
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"Quit",nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Report",nil)];
		[alert setMessageText:NSLocalizedString(@"OffsetNotFound",nil)];
		[alert setInformativeText:NSLocalizedString(@"OffsetNotFound2",nil)];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:mainWindow
				modalDelegate:self
				didEndSelector:@selector(alertEnded:returnCode:contextInfo:)
				contextInfo:nil];
	}
	[bootOffsets retain];
	// get current boot image
	[getSystemBootImageButton performClick:self];
}

- (void) alertEnded:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn)
	{	// quit
		
	} else if (returnCode == NSAlertSecondButtonReturn) {
		// report
		NSDictionary* errorInfo;
		NSURL* scriptURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SendBugReport" ofType:@"scpt" inDirectory:@"Scripts"]];
		NSAppleScript* reportScript = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo];
		if (reportScript != nil)
		{
			// set applescript routine
			NSAppleEventDescriptor* param1 = [NSAppleEventDescriptor descriptorWithString:
				[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
			NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
			[params insertDescriptor:param1 atIndex:1];
			NSAppleEventDescriptor* handler = [NSAppleEventDescriptor descriptorWithString:@"sendbugreport"];
			// set event
			ProcessSerialNumber psn = {0, kCurrentProcess};
			NSAppleEventDescriptor* target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
												bytes:&psn
												length:sizeof psn];
			NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:'ascr'
												eventID:'psbr'
												targetDescriptor:target
												returnID:kAutoGenerateReturnID
												transactionID:kAnyTransactionID];
			[event setParamDescriptor:handler forKeyword:'snam'];
			[event setParamDescriptor:params forKeyword:keyDirectObject];
			[reportScript executeAppleEvent:event error:&errorInfo];
			[reportScript release];
		}
		
	}
	[mainWindow close];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

# pragma mark Boot Image management

- (NSImage*)getBootImageFromData: (NSData*)pixelData palette:(NSData*)clutData {
	unsigned char	pixelBytes[BOOTIMAGE_SIZE*BOOTIMAGE_SIZE];
	unsigned char	clutBytes[256*3];
	
	// get pixelBytes
	if ([pixelData length] < sizeof(pixelBytes)) {
		// pixelData is RLE-compressed
		if (RLEGetDecodedSize([pixelData bytes], [pixelData length]) != sizeof(pixelBytes)) {
			// it's still the wrong size
			return nil;
		}
		// decompress pixelData
		RLEDecodeMem(pixelBytes, [pixelData bytes], [pixelData length]);
	}
	else if ([pixelData length] > sizeof(pixelBytes)) {	
		// pixelData is too big, this is bad
		return nil;
	}
	else {	
		// pixelData is the exact size
		memcpy(pixelBytes, [pixelData bytes], [pixelData length]);
	}
	
	// get clutBytes
	if ([clutData length] != sizeof(clutBytes)) {
		// clutBytes is wrong, we don't expect it to be compressed
		return nil;
	}
	else {
		memcpy(clutBytes, [clutData bytes], [clutData length]);
	}
	
	// Create Bitmap
	NSSize				bootImageSize = {BOOTIMAGE_SIZE, BOOTIMAGE_SIZE};
	NSBitmapImageRep	*bitmap;
	unsigned char		*plane;
	int					i;
	
	bitmap = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:	nil
		pixelsWide:					bootImageSize.width
		pixelsHigh:					bootImageSize.height
		bitsPerSample:				8
		samplesPerPixel:			3
		hasAlpha:					NO
		isPlanar:					NO
		colorSpaceName:				NSDeviceRGBColorSpace
		bytesPerRow:				0
		bitsPerPixel:				24
		];
	
	// Fill planes
	plane = [bitmap bitmapData];
	for(i = 0; i < BOOTIMAGE_SIZE*BOOTIMAGE_SIZE; i++) {
		plane[3*i] = clutBytes[(3*pixelBytes[i])];
		plane[3*i+1] = clutBytes[(3*pixelBytes[i])+1];
		plane[3*i+2] = clutBytes[(3*pixelBytes[i])+2];
	}
	
	// Create NSImage
	NSImage	*myImage;
	myImage = [[NSImage alloc] initWithSize:bootImageSize];
	[myImage addRepresentation:bitmap];
	[bitmap release];
	
	return myImage;
}

- (NSImage*)getDefaultBootImage {
	#if defined(__ppc__)
	return [self getBootImageFromFile:@BOOTX_DEFAULT];
	#elif defined(__i386__)
	return [self getBootImageFromFile:@BOOTEFI_DEFAULT];
	#endif
}

- (NSImage*)getSystemBootImage {
	#if defined(__ppc__)
	return [self getBootImageFromFile:@BOOTX_CURRENT];
	#elif defined(__i386__)
	return [self getBootImageFromFile:@BOOTEFI_CURRENT];
	#endif
}

- (NSImage*)getBootImageFromFile: (NSString*)filePath {
	NSFileHandle	*fh;
	NSData			*imageData, *clutData;
	
	fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
	[fh seekToFileOffset:[[bootOffsets objectAtIndex:0] intValue]];
	clutData = [fh readDataOfLength:bootClutSize];
	[fh seekToFileOffset:[[bootOffsets objectAtIndex:1] intValue]];
	imageData = [fh readDataOfLength:bootIconSize];
	[fh closeFile];
	
	if (currentClut) {
		[currentClut release];
		[currentImage release];
	}
	currentClut = clutData;
	currentImage = imageData;
	[currentClut retain];
	[currentImage retain];
	
	return [self getBootImageFromData:imageData palette:clutData];
}

- (NSArray*) getOffsets {
	NSMutableArray	*paletteOffsets, *imageOffsets, *offsets;
	NSData			*bootFile, *bootImage, *bootPalette;
	size_t			i, len;
	#if defined(__ppc__)
	bootFile = [NSData dataWithContentsOfFile: @BOOTX_DEFAULT];
	bootImage = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"bootlogo" ofType:@"of"]];
	#elif defined(__i386__)
	bootFile = [NSData dataWithContentsOfFile: @BOOTEFI_DEFAULT];
	bootImage = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"bootlogo" ofType:@"efi"]];
	#endif
	bootPalette = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"bootlogo" ofType:@"act"]];
	
	// find palette
	len = [bootPalette length];
	paletteOffsets = [NSMutableArray arrayWithCapacity:2];
	for(i = 0; i <= [bootFile length] - len; i++) if (memcmp([bootPalette bytes], [bootFile bytes]+i, len) == 0)
		[paletteOffsets addObject:[NSNumber numberWithUnsignedInt:i]];
	// find images
	len = [bootImage length];
	imageOffsets = [NSMutableArray arrayWithCapacity:2];
	for(i = 0; i <= [bootFile length] - len; i++) if (memcmp([bootImage bytes], [bootFile bytes]+i, len) == 0)
		[imageOffsets addObject:[NSNumber numberWithUnsignedInt:i]];
	
	// set return array
	NSMutableString* str = [NSMutableString stringWithCapacity :32];
	[str appendString:@"Found offsets: "];
	offsets = [NSMutableArray arrayWithCapacity:4];
	for(i = 0; i < [paletteOffsets count]; i++)
	{
		[str appendFormat:@"p:0x%x i:0x%x ", [[paletteOffsets objectAtIndex:i] intValue], [[imageOffsets objectAtIndex:i] intValue]];
		[offsets addObject:[paletteOffsets objectAtIndex:i]];
		[offsets addObject:[imageOffsets objectAtIndex:i]];
	}
	NSLog(str);
	return offsets;
}

- (NSImage*) convertImageForBoot: (NSImage*)theImage isValid:(BOOL*)validRef {
	NSBitmapImageRep	*bitmap;
	NSImage				*bootImage;
	NSData				*imageData, *clutData;
	NSPoint				drawPos;
	unsigned char		pixelBytes[BOOTIMAGE_SIZE*BOOTIMAGE_SIZE];
	unsigned char		clutBytes[256*3];
	int					i,j;
	float				rVal, gVal, bVal, aVal;
	unsigned char		rByte, gByte, bByte;
	
	if (theImage == nil) return nil;
	// draw the image at 128x128
	bootImage = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];
	
	[bootImage lockFocus];
	[[NSColor colorWithDeviceRed:(191.0/255) green:(191.0/255) blue:(191.0/255) alpha:1.0] setFill];
	NSRectFill(NSMakeRect(0,0,128,128));
	drawPos = NSMakePoint(trunc((BOOTIMAGE_SIZE-[theImage size].width)/2), trunc((BOOTIMAGE_SIZE-[theImage size].height)/2));
	[theImage drawAtPoint:drawPos fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[bootImage unlockFocus];
	bitmap = [[NSBitmapImageRep alloc] initWithData:[bootImage TIFFRepresentation]];
	
	// load initial palette
	clutData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"bootlogo" ofType:@"act"]];
	memcpy(clutBytes, [clutData bytes], [clutData length]);
	
	for(i = 0; i < BOOTIMAGE_SIZE; i++) for(j = 0; j < BOOTIMAGE_SIZE; j++) {
		[[bitmap colorAtX:i y:j] getRed:&rVal green:&gVal blue:&bVal alpha:&aVal];
		rByte = (unsigned char)(rVal*255.0);
		gByte = (unsigned char)(gVal*255.0);
		bByte = (unsigned char)(bVal*255.0);
		pixelBytes[i + (j*BOOTIMAGE_SIZE)] = findColorInCLUT(rByte, gByte, bByte, clutBytes);
	}
	[bitmap release];
	[bootImage release];
	
	// get image
	clutData = [[NSData alloc] initWithBytes:clutBytes length:sizeof(clutBytes)];
	imageData = [[NSData alloc] initWithBytes:pixelBytes length:sizeof(pixelBytes)];
	if (currentClut) {
		[currentClut release];
		[currentImage release];
	}
	currentClut = clutData;
	currentImage = imageData;
	[currentClut retain];
	[currentImage retain];
	
	// report validity
	#if defined(__ppc__)
	*validRef = YES;
	#elif defined(__i386__)
	*validRef = (RLEGetEncodedSize([imageData bytes], [imageData length]) <= BOOTEFI_ICON_SIZE);
	#endif
	
	return [self getBootImageFromData:imageData palette:clutData];
}

- (IBAction)saveBootImage:(id)sender {
	NSString *toolPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"InstallBootImage"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:toolPath] == NO) return;
	
	// check validity
	#if defined(__i386__)
	if ([currentImage length] == 128*128 && 
		RLEGetEncodedSize([currentImage bytes], [currentImage length]) > BOOTEFI_ICON_SIZE) {
		NSBeep();NSBeep();NSBeep();
		NSLog(@"[!!!] saveBootImage:Setting invalid boot image aborted");
		return;
	}
	#endif
	
	[self installBootImage:currentImage palette:currentClut withTool:[toolPath UTF8String]];
}

- (IBAction) openWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"WebsiteURL"]]];
}

- (int) installBootImage: (NSData*)imageData palette:(NSData*)clutData withTool:(const char *)toolPath {
	AuthorizationRef		auth;
	AuthorizationFlags		authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
	AuthorizationItem		authItems[] = {kAuthorizationRightExecute, strlen(toolPath), (void*)toolPath, 0};
	AuthorizationRights		authRights = {sizeof(authItems)/sizeof(AuthorizationItem), authItems};
	OSStatus				err;
	char					*toolArgs[2];
	FILE					*toolPipe = NULL;
	NSData					*bootFile;
	NSMutableData			*newBootFile;
	char					strLength[16];
	
	// prepare boot file
	#if defined(__ppc__)
	bootFile = [NSData dataWithContentsOfFile:@BOOTX_DEFAULT];
	#elif defined(__i386__)
	bootFile = [NSData dataWithContentsOfFile:@BOOTEFI_DEFAULT];
	#endif
	newBootFile = [bootFile mutableCopy];
	
	// get final image
	NSMutableData *imageDataFinal;
	#if defined(__ppc__)
	imageDataFinal = [imageData mutableCopy];
	#elif defined(__i386__)
	if ([imageData length] == 128*128) {
		// image is not compressed
		imageDataFinal = [NSMutableData dataWithLength:BOOTEFI_ICON_SIZE];
		RLEEncodeMem([imageDataFinal mutableBytes], [imageData bytes], [imageData length]);
	}
	else if ([imageData length] <= BOOTEFI_ICON_SIZE) {
		// image is compressed
		imageDataFinal = [imageData mutableCopy];
	} else {
		// image is too big
		NSBeep();NSBeep();NSBeep();
		NSLog(@"[!!!] installBootImage:Setting invalid boot image aborted");
		goto error;
	}
	#endif
	
	// replace image & palette in data
	[newBootFile replaceBytesInRange:NSMakeRange([[bootOffsets objectAtIndex:0] intValue], bootClutSize) withBytes:[clutData bytes]];
	[newBootFile replaceBytesInRange:NSMakeRange([[bootOffsets objectAtIndex:1] intValue], bootIconSize) withBytes:[imageDataFinal bytes]];
	if ([bootOffsets count] > 2) {
		[newBootFile replaceBytesInRange:NSMakeRange([[bootOffsets objectAtIndex:2] intValue], bootClutSize) withBytes:[clutData bytes]];
		[newBootFile replaceBytesInRange:NSMakeRange([[bootOffsets objectAtIndex:3] intValue], bootIconSize) withBytes:[imageDataFinal bytes]];
	}
	
	// prepare arguments
	#if defined(__ppc__)
	toolArgs[0] = BOOTX_CURRENT;
	#elif defined(__i386__)
	toolArgs[0] = BOOTEFI_CURRENT;
	#endif
	sprintf(strLength, "%d", [newBootFile length]);
	toolArgs[1] = strLength;
	toolArgs[2] = NULL;
	
	// run install tool
	err = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, authFlags, &auth);
	if (err != errAuthorizationSuccess) goto error;
	err = AuthorizationExecuteWithPrivileges(auth, toolPath, kAuthorizationFlagDefaults, toolArgs, &toolPipe);
	if (err != errAuthorizationSuccess) goto error;
	
	// write file
	fwrite([newBootFile bytes], [newBootFile length], 1, toolPipe);
	
	// close
	fclose(toolPipe);
	return 1;
	
	error:
		NSLog(@"InstallBootImage error");
		return 0;
}

@end
