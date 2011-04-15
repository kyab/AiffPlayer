//
//  RangeX.m
//  AiffPlayer
//
//  Created by koji on 11/04/15.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RangeX.h"

@implementation RangeX

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		[self setStart:0.0f];
		[self setEnd:0.0f];
		NSLog(@"RangeX::init, start = %f, end = %f",
			  _start, _end);
    }
    return self;
}

-(float)restrictToPercent:(float)val{
	if (val < 0.0f){
		return 0.0f;
	}else if (val > 100.0f){
		return 100.0f;
	}
	return val;
}

- (void)dealloc
{
    [super dealloc];
}

-(float)start{
	return _start;
}

-(void)setStart:(float)start{
	_start = [self restrictToPercent:start];
}

-(void)setEnd:(float)end{
	_end = [self restrictToPercent:end];
}

- (float)end{
	return _end;
}

-(void)offset:(float)offset{
	self.start += offset;
	self.end += offset;
}


@end

