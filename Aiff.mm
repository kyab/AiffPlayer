//
//  Aiff.m
//  AiffViewer
//
//  Created by koji on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Aiff.h"

#include "ieee.h"
#include "util.h"
#include <string>
#include <vector>


/* note
 
 基本的にAIFFはビッグエンディアン。仕様書には
 All data is stored in Motorola 68000 format とあるがMotorola 6800はビッグエンディアン。
*/

unsigned long swapByteOrderULong(unsigned long org){
	
	unsigned long ret = 0;
	unsigned char *p = (unsigned char *)&ret;
	/*
	 ret = ((org & 0xFF000000) >> 24) | 
	 ((org & 0x00FF0000) >> 8) | 
	 ((org & 0x0000FF00) << 8 ) | 
	 ((org & 0x000000FF) << 24);
	 */
	p[3] = (org & 0x000000FF);
	p[2] = (org & 0x0000FF00) >> 8;
	p[1] = (org & 0x00FF0000) >> 16;
	p[0] = (org & 0xFF000000) >> 24;
	return ret;
}

unsigned short swapByteOrderUShort(unsigned short org){
	return ((org & 0xFF00) >> 8) | ((org & 0x00FF) << 8);
}

signed short swapByteOrderShort(signed short org){
	return ((org & 0xFF00) >> 8) | ((org & 0x00FF) << 8);
}

@implementation Aiff

- (id) init{
	NSLog(@"init");
	NSLog(@"init exit");
	_buffer_l = [[NSMutableArray alloc] init];
	return self;
}

- (void) dealloc{
	[_buffer_l dealloc];
	[super dealloc];
}

- (void) loadFile: (NSString *)fileName{
	NSLog(fileName);
	
	//printf("%d\n", util());
	
	//const char *aiffFile = "/Users/koji/work/AiffReader/sound_files/MilkeyWay_48k_mono.aiff";
	_fileName = [NSString stringWithCString:aiffFile];
	
	//_fileName = fileName;
	
	FILE *fp;
	if ((fp = fopen(aiffFile,"rb")) == NULL){
		printf("can't open file:%s.\n",aiffFile);
		return ;
	}
	printf("reading file : %s\n", aiffFile);
	
	//read "FORM" chunk
	char str[5];
	str[4] = 0;
	fread(str,1,4,fp);
	printf("%s\n", str);		//Should be FORM
	
	unsigned long size;
	fread(&size, 4,1, fp);
	size = swapByteOrderULong(size);
	printf("size = 0x%x(%ld bytes)\n", size,size);  
	
	//read "AIFF" formType tag
	char formType[5];
	formType[4] = 0;
	fread(formType,1,4,fp);
	printf("%s\n", formType);
	
	
	//chunks ("COMM", "SSND",etc).
	char chunkName[5];
	chunkName[4] = 0;
	fread(chunkName,1,4,fp);
	printf("%s\n", chunkName);
	
	fread(&size, 4,1, fp);
	size = swapByteOrderULong(size);
	printf("size = 0x%x(%ld bytes)\n", size,size);  
	int prevPos = ftell(fp);
	
	unsigned short channels = 0;
	unsigned long sampleFrames = 0;
	
	std::string cName = chunkName;
	if (cName == "COMM"){
		printf("COMM chunk dumping\n");
		{	//parse Comm chunk
			
			
			unsigned short bitSize = 0;
			unsigned char sampleRateBytes[10];
			
			
			fread(&channels, 2 ,1 , fp);
			channels = swapByteOrderUShort(channels);
			
			fread(&sampleFrames, 4, 1, fp);
			sampleFrames = swapByteOrderULong(sampleFrames);
			
			fread(&bitSize, 2, 1, fp);
			bitSize = swapByteOrderUShort(bitSize);
			
			fread(&sampleRateBytes, 1, 10, fp);
			double sampleRate = ConvertFromIeeeExtended(sampleRateBytes);
			
			printf("%d channels, %d bits, %.2f[Hz], %d samples\n", channels, bitSize, sampleRate, sampleFrames);
			
			double duration = (double)sampleFrames / sampleRate;
			printf("%.2f [seconds]\n", duration); 
		}		
		
	}
	
	
	fseek(fp,prevPos, SEEK_SET);
	fseek(fp,size,SEEK_CUR);
	chunkName[4] = 0;
	fread(chunkName,1,4,fp);
	printf("%s\n", chunkName);
	
	
	fread(&size, 4,1, fp);
	size = swapByteOrderULong(size);
	printf("size = 0x%x(%ld bytes)\n", size,size);  	
	
	cName = chunkName;
	if (cName == "SSND"){
		printf("dumping SSND chunk\n");
		unsigned long offset = 0;
		unsigned long blockSize = 0;
		fread(&offset, 2, 1, fp);
		fread(&blockSize, 2, 1, fp);
		
		offset = swapByteOrderULong(offset);
		blockSize = swapByteOrderULong(blockSize);
		
		printf("offset = %d, blockSize = %d\n", offset, blockSize);
	}
	
	//read samples
	UnsignedWide startMicroSec;
	Microseconds(&startMicroSec);
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();



	printf("loading buffers...");
	if (channels == 1){
		//ensure size.
		signed short samples[sampleFrames];
		fread(samples, 2, sampleFrames, fp);
		printf("sampleFrames = %d\n", sampleFrames);
		for (int i = 0; i < sampleFrames ; i++){

			//signed short sample = swapByteOrderShort(samples[i]);
			//signed short sample = samples[i];
			//[_buffer_l addObject:
			//	[NSNumber numberWithShort:sample]];
			_stlbuffer.push_back(swapByteOrderShort(samples[i]));
		}
	}
	UnsignedWide endMicroSec;
	Microseconds(&endMicroSec);
	float startMicroSecFloat = startMicroSec.lo + startMicroSec.hi*4294967296.0; 
	float endMicroSecFloat = endMicroSec.lo + endMicroSec.hi * 4294967296.0; 
	float duration = (endMicroSecFloat - startMicroSecFloat)/1000;
	printf("done(takes %f[msec]\n", duration);
	printf("done(takes %f[sec]\n", CFAbsoluteTimeGetCurrent() - start);
	
	//もっと高精度のタイマはたぶんこちら
	//http://www.carbondev.com/site/?page=Time
	//timeIntervalSinceDate
	fclose(fp);	
	
	
}

- (NSMutableArray *)buffer{
	return _buffer_l;
}

- (NSString *)fileName{
	return _fileName;
}

- (std::vector<signed short> *)stlbuffer{
	return &_stlbuffer;
}

@end
