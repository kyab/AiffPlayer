//
//  SpectrumView.h
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Aiff.h"

@interface SpectrumView : NSView {
	Aiff *_aiff;	//or sound buffer
	
}

-(void)setAiff:(Aiff *)aiff;

@end
