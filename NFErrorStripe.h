//
//  NFErrorStripe.h
//  BootXChanger
//
//  Created by Zydeco on 2007-11-11.
//  Copyright 2007 namedfork.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef enum {animStoppedHidden, animStoppedShown, animShowing, animHiding} animStatusType;

@interface NFErrorStripe : NSView {
	float	duration;
@private
	NSString	*message;
	bool		endStatusShow;
	animStatusType animStatus;
}

- (void)showWithMessage: (NSString *)errorText;
- (void)showWithLocalizedMessage: (NSString *)errorText;
- (void)hide;
- (void)show;
@end
