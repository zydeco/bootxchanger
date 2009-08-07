//
//  AppController.h
//  BootXChanger
//
//  Created by Zydeco on 2007-11-03.
//  Copyright 2007-2009 namedfork.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define BOOTIMAGE_SIZE 128

@interface AppController : NSObjectController {
	IBOutlet NSWindow		*mainWindow;
	IBOutlet NSWindow		*prefsWindow;
	IBOutlet NSButton		*getSystemBootImageButton;
	// current image and palette in system format (i.e. compressed on intel)
	NSData					*currentClut, *currentImage;
	int						bootIconSize, bootClutSize;
	NSArray*				bootOffsets;
}
- (NSImage*) getBootImageFromData: (NSData*)pixelData palette:(NSData*)clutData;
- (NSImage*) getBootImageFromFile: (NSString*)filePath;
- (NSImage*) getDefaultBootImage;
- (NSImage*) getSystemBootImage;
- (NSArray*) getOffsets;
- (NSImage*) convertImageForBoot: (NSImage*)theImage isValid:(BOOL*)validRef;
- (IBAction) saveBootImage:(id)sender;
- (IBAction) openWebsite:(id)sender;
- (int) installBootImage: (NSData*)imageData palette:(NSData*)clutData withTool:(const char *)toolPath;
@end
