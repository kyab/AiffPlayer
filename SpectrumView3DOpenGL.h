//
//  SpectrumView3DOpenGL.h
//  AiffPlayer
//
//  Created by koji on 11/05/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include <vector>
#include <deque>
#include <complex>

#import "Aiff.h"
typedef std::complex<double> Dcomplex;
typedef std::vector<Dcomplex> Spectrum;

@interface SpectrumView3DOpenGL : NSOpenGLView {
	bool _mouseDragging;
	NSPoint _prevDragPoint;
	
	id _aiff;
	std::deque<Spectrum> _spectrums;
	
	Boolean _enabled;
	Boolean _log;
	
}
-(void)rotate:(float)angle forX:(float)x forY:(float)y forZ:(float)z;
-(void)setAiff:(id)aiff;

@property(assign)Boolean enabled;
@property(assign)Boolean log;

@end