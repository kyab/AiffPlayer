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

#import "RangeX.h"

@interface Aiff : NSObject {

	//unsigned long _sampleCount;
	NSString *_fileName;

	std::vector<float> _left;
    std::vector<float> _right;

    RangeX *_selection;
	
	unsigned long _currentFrame;
	unsigned long _scribStartFrame;
	Boolean _scrib;
	id _observer;
	SEL _notify_selector;
	
}

- (void) loadFile: (NSString *)fileName;
- (NSString *)fileName;

//the buffer(float left)
-(std::vector<float> *) left;
-(std::vector<float> *) right;

-(float)foo;
-(void)setFoo:(float)val;


//scrib playback support
- (Boolean)scrib;
- (void) setScrib: (Boolean)b;

-(std::vector<std::complex<double> >)getDFTBuffer;
-(std::vector<std::complex<double> >)getSlowFFTBuffer;
-(std::vector<std::complex<double> >)getFastFFTBuffer;

-(void)fastFFTForFrame:(UInt32)frame toBuffer:(std::vector<std::complex<double> > &)buffer size:(int)size;

//frame (position in sample) handling
- (unsigned long) currentFrame;
- (unsigned long) totalFrameCount;
- (void) setCurrentFrameInRate: (float) rate scribStart:(Boolean)scribStart ;

//observer
- (void)observeFrameChange:(id) observer forSelector:(SEL) sel;

//
- (Boolean) renderToBuffer:(UInt32)sampleCount left:(void *)pLeft right:(void *)pRight;  


- (RangeX *)selection;
@end	
