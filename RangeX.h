//
//  RangeX.h
//  AiffPlayer
//
//  Created by koji on 11/04/15.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RangeX : NSObject {
@private
    float _start;
	float _end;
}

-(float)end;
-(float)start;
-(void)setStart:(float)start;
-(void)setEnd:(float)end;
-(void)offset:(float)offset;
@end
