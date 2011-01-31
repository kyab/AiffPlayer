//
//  Aiff.h
//  AiffViewer
//
//  Created by koji on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <vector>
#include <complex>

@interface Aiff : NSObject {
	//NSMutableArray *_buffer_l;
	unsigned long _sampleCount;
	NSString *_fileName;
	std::vector<signed short> _stlbuffer;
	std::vector<signed short> _stlbuffer_lowpassed;
	Boolean _useLowPass;
	unsigned long _currentFrame;
	unsigned long _scribStartFrame;
	Boolean _scrib;
}

- (void) loadFile: (NSString *)fileName;
- (NSString *)fileName;

//- (NSMutableArray *)buffer;

//handling lowpass filter
- (void)lowpass;
- (void)setUseLowpass: (Boolean)useLowpass;

//the buffer(whole)
- (std::vector<signed short> *)stlbuffer;


//scrib playback support
- (Boolean)scrib;
- (void) setScrib: (Boolean)b;

//
//-(std::vector<complex>)getDFTBuffer;
//-(std::vector<complex>)getFFTBuffer;

//frame (position in sample) handling
- (unsigned long) currentFrame;
- (unsigned long) totalFrameCount;
- (void) setCurrentFrameInRate: (float) rate scribStart:(Boolean)scribStart ;


//
- (Boolean) renderToBuffer:(UInt32)channels sampleCount:(UInt32)sampleCount data:(void *)data;  

@end	
