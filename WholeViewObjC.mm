//
//  WholeViewObjC.m
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WholeViewObjC.h"


@implementation WholeViewObjC

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
	_wavepath = nil;
    return self;
}

-(void)setAiff:(Aiff *)aiff{
	NSLog(@"WhileViewObjec::setAiff called with arg=%p",aiff);
	
	_aiff = aiff;
	[self recreateWavePath];
	[self setNeedsDisplay:TRUE];
	
	
}


-(void)recreateWavePath{
	
	[_wavepath release];
	_wavepath = [NSBezierPath bezierPath];
	
	[_wavepath setLineWidth:1];
	
	std::vector<signed short> *samples = [_aiff stlbuffer];
	NSLog(@"recreateWavePath count=%d", samples->size()/2);
	
	[_wavepath moveToPoint: NSMakePoint(0, (*samples)[0])];
	for (int i =0; i < samples->size() ;i+=2){
		float x = i;
		float y = (*samples)[i];
		[_wavepath lineToPoint: NSMakePoint(x,y)];
	}
	
}


-(id)aiff{
	return _aiff;
}


- (void)drawRect:(NSRect)rect {
	if ([self inLiveResize]){
		//return;
	}
	[[NSColor blackColor] set];
	NSRectFill([self bounds]);
	
	//draw current play position line
	
	
	const int SHORT_MAX = 0xFFFF/2;
	
	[[NSColor cyanColor] set];
	//NSMutableArray *samples = [_aiff buffer];
	std::vector<signed short> *samples = [_aiff stlbuffer];
	if (!samples){
		return;
	}
	//Make a transform
	NSAffineTransform *transform = [NSAffineTransform transform];
	float x_ratio = (float)([self bounds].size.width) / (samples->size()/2);
	float y_ratio = (1.0f / SHORT_MAX) * ([self bounds].size.height)/2.0f;
	float y_addition = [self bounds].size.height / 2.0f;
	[transform translateXBy:0 yBy:y_addition];
	[transform scaleXBy:x_ratio yBy:y_ratio];
	
	NSBezierPath *path = [transform transformBezierPath:_wavepath];
	[path stroke];
	
	NSLog(@"drawRect");

}

@end
