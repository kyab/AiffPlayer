//
//  util.m
//  AiffPlayer
//
//  Created by koji on 11/01/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "util.h"
#include <string>

extern "C" char *__cxa_demangle (
								 const char *mangled_name,
								 char *output_buffer,
								 size_t *length,
								 int *status);

std::string demangle(const char * name) {
    size_t len = strlen(name) + 256;
    char output_buffer[len];
    int status = 0;
    return std::string(
					   __cxa_demangle(name, output_buffer, 
									  &len, &status));
}

