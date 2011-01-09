//
//  WholeViewObjC.m
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WholeViewObjC.h"

bool isSameRect(const NSRect &rect1, const NSRect &rect2){
	if ( (rect1.origin.x == rect2.origin.x) &&
		 (rect1.origin.y == rect2.origin.y) &&
		 (rect1.size.width == rect2.size.width ) &&
		(rect1.size.height == rect2.size.height)){
		return true;
	}
	
	return false;
}

@implementation WholeViewObjC

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
	_wavepath = nil;
	_wavepath_transformed = nil;
	_prevBounds = [self bounds];
    return self;
}

-(void)setAiff:(Aiff *)aiff{
	NSLog(@"WhileViewObjec::setAiff called with arg=%p",aiff);
	
	_aiff = aiff;
	[self recreateWavePath];
	[self recreateWavePath_transformed];
	[self setNeedsDisplay:TRUE];
	
	
}


-(void)recreateWavePath{
	
	[_wavepath release];
	_wavepath = [NSBezierPath bezierPath];
	
	[_wavepath setLineWidth:1];
	
	std::vector<signed short> *samples = [_aiff stlbuffer];
	NSLog(@"recreateWavePath count=%d", samples->size()/2);
	
	//さすがにこれだと重すぎる。
	[_wavepath moveToPoint: NSMakePoint(0, (*samples)[0])];
	for (int i =0; i < samples->size() ;i+=2){
		float x = i;
		float y = (*samples)[i];
		[_wavepath lineToPoint: NSMakePoint(x,y)];
	}
	
}

-(void)recreateWavePath_transformed{
	[_wavepath_transformed release];
	
	std::vector<signed short> *samples = [_aiff stlbuffer];
	if (!samples){
		return;
	}
	
	const int SHORT_MAX = 0xFFFF/2;
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	float x_ratio = (float)([self bounds].size.width) / (samples->size()/2);
	float y_ratio = (1.0f / SHORT_MAX) * ([self bounds].size.height)/2.0f;
	float y_addition = [self bounds].size.height / 2.0f;
	[transform translateXBy:0 yBy:y_addition];
	[transform scaleXBy:x_ratio yBy:y_ratio];
	
	_wavepath_transformed = [transform transformBezierPath:_wavepath];
	NSLog(@"recreated _wavepath_transformed");
}

- (void)drawRect:(NSRect)rect {

	if ([self inLiveResize]){
		//return;
	}
	
	//draw background
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
	

	///////////
	//draw sound
	[[NSColor cyanColor] set];

	//Make a transform
	std::vector<signed short> *samples = [_aiff stlbuffer];
	if (!samples){
		return;
	}
	if (!isSameRect(_prevBounds, [self bounds])){
		_prevBounds = [self bounds];
		[self recreateWavePath_transformed];
	}

	[_wavepath_transformed stroke];
	
	/////////////////////////////////////
	//draw current play position line
	[[NSColor yellowColor] set];
	
	unsigned long currentFrame = [_aiff currentFrame];		//frame = sample
	unsigned long totalFrameCount = [_aiff totalFrameCount];
	float x = 0.0f;
	if (totalFrameCount > 0){
		x = ([self bounds].size.width) * currentFrame/totalFrameCount;
	}
	
	NSRectFill(NSMakeRect(x,0,2,[self bounds].size.height));	
}

@end
