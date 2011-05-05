//
//  NSColor_extention.h
//  OpenGLSimpleRotation
//
//  Created by koji on 11/03/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <GLUT/glut.h>
#include <OpenGL/glext.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

@interface NSColor (OpenGLExtention)
-(void)openGLClearColor;
-(void)openGLColor4f;
@end
