//
//  SpectrumView3DOpenGL.h
//  AiffPlayer
//
//  Created by koji on 11/05/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "trackball.h"

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
	Boolean _smooth;
	
	Boolean _rotateByTrackball;	//
	GLfloat _worldRotation[4];
	GLfloat _trackballRotation[4];
	
}
-(void)rotate:(float)angle forX:(float)x forY:(float)y forZ:(float)z;
-(void)setAiff:(id)aiff;


@property(assign)Boolean enabled;
@property(assign)Boolean log;
@property(assign)Boolean rotateByTrackball;
@property(assign)Boolean smooth;

@end

@interface SpectrumView3DOpenGL (privates)
-(void)compileSpectrumsToDisplayList;
-(void)resetWorldRotaion;
@end