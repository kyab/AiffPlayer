//
//  AUProcessor.h
//  AiffPlayer
//
//  Created by koji on 10/12/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Aiff.h"

#include <vector>

//The Application Main Model

@interface AUProcessor : NSObject {
	Aiff *m_aiff;
}

- (void) listOutputDevices;
- (void) initCoreAudio;
- (void) start;
- (void) stop;

- (void) setFormat;
- (void) setCallback;



- (Boolean)loadAiff:(NSString *)fileName;
- (Aiff *)aiff;


- (OSStatus) renderCallback:(AudioUnitRenderActionFlags *)ioActionFlags :(const AudioTimeStamp *) inTimeStamp:
(UInt32) inBusNumber: (UInt32) inNumberFrames :(AudioBufferList *)ioData;

@end
