//
//  glhelper.c
//  AiffPlayer
//
//  Created by koji on 11/05/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#include <OpenGL/OpenGL.h>
#import <Cocoa/Cocoa.h>
#import "glhelper.h"


void GLwithLight(void (^block)(void)){
	glEnable(GL_LIGHTING);
	block();
	glDisable(GL_LIGHTING);
}

void foo(){
	NSLog(@"foo");
}