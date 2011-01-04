/*
 *  ieee.h
 *  AiffReader
 *
 *  Created by koji on 10/07/15.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

//IEEE 80 extended floating pointの変換ルーチンを
//http://www.onicos.com/staff/iz/formats/aiff.html 経由で持ってきた(ieee.c)が、ライセンスOKかいなこれ。
/* Interface Functions */ //defined in ieee.c


#ifdef __cplusplus
extern "C" {
#endif
	
	void ConvertToIeeeExtended(double num, char* bytes);
	double ConvertFromIeeeExtended(unsigned char* bytes);
	
#ifdef __cplusplus
}
#endif

