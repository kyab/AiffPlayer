//
//  Aiff.h
//  AiffViewer
//
//  Created by koji on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <vector>

@interface Aiff : NSObject {
	NSMutableArray *_buffer_l;
	unsigned long _sampleCount;
	NSString *_fileName;
	std::vector<signed short> _stlbuffer;
	
	unsigned long _currentFrame;
}

- (void) loadFile: (NSString *)fileName;
- (NSMutableArray *)buffer;
- (std::vector<signed short> *)stlbuffer;
- (NSString *)fileName;

- (unsigned long) currentFrame;
- (unsigned long) totalFrameCount;

- (Boolean) renderToBuffer:(UInt32)channels sampleCount:(UInt32)sampleCount data:(void *)data;  

@end	
