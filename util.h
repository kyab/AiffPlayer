//
//  util.h
//  AiffPlayer
//
//  Created by koji on 11/01/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef __UTIL_H__
#define __UTIL_H__

#import <Cocoa/Cocoa.h>

#import "MacRuby/MacRuby.h"
#include <string>
#include <typeinfo>


//demangle function
//http://d.hatena.ne.jp/hidemon/20080731/1217488497
#include <string>


std::string demangle(const char * name);


//dump C struct with MacRuby
//using ruby to meta
template <typename T>
void dump_struct(const T &t){
	const std::type_info &type = typeid(t);
	std::string demangled_type_name = demangle(type.name());
	
	NSValue *v = [NSValue valueWithPointer:&t];
	NSString *typeName = [NSString stringWithCString:demangled_type_name.c_str() encoding:kCFStringEncodingUTF8 ];
	id ruby_util = [[MacRuby sharedRuntime] evaluateString:@"RUtil"];
	[ruby_util performRubySelector:@selector(dump_struct_withName:) withArguments:v,typeName,NULL];
}


//benchmark
class Timer{
public:
	Timer(){
	}
	
	void start(){
		_startTime = CFAbsoluteTimeGetCurrent();
	}
	
	void stop(){
		_endTime = CFAbsoluteTimeGetCurrent();
	}
	
	CFAbsoluteTime result(){
		return _endTime - _startTime;
	}
private:
	CFAbsoluteTime _startTime, _endTime;
};
		
	

#endif //__UTIL_H__
