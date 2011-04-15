//
//  PercentStringTransformer.m
//  AiffPlayer
//
//  Created by koji on 11/04/16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PercentStringTransformer.h"
#import "RangeX.h"

@implementation PercentStringTransformer

+(Class) transformedValueClass{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return FALSE;
}

-(id)transformedValue:(id)value{
	
	if (value == nil) return nil;
	
	NSLog(@"transformer");
	float start = [(RangeX *)value start];
	float end = [(RangeX *)value end];
	
	NSString *result = [NSString stringWithFormat:@"%0.2f%% to %0.2f%%" ,start, end];
	
	return result;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end
