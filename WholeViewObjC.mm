//
//  WholeViewObjC.m
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WholeViewObjC.h"
#include <math.h>

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
	//[self recreateWavePath];
	//[self recreateWavePath_transformed];
	[self recreateWavePath2];
	[self setNeedsDisplay:TRUE];
	
	
}

//現在の再生時刻を参考に、部分再描画を行う。
-(void)piriodicUpdate{
	
	float position_ratio = [_aiff currentFrame]/float([_aiff totalFrameCount]);
	float view_width = [self bounds].size.width;
	float view_height = [self bounds].size.height;
	
	float x = view_width * position_ratio;
	
	//少し手前から50ピクセル分横幅を描画する。
	x = x-200;
	float width = 400;
	
	NSRect rectToRedraw = NSMakeRect(x,0,width, view_height);

	[self setNeedsDisplayInRect:rectToRedraw];
	//[self displayRect:rectToRedraw];
	//NSLog(@"foo");
	
	//だめだー、これだけだと以前の再生カーソルが消えない場合がある。
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

-(void)recreateWavePath2{
	
	[_wavepath release];
	_wavepath = [NSBezierPath bezierPath];
	
	NSRect bounds = [self bounds];
	
	NSLog(@"bounds = [%f,%f]",bounds.size.width, bounds.size.height);
	//区間最大と区間最小。
	
	[_wavepath setLineWidth:1.0f];
	//[_wavepath setLineCapStyle:NSRoundLineCapStyle];
	std::vector <signed short >*samples = [_aiff stlbuffer];
	NSLog(@"recreateWavePath2 count=%d", samples->size()/2);
	
	[_wavepath moveToPoint:NSMakePoint(0, (*samples)[0])];
	
	const int SHORT_MAX = 0xFFFF/2;
	float y_addition = bounds.size.height / 2.0f;
	float y_ratio = (1.0f / SHORT_MAX) * (bounds.size.height)/2.0f;
	
	float samples_per_pixel = float(samples->size()/2)/bounds.size.width;
	//TODO このレートが小さい時は全サンプルを描画する方法に変える。
	
	UInt32 sample_from = 1;
	UInt32 sample_to = 0;
	for (UInt32 pixel = 1; pixel < bounds.size.width ; pixel++){
		sample_to = (UInt32)floor(pixel * samples_per_pixel);
		
		float max = (*samples)[sample_from*2];
		float min = max;
		for(int i =sample_from; i < sample_to; i++){
			float val = (*samples)[i*2];
			if (val > max) max = val;
			if (val < min) min = val;
		}

		min = (min*y_ratio) + y_addition;
		max = (max*y_ratio) + y_addition;
		[_wavepath moveToPoint:NSMakePoint(pixel, min)];
		[_wavepath lineToPoint:NSMakePoint(pixel, max)];
		sample_from = sample_to;
	}
	
	//4)基本的にはリサンプリングするのが正しいはず。=表示される時間幅/ピクセル数
	/*でもそれだと超低サンプリングレートになるだけか。
	 区間最大値と最小値を書く?*/
	//
	//5)Cool Editはなんでこんな正確かつ軽いんだ。。
	
	/*
	 だめだ、アニメーションはともかくとして、如何に直感的、かつ少ないポイントで波形を表示できるかに集中!!*/
	
	
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
	[[NSColor greenColor] set];
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	
	//disable anti-alias(default anti aliased)
	//NSLog(@"current anti alias state = %d", [context shouldAntialias]);
	[context setShouldAntialias:NO];
	

	//Make a transform
	std::vector<signed short> *samples = [_aiff stlbuffer];
	if (!samples){
		return;
	}

	if (!isSameRect(_prevBounds, [self bounds])){
		_prevBounds = [self bounds];
		[self recreateWavePath2];
	}
	[_wavepath stroke];
	
	/////////////////////////////////////
	//draw current play position line
	[[NSColor whiteColor] set];
	
	unsigned long currentFrame = [_aiff currentFrame];		//frame = sample
	unsigned long totalFrameCount = [_aiff totalFrameCount];
	float x = 0.0f;
	if (totalFrameCount > 0){
		x = ([self bounds].size.width) * currentFrame/totalFrameCount;
	}
	
	NSRectFill(NSMakeRect(x,0,1,[self bounds].size.height));	
}

@end
