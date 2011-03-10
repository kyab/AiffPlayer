//
//  SpectrumView.m
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView.h"
#include <vector>
#include <complex>
#include <iostream>

#include "util.h"

@implementation SpectrumView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_aiff = nil;
    }
    return self;
}
-(void)setAiff:(Aiff *)aiff{
	_aiff = aiff;
	[self setNeedsDisplay:YES];
	
	//observe on _aiff to monitor frame change
	[_aiff observeFrameChange:self forSelector:@selector(updateCurrentFrame:)];
}

-(void)updateCurrentFrame:(id)sender{
	NSLog(@"spectrum view: notified aiff play position change") ;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {

    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	if (_aiff == nil) return;
	using namespace std;
	
	vector<complex <double> > spectrum  = [_aiff getFastFFTBuffer];
	
	NSRect bounds = [self bounds];
	
	Timer timer; timer.start();
	
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];
	[path moveToPoint:NSMakePoint(0,0)];
	for (int i = 0 ; i < spectrum.size() ; i++){
		//std::cout << spectrum[i] << std::endl;
		float amp = abs(spectrum[i])/spectrum.size();
		float x = bounds.size.width*2 / spectrum.size() * i;
		
		float db = 20 * std::log10(amp);
		float y = (db+96) * (bounds.size.height)/96.0f ;
		[path lineToPoint:NSMakePoint(x,y)];
	}
	[[NSColor yellowColor] set];
	[path stroke];
	timer.stop();
	//NSLog(@"drwaing takes %f[msec]", timer.result()*1000);
	
}

@end
