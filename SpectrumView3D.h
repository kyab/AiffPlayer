//
//  SpectrumView3D.h
//  Oscilloscope
//
//  Created by koji on 11/02/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <vector>
#include <deque>
#include <complex>

#import "Aiff.h"
typedef std::complex<double> Dcomplex;
typedef std::vector<Dcomplex>  Spectrum;

@interface SpectrumView3D : NSView {
	id _aiff;	//or sound buffer
	std::deque<Spectrum> _spectrums;
	
	float _rotateX;
	float _rotateY;
	float _rotateZ;
	
	Boolean _enabled;
	Boolean _log;
	
}

- (void)setAiff:(Aiff *)aiff;

@property(assign)float rotateX;
@property(assign)float rotateY;
@property(assign)float rotateZ;
@property(assign)Boolean enabled;
@property(assign)Boolean log;

@end

