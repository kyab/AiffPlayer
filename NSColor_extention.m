//
//  NSColor_extention.m
//  OpenGLSimpleRotation
//
//  Created by koji on 11/03/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSColor_extention.h"

@implementation NSColor (OpenGLExtention)
-(void)openGLClearColor{
	//NSLog(@"OpenGL Extention");
	NSColor *aColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r,g,b,a;
	[aColor getRed:&r green:&g blue:&b alpha:&a];
	glClearColor(r,g,b,a);
}

-(void)openGLColor4f{
	NSColor *aColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r,g,b,a;
	[aColor getRed:&r green:&g blue:&b alpha:&a];
	glColor4f(r,g,b,a);	
}

@end

