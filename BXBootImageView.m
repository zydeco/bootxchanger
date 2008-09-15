/*
 *  BXBootImageView.m
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

#import "BXBootImageView.h"

@implementation BXBootImageView
- (IBAction)loadDefaultBootImage:(id)sender {
	NSImage *bootImage = [mainController getDefaultBootImage];
    [super setImage:bootImage];
	[bootImage release];
	[applyButton setEnabled:YES];
	[errView hide];
}

- (IBAction)loadSystemBootImage:(id)sender {
	NSImage *bootImage = [mainController getSystemBootImage];
    [super setImage:bootImage];
	[bootImage release];
	[applyButton setEnabled:YES];
	[errView hide];
}

- (void)setImage:(NSImage *)newImage {
	NSImage *bootImage;
	BOOL	valid;
	
	if (newImage == nil) {
		[self loadSystemBootImage:self];
		return;
	}
	
	bootImage = [mainController convertImageForBoot:newImage isValid:&valid];
	[applyButton setEnabled:valid];
	if (!valid) {
		[errView showWithLocalizedMessage:@"ImageUnusable"];
	}
	else {
		[errView hide];
	}
	[super setImage:bootImage];
	[bootImage release];
}

@end