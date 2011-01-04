//
//  AUProcessor.h
//  AiffPlayer
//
//  Created by koji on 10/12/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Aiff.h"

@interface AUProcessor : NSObject {
	Aiff *m_aiff;
}

- (void) listOutputDevices;
- (void) initCoreAudio;
- (void) start;
- (void) stop;

- (void) setFormat;
- (void) setCallback;

- (void)setFreq:(int)freq;

- (Boolean)loadAiff:(NSString *)fileName;

@end
