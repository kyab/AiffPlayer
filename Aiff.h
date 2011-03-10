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

#include <sys/time.h>
#include <sys/times.h>


@interface Aiff : NSObject {
	//NSMutableArray *_buffer_l;
	unsigned long _sampleCount;
	NSString *_fileName;
	std::vector<signed short> _stlbuffer;
	std::vector<signed short> _stlbuffer_lowpassed;
	
	std::vector<float> _left;
	Boolean _useLowPass;
	unsigned long _currentFrame;
	unsigned long _scribStartFrame;
	Boolean _scrib;
	id _observer;	//TODO: make observer to list
	SEL _notify_selector;
	
	
	//ぐちゃぐちゃになってきたｗ
	
	
	//DFT buffer
	std::vector<std::complex<double> >_samples;
	std::vector<std::complex<double> >_result;

}

- (void) loadFile: (NSString *)fileName;
- (NSString *)fileName;

//- (NSMutableArray *)buffer;

//handling lowpass filter
- (void)lowpass;
- (void)setUseLowpass: (Boolean)useLowpass;

//the buffer(whole)
- (std::vector<signed short> *)stlbuffer;


//the buffer(float left)
-(std::vector<float> *) left;


//scrib playback support
- (Boolean)scrib;
- (void) setScrib: (Boolean)b;

-(std::vector<std::complex<double> >)getDFTBuffer;
-(std::vector<std::complex<double> >)getSlowFFTBuffer;
-(std::vector<std::complex<double> >)getFastFFTBuffer;
//-(std::vector<complex>)getFFTBuffer;

//frame (position in sample) handling
- (unsigned long) currentFrame;
- (unsigned long) totalFrameCount;
- (void) setCurrentFrameInRate: (float) rate scribStart:(Boolean)scribStart ;


//observer
- (void)observeFrameChange:(id) observer forSelector:(SEL) sel;

//
- (Boolean) renderToBuffer:(UInt32)channels sampleCount:(UInt32)sampleCount data:(void *)data;  

@end	
