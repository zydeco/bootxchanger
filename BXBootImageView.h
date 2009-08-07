/*
 *  BXBootImageView.h
 *  BootXChanger
 *
 *  Created by Zydeco on 2007-11-03.
 *  Copyright 2007-2009 namedfork.net. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "NFErrorStripe.h"

@interface BXBootImageView : NSImageView {
    IBOutlet AppController *mainController;
	IBOutlet NFErrorStripe *errView;
	IBOutlet NSButton *applyButton;
}
- (IBAction)loadDefaultBootImage:(id)sender;
- (IBAction)loadSystemBootImage:(id)sender;
@end
