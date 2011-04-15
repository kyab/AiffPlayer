//
//  WholeViewObjC.m
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WholeViewObjC.h"
#include <math.h>

static const int CURSOR_BOUND_SIZE = 20;

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
	_prevBounds = [self bounds];
	_highLight = false;
    return self;
}

-(void)setAiff:(Aiff *)aiff{
	NSLog(@"WhileViewObjec::setAiff called with arg=%p",aiff);
	
	_aiff = aiff;
	
	_aiff.selection.start = 20.0f;
	_aiff.selection.end = 45.0f;
	[self recreateWavePath2];
	[self setNeedsDisplay:YES];
	
}

-(void)forceRedraw{
	[self recreateWavePath2];
	[self setNeedsDisplay:YES];
}

//現在の再生時刻を参考に、部分再描画を行う。
-(void)piriodicUpdate{
	
	float position_ratio = [_aiff currentFrame]/float([_aiff totalFrameCount]);
	float view_width = [self bounds].size.width;
	float view_height = [self bounds].size.height;
	
	float x = view_width * position_ratio;
	
	//部分描画する。ピクセル分横幅を描画する。
	x = x-200;
	float width = 400;
	
	NSRect rectToRedraw = NSMakeRect(x,0,width, view_height);

	[self setNeedsDisplayInRect:rectToRedraw];
	//[self displayRect:rectToRedraw];
	//NSLog(@"foo");
	
	//だめだー、これだけだと以前の再生カーソルが消えない場合がある。レイヤー表示とか使うべきなの？
}

-(void)recreateWavePath2{
	
	[_wavepath release];
	_wavepath =  [[NSBezierPath bezierPath] retain];
	
	NSRect bounds = [self bounds];
	
	NSLog(@"bounds = [%f,%f]",bounds.size.width, bounds.size.height);
	//区間最大と区間最小。
	
	[_wavepath setLineWidth:1.0f];
	//[_wavepath setLineCapStyle:NSRoundLineCapStyle];
	
	std::vector <float >*samples = [_aiff right];
	NSLog(@"recreateWavePath2 count=%lu", samples->size());
	
	[_wavepath moveToPoint:NSMakePoint(0, (*samples)[0])];
	
	//const int SHORT_MAX = 0xFFFF/2;
	float y_addition = bounds.size.height / 2.0f;
	float y_ratio = (bounds.size.height)/2.0f;
	
	float samples_per_pixel = float(samples->size())/bounds.size.width;
	//TODO このレートが小さい時は全サンプルを描画する方法に変える->Oscilloscopeにて実装済み。
	
	//各ピクセルが占めるサンプルの最小値から最大値への縦棒
	UInt32 sample_from = 1;
	UInt32 sample_to = 0;
	for (UInt32 pixel = 1; pixel < bounds.size.width ; pixel++){
		sample_to = (UInt32)floor(pixel * samples_per_pixel);
		
		float max = (*samples)[sample_from];
		float min = max;
		for(int i =sample_from; i < sample_to; i++){
			float val = (*samples)[i];
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

- (NSRect) selectionRect{
	NSRect rect = [self bounds];
	
	rect.origin.x = _aiff.selection.start / 100.0 * self.bounds.size.width;
	rect.size.width = _aiff.selection.end / 100.0 * self.bounds.size.width -  rect.origin.x;
	return rect;
}

-(NSRect) selectionRectWithoutBound{
	NSRect rect = [self selectionRect];
	rect.origin.x += CURSOR_BOUND_SIZE/2;
	rect.size.width -= CURSOR_BOUND_SIZE;
	return rect;
}

-(NSRect) selectionBoundLeftRect{
	NSRect rect = [self selectionRect];
	rect.origin.x -= CURSOR_BOUND_SIZE/2;
	rect.size.width = CURSOR_BOUND_SIZE;
	return rect;
}

-(NSRect) selectionBoundRightRect{
	NSRect rect = [self selectionRect];
	rect.origin.x += rect.size.width;
	rect.origin.x -= CURSOR_BOUND_SIZE/2;
	rect.size.width = CURSOR_BOUND_SIZE;
	return rect;
}

- (void)resetCursorRects{
	[self discardCursorRects];
	
	[self addCursorRect:[self selectionRectWithoutBound] cursor:[NSCursor openHandCursor]];
	[self addCursorRect:[self selectionBoundLeftRect] cursor:[NSCursor resizeLeftRightCursor]];
	[self addCursorRect:[self selectionBoundRightRect] cursor:[NSCursor resizeLeftRightCursor]];	
}


-(float)percentFromPixelX:(float)x{
	return 100.0f * x / self.bounds.size.width;	
}

-(void)dragStarted:(NSPoint)startPoint mode:(DRAGMODE)mode{
	//push the cursor for each mode.
	switch(mode){
		case DRAGMODE_NEWSELECTION:
			[[NSCursor IBeamCursor] push];
			break;
		case DRAGMODE_CHANGEEND:
		case DRAGMODE_CHANGESTART:
			[[NSCursor resizeLeftRightCursor] push];
			break;
		case DRAGMODE_DRAGAREA:
			[[NSCursor closedHandCursor] push];
			break;
		default:
			NSAssert(false, @"dragStarted: invalid mode.");
			break;
	}
	
	//draw fake small selection before actual dragging, for new selection mode.
	if (mode == DRAGMODE_NEWSELECTION){
		_aiff.selection.start = 100.0f * startPoint.x / self.bounds.size.width;
		_aiff.selection.end = _aiff.selection.start + 0.1f;
	}
	
	_highLight = true;
	[self setNeedsDisplay:YES];
	
}

-(void)dragCompleted{
	[NSCursor pop];
	[[self window] invalidateCursorRectsForView:self];
	
	_highLight = false;
	[self setNeedsDisplay:YES];
}

-(void)processDragFromPoint:(NSPoint)startPoint mode:(DRAGMODE)mode{
	[self dragStarted:startPoint mode:mode];
	bool loop = true;
	NSPoint prevPoint = startPoint;
	while(loop){
		
		//////
		//get the next event and whose mouse location.
		
		//note1. drawing is processed in nextEventMatchingMask
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		NSPoint newPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		
		switch([event type]){
			case NSLeftMouseDragged:
				switch (mode){
					case DRAGMODE_NEWSELECTION:
					{
						//swap position if needed
						float leftX, rightX;
						if (newPoint.x > startPoint.x){
							leftX = startPoint.x;
							rightX = newPoint.x;
						}else{
							leftX = newPoint.x;
							rightX = startPoint.x;
						}
						
						RangeX *selection = [_aiff selection];
						selection.start = 100.0 * leftX / self.bounds.size.width;
						selection.end = 100.0 * rightX / self.bounds.size.width;
					}
						break;
					case DRAGMODE_DRAGAREA:
					{
						RangeX *selection = _aiff.selection;
						
						float offset = [self percentFromPixelX:(newPoint.x - prevPoint.x)];
						if (selection.end + offset > 100.0f){
							//精度に難有りか、、
							float actual_offset = 100.0f - selection.end;
							[selection offset:actual_offset];
							
							prevPoint.y = newPoint.y;
							prevPoint.x += actual_offset / 100.0f * self.bounds.size.width;
						}else if (selection.start + offset < 0.0f){
							float actual_offset = - selection.start;
							[selection offset:actual_offset];
							
							prevPoint.y = newPoint.y;
							prevPoint.x += actual_offset / 100.0f * self.bounds.size.width;
						}else{
							[selection offset:offset];
							prevPoint = newPoint;
						}
						
					}
						break;
					case DRAGMODE_CHANGESTART:
					{
						RangeX *selection = _aiff.selection;
						
						float offset = [self percentFromPixelX:(newPoint.x - prevPoint.x)];
						
						if (selection.start + offset < 0.0f){
							//mouse is out of left boundary
							float actual_offset = -selection.start;
							selection.start = 0;
							prevPoint.x += actual_offset / 100.0f * self.bounds.size.width;
						}else if (selection.start + offset > selection.end){
							//mouse is righter than end-of-selection.
							float prev_start = selection.start;
							selection.start = selection.end;
							selection.end = prev_start + offset;
							
							mode = DRAGMODE_CHANGEEND;
							prevPoint = newPoint;
						}else{
							selection.start += offset;
							prevPoint = newPoint;
						}
						
					}
						break;
					case DRAGMODE_CHANGEEND:
					{
						RangeX *selection = _aiff.selection;
						
						float offset = [self percentFromPixelX:(newPoint.x - prevPoint.x)];
						if (selection.end + offset > 100.0f){
							float actual_offset = 100.0f - selection.end;
							selection.end = 100.0f;
							prevPoint.x += actual_offset / 100.0f * self.bounds.size.width;
						}else if (selection.end + offset < selection.start){
							float prev_end = selection.end;
							selection.end = selection.start;
							selection.start  = prev_end + offset;
							mode = DRAGMODE_CHANGESTART;
							prevPoint = newPoint;
						}else{
							selection.end += offset;
							prevPoint = newPoint;
						}
					}
						break;
					default:
						break;
				}
				[self setNeedsDisplay:YES];
				break;
			case NSLeftMouseUp:
				[NSCursor pop];
				[[self window] invalidateCursorRectsForView:self];
				
				_highLight = false;
				[self setNeedsDisplay:YES];
				
				loop = false; //exit loop
				break;
			default:
				break;
		}
	}
	[self dragCompleted];
}

- (void)mouseDown:(NSEvent *)theEvent{
	
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (NSPointInRect(curPoint,[self selectionRectWithoutBound])){
		[self processDragFromPoint:curPoint mode:DRAGMODE_DRAGAREA];
	}else if (NSPointInRect(curPoint, [self selectionBoundLeftRect])){
		[self processDragFromPoint:curPoint mode:DRAGMODE_CHANGESTART];
	}else if (NSPointInRect(curPoint, [self selectionBoundRightRect])){
		[self processDragFromPoint:curPoint mode:DRAGMODE_CHANGEEND];
	}else{	
		[self processDragFromPoint:curPoint mode:DRAGMODE_NEWSELECTION];
		
	}	
	/*
	 NSLog(@"scrib start(%f,%f)", curPoint.x, curPoint.y);
	 if (_aiff){
	 [_aiff setCurrentFrameInRate:(curPoint.x)/([self bounds].size.width) scribStart:YES];
	 }*/
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
	
	//disable anti-alias
	//NSLog(@"current anti alias state = %d", [context shouldAntialias]);
	[context setShouldAntialias:NO];


	std::vector<float> *samples = [_aiff left];
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
	
	/////////////////////
	//draw current selection rectangle
	// see Apple's CompositLab example for more sophicicated color composite..
	{
		NSColor *selectionColor = [NSColor yellowColor];
		selectionColor = [selectionColor colorWithAlphaComponent:0.5];
		[selectionColor set];
	}
	NSRectFillUsingOperation([self selectionRect], NSCompositeSourceOver);
	
}



- (void)mouseUp:(NSEvent *)theEvent{
	NSLog(@"mouse up");
	//[super mouseUp:theEvent];
	if (_aiff){
		[_aiff setScrib:NO];
	}
	NSLog(@"Scrib end");
}

- (void)mouseDragged:(NSEvent *)theEvent{
	NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	//NSLog(@"drag(%f,%f)", curPoint.x, curPoint.y);
	if (NSPointInRect(curPoint, [self bounds])){
		[_aiff setCurrentFrameInRate:(curPoint.x)/([self bounds].size.width) scribStart:YES];
	}
}

/*needs setAcceptsMouseMovedEvents for window, to receive this event*/
- (void)mouseMoved:(NSEvent *)theEvent{
	//needs setAcceptsMouseMovedEvents:
	NSLog(@"mouse moved");
}


@end
