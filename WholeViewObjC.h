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
}

-(void)setAiff:(Aiff *)aiff;
-(id)aiff;
-(void)recreateWavePath;

@end
