//
//  WholeViewObjC.h
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Aiff.h>

typedef enum {
	DRAGMODE_NONE,		
	DRAGMODE_DRAGAREA,		//drag(move) whole selection
	DRAGMODE_NEWSELECTION,	//create new selection area 
	DRAGMODE_CHANGESTART,	//change start of selection
	DRAGMODE_CHANGEEND,		//change end of selection
}DRAGMODE;


@interface WholeViewObjC : NSView {
	Aiff *_aiff;
	NSBezierPath *_wavepath;
	
	//drawing optimization.
	NSRect _prevBounds;
	bool _highLight;
}

-(void)setAiff:(Aiff *)aiff;
-(void)recreateWavePath2;
-(void)piriodicUpdate;
-(void)forceRedraw;

-(void)processDragFromPoint:(NSPoint)startPoint mode:(DRAGMODE)mode;


@end
