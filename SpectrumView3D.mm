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

static double linearInterporation(double x0, double y0, double x1, double y1, double x){
	double rate = (x - x0) / (x1 - x0);
	double y = (1.0 - rate)*y0 + rate*y1;
	return y;
}


static const int FFT_SIZE = 1024 * 16;
static const int SPECTRUM3D_COUNT = 100;

//world corrdinate is basically [-100 100] for x,y, and z

@implementation SpectrumView3D

@synthesize rotateX = _rotateX,rotateY = _rotateY, rotateZ = _rotateZ;
@synthesize enabled = _enabled;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_aiff = nil;
		_rotateX = 20;// 30;
		_rotateY = -40;//-40;
		_rotateZ = 0;
		_enabled = NO;
		_log = YES;
								 
    }
    return self;
}

- (void)awakeFromNib{
	NSLog(@"SpectrumView3D, awaked from nib");
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
	camera_size.height = 200;
	
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
- (NSPoint)pointXYFromPoint3D:(Point3D)point3d{
	
	//this works well
	//point3d.rotateY(rad(-40)).rotateX(rad(_rotateX/*30*/));
	point3d.rotateX(rad(_rotateX)).rotateY(rad(_rotateY)).rotateZ(rad(_rotateZ));
	
	//NSPoint pointXY = point3d.toCamera(600,1000);		//DO NOT CHANGE THIS!
	NSPoint pointXY = point3d.toCamera_noPerspective();
	pointXY = [self screenFromCamera:pointXY];
	
	//tweak...
	pointXY.x -= [self bounds].size.width/2.2;
	pointXY.x -= 50;
	pointXY.y -= 120;
	return pointXY;
}

-(void)drawSpectrum:(const Spectrum &)spectrum index:(int)index{
	NSBezierPath *path = [[NSBezierPath bezierPath] retain];

	int length = spectrum.size()/2;
	for (int i = 0 ; i < length ; i++){
		float amp = abs(spectrum[i])/spectrum.size();
		float db = 20 * std::log10(amp);
		if (db < -95){
			//draw the base line
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
			z = z * 100/length * 2/*scale factor*/;
		}
		
		y = y * 200/96 * 0.2 /*scale factor*/;
		float x = float(index) * 200/(_spectrums.size()) * 1.3/*scale factor*/;
		
		Point3D point3d(x,y,z);
		NSPoint point = [self pointXYFromPoint3D:point3d];		
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

	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.2;
		z = float(length)*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMaxFreq = [self pointXYFromPoint3D:point3d];
		[path lineToPoint:zeroAtMaxFreq];
	}
	
	{
		float x,y,z;
		x = float(index) * 200/(_spectrums.size()) * 1.3;
		y = 0.0f;
		y = y * 200/96 * 0.2;
		z = 0.0f*100/length*2;
		Point3D point3d(x,y,z);
		NSPoint zeroAtMinFreq = [self pointXYFromPoint3D:point3d];
		[path lineToPoint:zeroAtMinFreq];
	}
	
	[path closePath];
	[path fill];
	[[NSColor yellowColor] set];
	[path stroke];
	
}


- (void)drawLineFrom:(Point3D)from to:(Point3D)to{
	NSPoint from_xy = [self pointXYFromPoint3D:from];
	NSPoint to_xy = [self pointXYFromPoint3D:to];

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
    
    NSPoint point_xy = [self pointXYFromPoint3D:point3d];
    [at_text drawAtPoint:point_xy];
	
}



-(double)calculateAmpForFreq:(double)freq fromSpectrum:(const Spectrum &)spectrum{
	
	//assume sampling rate = 44.1kHz
	static const double SAMPLING_RATE = 44100.0;
	
	double freq_left = 0;
	double freq_right = 0;
	double amp_left = 0;
	double amp_right = 0;
	//find the neaest 
	
	//get neaest index
	int i = static_cast<int> (floor(freq / (SAMPLING_RATE/spectrum.size())));
	for( ; i < spectrum.size() ; i++){
		double f = SAMPLING_RATE/spectrum.size() * i;
		if (f < freq){
			freq_left = f;
			amp_left = abs(spectrum[i])/spectrum.size();
		}else{
			freq_right = f;
			amp_right = abs(spectrum[i])/spectrum.size();
			
			break;
		}
	}
	
	//線形補間
	double amp = linearInterporation(freq_left, amp_left, freq_right, amp_right, freq);
	return amp;
	
}

//draw one line for target freq
-(void) drawLineForFreq:(float)freq{
	
	double target_hz = freq;
	std::vector<double> amps;
	
	//amps = _spectrums.map {|s| s.ampForFreq(freq)}
	for (int index = 0; index < _spectrums.size() ; index++){
		double amp = [self calculateAmpForFreq:target_hz fromSpectrum:_spectrums[index]];
		amps.push_back(amp);
	}
	
	//amps.to_bezierPath().stroke
	NSBezierPath *path = [NSBezierPath bezierPath];
	for (int i = 0 ; i < amps.size() ; i++){
		float db = 20 * std::log10(amps[i]);
		if (db < -95) db = -96;
		float y = db + 96 + 0/*visible factor*/;
		float z = 0;
		if (_log){
			float logFreq = std::log10(target_hz);
			z = logFreq * 100.0f/(std::log10(22050) - std::log10(10));
			
			//normal
			//z *= 1.1;
			
			//周波数が高いほど手前になるようにしてみる。さらに、倍率を上げる。
			z = 100.0 - z;
			z *= 6.0;
		}else{
			z = target_hz * (100.0 / (FFT_SIZE/2.0))*2;
		}
		y = y * 200.0/96 * 0.2;	/*scale factor*/
		float x = i * (200.0/amps.size()) * 1.3;
		Point3D point3d(x,y,z);
		NSPoint point = [self pointXYFromPoint3D:point3d];
		if (i == 0){
			[path moveToPoint:point];
		}else{
			[path lineToPoint:point];
		}
	}
	[path stroke];
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
		
		RangeX *selection = [_aiff selection];		//notice selection is 0 to 100(full)
		float start = selection.start / 100.0f;
		float width = selection.end / 100.0f - start;
		float rate = width / SPECTRUM3D_COUNT;
		for (int i = 0; i < SPECTRUM3D_COUNT; i++){
			UInt32 frame = (UInt32) ([_aiff totalFrameCount] * (start + i*rate));
			[_aiff fastFFTForFrame:frame toBuffer:_spectrums[i] size:FFT_SIZE];
		}
		
		
		for(int index = 0; index < _spectrums.size(); index++){
			//[self drawSpectrum:_spectrums[index] index:index];
		}
		
		//10hzから22050hzまでを対数線形で描画
		double haba = std::log10(22050.0) - std::log10(10);
		double logfreq_unit = haba / 1000.0;
		for (int i = 0 ; i < 1000; i++){
			double logfreq = i * logfreq_unit;
			double freq = pow(10.0, logfreq);
			
			double red = 0.1 +  0.5 * (i / 1000.0);
			NSColor *color = [NSColor colorWithCalibratedRed:red/*0.5*/
													   green:0.1 
														blue:0.1
													   alpha:0.9];
			[color set];
			[self drawLineForFreq:freq];
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
- (void)setEnabled:(Boolean)enabled{
	_enabled = enabled;
	[self setNeedsDisplay:YES];
}

-(Boolean)log{
	return _log;
}


@end
