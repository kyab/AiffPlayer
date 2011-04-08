//
//  WholeViewObjC.h
//  AiffViewer
//
//  Created by koji on 10/08/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Aiff.h>

@interface WholeViewObjC : NSView {
	Aiff *_aiff;
	NSBezierPath *_wavepath;
	NSBezierPath *_wavepath_transformed;
	NSRect _prevBounds;
}

-(void)setAiff:(Aiff *)aiff;
-(void)recreateWavePath2;
-(void)piriodicUpdate;
-(void)forceRedraw;
@end
