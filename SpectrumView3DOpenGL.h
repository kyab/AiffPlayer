//
//  SpectrumView3DOpenGL.h
//  AiffPlayer
//
//  Created by koji on 11/05/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface SpectrumView3DOpenGL : NSOpenGLView {
	bool _mouseDragging;
	NSPoint _prevDragPoint;
	id _aiff;
	
}
-(void)rotate:(float)angle forX:(float)x forY:(float)y forZ:(float)z;
-(void)setAiff:(id)aiff;
@end