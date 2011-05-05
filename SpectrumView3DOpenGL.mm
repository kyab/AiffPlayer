//
//  SpectrumView3DOpenGL.m
//  AiffPlayer
//
//  Created by koji on 11/05/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpectrumView3DOpenGL.h"
#import "NSColor_extention.h"

@implementation SpectrumView3DOpenGL

- (id)initWithFrame:(NSRect)frameRect{
	NSLog(@"SpectrumView3DOpenGL::initWithFrame");
	self = [super initWithFrame:frameRect];
	if (self){
		// intializatio code here
	}
	return self;
}

- (void)rotate:(float)angle forX:(float)x forY:(float)y forZ:(float)z{
	
}

-(void)setAiff:(id)aiff{
	_aiff = aiff;
}

-(void)drawRect:(NSRect)dirtyRect{
	NSLog(@"OpenGL: drawRect");
	
	[[NSColor blackColor] openGLClearColor];
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	
	glFinish();
	glFlush();
}

@end
