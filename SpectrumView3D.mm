//
//  SpectrumView.m
//  AiffPlayer
//
//  Created by koji on 11/01/31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView3D.h"
#include <vector>
#include <complex>
#include <iostream>
#include <math.h>

#include "fft.h"
#include "util.h"

#include "math.h"
#import "3d.h"


static const int FFT_SIZE = 256 * 8;
static const int SPECTRUM3D_COUNT = 40;

//world corrdinate is basically [-100 100] for x,y, and z

@implementation SpectrumView3D

@synthesize rotateX = _rotateX,rotateY = _rotateY, rotateZ = _rotateZ;
@synthesize enabled = _enabled;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_aiff = nil;
		_rotateX = 30;// 30;
		_rotateY = -40;//-40;
		_rotateZ = 0;
		_enabled = YES;
		_log = YES;
								 
    }
    return self;
}
- (void)setAiff:(Aiff *)aiff{
	_aiff = aiff;
	[_aiff addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:NULL];
	[self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	
	NSLog(@"Spectrum3D observe change of selection : %@", keyPath);
	if ([keyPath isEqual:@"selection"]){

		float start = [[_aiff selection] end];
		float end = [[_aiff selection] end];
		NSLog(@"change detected. start = %f, end = %f", start, end);
		[self setNeedsDisplay:YES];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

//camera -> screen
- (NSPoint) screenFromCamera:(NSPoint)point{
	NSSize camera_size;
	camera_size.width = 300;
	camera_size.height = 300;
	
	//shift
	float x = point.x + camera_size.width/2.0;
	float y = point.y + camera_size.height/2.0;
	
	NSRect bounds = [self bounds];
	
	//scale
	x = x * bounds.size.width/camera_size.width;
	y = y * bounds.size.height/camera_size.height;
	return NSMakePoint(x,y);
}

//world -> camera -> screen
- (NSPoint)pointXYFrom3DPoint:(Point3D)point3d{
	
	//this works well
	//point3d.rotateY(rad(-40)).rotateX(rad(_rotateX/*30*/));
	point3d.rotateX(rad(_rotateX)).rotateY(rad(_rotateY)).rotateZ(rad(_rotateZ));
	
	//NSPoint pointXY = point3d.toCamera(600,1000);		//DO NOT CHANGE THIS!
	NSPoint pointXY = point3d.toCamera_noPerspective();
	pointXY = [self screenFromCamera:pointXY];
	
	//tweak shift
	pointXY.x -= [self bounds].size.width/2.2;
	pointXY.y -= 20;
	return pointXY;
}

-(void)drawSpectrum:(const Spectrum &)spectrum index:(int)index{
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];

	int length = spectrum.size()/2;
	for (int i = 0 ; i < length ; i++){
		float amp = abs(spectrum[i])/spectrum.size();
		float db = 20 * std::log10(amp);
		if (db < -95){
			//to draw the base line
			db = -96;
		}
		
		float y = db + 96 + 0/*visible factor*/;
		float z = i;
		
		//scale to world coordinate:[-100,100]
		if (_log){
			float freq = (float)i * 44100/spectrum.size();
			float logFreq = std::log10(freq);
			if (logFreq < 1.0f) logFreq = 0.0f;
			z = 100.0f/(std::log10(22050) - std::log10(10)) * logFreq;
			z *= 2;
		}else{
			z = z * 100/length*2/*scale factor*/;
		}
		
		y = y * 200/96 * 0.2/*scale factor*/;
		
		float x = float(index) * 200/(_spectrums.size()) * 1.3/*scale factor*/;

		Point3D point3d(x,y,z);
		
		//now point3d is 3D point in world coordinate.
		
		NSPoint point = [self pointXYFrom3DPoint:point3d];		
		if (i == 0){
			[path moveToPoint:point];
		}else{
			[path lineToPoint:point];
		}
	}
	float red = 1.0f * index / _spectrums.size();
	NSColor *color = [NSColor colorWithCalibratedRed:red/*0.5*/
											green:0.1 
											blue:0.1
											  alpha:0.9];
	[color set];
	//[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	//[path stroke];
	
	//TODO: add lines to complete path
	//last point to -96 decibel
	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.2;
		z = float(length)*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMaxFreq = [self pointXYFrom3DPoint:point3d];
		[path lineToPoint:zeroAtMaxFreq];
	}
	
	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.2;
		z = 0.0f*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMinFreq = [self pointXYFrom3DPoint:point3d];
		[path lineToPoint:zeroAtMinFreq];
	}
	
	[path closePath];
	[path fill];
	[[NSColor yellowColor] set];
	[path stroke];
	
}


- (void)drawLineFrom:(Point3D)from to:(Point3D)to{
	NSPoint from_xy = [self pointXYFrom3DPoint:from];
	NSPoint to_xy = [self pointXYFrom3DPoint:to];

	[NSBezierPath strokeLineFromPoint:from_xy toPoint:to_xy];
}


- (void)drawText:(NSString *)text atPoint:(Point3D)point3d{
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSFont fontWithName:@"Monaco" size:14.0f]
				   forKey:NSFontAttributeName];
	[attributes setObject:[NSColor whiteColor]
				   forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *at_text = [[NSAttributedString alloc] initWithString: text
	                                                        attributes: attributes];
    
    NSPoint point_xy = [self pointXYFrom3DPoint:point3d];
    [at_text drawAtPoint:point_xy];
	
}


- (void)drawRect:(NSRect)dirtyRect {

    [[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	if (_aiff == nil) return;
	
	using namespace std;
	
	//draw spectrum(s).
	
	if (_enabled){
		_spectrums.clear();
		for(int i = 0; i < SPECTRUM3D_COUNT; i++){
			_spectrums.push_back(Spectrum(FFT_SIZE,0.0));
		}
		
		//0.0 to 1.0
		RangeX *selection = [_aiff selection];
		float start = selection.start / 100.0f;
		float width = selection.end / 100.0f - start;
		float rate = width / SPECTRUM3D_COUNT;
		for (int i = 0; i < SPECTRUM3D_COUNT; i++){
			UInt32 frame = (UInt32) ([_aiff totalFrameCount] * (start + i*rate));
			[_aiff fastFFTForFrame:frame toBuffer:_spectrums[i] size:FFT_SIZE];
		}
		
		
		for(int index = 0; index < _spectrums.size(); index++){
			[self drawSpectrum:_spectrums[index] index:index];
		}
	}
		
	//draw axis
	
	[[NSColor yellowColor] set];
	[self drawLineFrom:Point3D(0,-100,0) to:Point3D(0,100,0)];
	[self drawLineFrom:Point3D(-100,0,0) to:Point3D(100,0,0)];
	[self drawLineFrom:Point3D(0,0,-100) to:Point3D(0,0,100)];
	
	//draw axis label
	[self drawText:@"time(x)" atPoint:Point3D(100,0,0)];
	[self drawText:@"dB(y)" atPoint:Point3D(0,100,0)];
	[self drawText:@"freq(z)" atPoint:Point3D(0,0,100)];
	
}

- (void)setLog:(Boolean)log{
	_log = log;
	[self setNeedsDisplay:YES];
}

-(Boolean)log{
	return _log;
}


@end
