/*
 *  NFErrorStripe.m
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-11.
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

#import "NFErrorStripe.h"


@implementation NFErrorStripe

- (void)awakeFromNib
{
    duration = 0.5;
	message = nil;
	animStatus = animStoppedHidden;
	endStatusShow = NO;
}

- (void)dealloc {
	if (message) [message release];
	[super dealloc];
}

- (void)animationDidEnd:(NSAnimation *)anim {
	// check if we're at our end status
	if (animStatus == animShowing) {
		// was showing
		animStatus = animStoppedShown;
		[anim release];
		if (!endStatusShow) [self hide];
	}
	else if (animStatus == animHiding) {
		// was hiding
		animStatus = animStoppedHidden;
		[anim release];
		if (endStatusShow) [self show];
	}
}

- (void)show {
	NSViewAnimation		*anim;
	NSMutableDictionary	*dict;
	NSRect				frame;
	NSWindow			*win = [[self superview] window];
	endStatusShow = YES;
	if (animStatus != animStoppedHidden) return;
	animStatus = animShowing;
	dict = [NSMutableDictionary dictionaryWithCapacity:3];
	frame = [win frame];
	
	[self setHidden:NO];
	[dict setObject:win forKey:NSViewAnimationTargetKey];
	[dict setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
	frame.size.height += 20;
	frame.origin.y -= 20;
	[dict setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
	
	anim = [[NSViewAnimation alloc] initWithViewAnimations:
		[NSArray arrayWithObjects: dict, nil]];
	[anim setDuration:duration];
	[anim setDelegate:self];
	[anim setAnimationCurve:NSAnimationEaseIn];
	[anim startAnimation];
}

- (void)showWithMessage: (NSString *)errorText {
	if(message) [message release];
	message = errorText;
	[message retain];
	[self show];
}

- (void)showWithLocalizedMessage: (NSString *)errorText {
	if(message) [message release];
	message = NSLocalizedString(errorText, nil);
	[message retain];
	[self show];
}

- (void)hide {
	NSViewAnimation		*anim;
	NSMutableDictionary	*dict;
	NSRect				frame;
	NSWindow			*win = [[self superview] window];
	endStatusShow = NO;
	if (animStatus != animStoppedShown) return;
	animStatus = animHiding;
	dict = [NSMutableDictionary dictionaryWithCapacity:3];
	frame = [win frame];	
	[dict setObject:win forKey:NSViewAnimationTargetKey];
	[dict setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
	frame.size.height -= 20;
	frame.origin.y += 20;
	[dict setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
	
	anim = [[NSViewAnimation alloc] initWithViewAnimations:
		[NSArray arrayWithObjects: dict, nil]];
	[anim setDuration:duration];
	[anim setDelegate:self];
	[anim setAnimationCurve:NSAnimationEaseIn];
	[anim startAnimation];
}

- (void)drawRect:(NSRect)aRect {
	NSString			*path;
	NSImage				*img;
	NSMutableDictionary	*attrs;
	
	// background
	path = [[NSBundle mainBundle] pathForImageResource:@"ErrorStripeBG"];
	img = [[NSImage alloc] initWithContentsOfFile:path];
	[img drawInRect:NSMakeRect(0, 0, aRect.size.width, 20) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[img release];
	
	// icon
	path = [[NSBundle mainBundle] pathForImageResource:@"TinyAlert"];
	img = [[NSImage alloc] initWithContentsOfFile:path];
	[img drawAtPoint:NSMakePoint(3, 1) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[img release];

	// message
	attrs = [[NSMutableDictionary alloc] initWithCapacity:3];
	[message drawAtPoint:NSMakePoint(24, 3) withAttributes:attrs];
	
	// bottom line
	/*[[NSColor windowFrameColor] setFill];
	NSRectFill(NSMakeRect(0, 0, aRect.size.width, 1));*/
}
@end
