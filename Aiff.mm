//
//  Aiff.m
//  AiffViewer
//
//  Created by koji on 10/08/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Aiff.h"

#include "ieee.h"
#include <string>
#include <vector>
#import "util.h"
#include "fft.h"

static const int SHORT_MAX = 0xFFFF/2;

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
	self = [super init];
	if(self){
		
		NSLog(@"init");
		//_buffer_l = [[NSMutableArray alloc] init];
	
		_currentFrame = 0;
		_useLowPass = false;
		_scrib = NO;
		_observer = nil;
	
		typedef std::complex<float> complexf;
	
		_samples.assign(1024, complexf(0.0));
		_result.assign(1024, complexf(0.0));
	}
	
	return self;
	
	
}

- (void) dealloc{
	//[_buffer_l dealloc];
	[super dealloc];
}

- (void) loadFile: (NSString *)fileName{
	NSLog(@"%@",fileName);
	
	_currentFrame = 0;
	_scribStartFrame = 0;
	_sampleCount = 0;
	_stlbuffer.clear();
	_stlbuffer_lowpassed.clear();
	_left.clear();
	
	_useLowPass = false;
	
	printf("size of unsigned long=%ld\n", sizeof(unsigned long));
	
	_fileName = fileName;
	
	FILE *fp;
	if ((fp = fopen([_fileName UTF8String],"rb")) == NULL){
		NSLog(@"can't open file:%@.\n",_fileName);
		return ;
	}
	NSLog(@"reading file : %@\n", _fileName);
	
	//read "FORM" chunk
	char str[5];
	str[4] = 0;
	fread(str,1,4,fp);
	printf("%s\n", str);		//Should be FORM
	
	unsigned long size;
	fread(&size, 4,1, fp);
	size = swapByteOrderULong(size);
	printf("size = 0x%lx(%ld bytes)\n", size,size);  
	
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
	printf("size = 0x%lx(%ld bytes)\n", size,size);  
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
			
			printf("%d channels, %d bits, %.2f[Hz], %ld samples\n", channels, bitSize, sampleRate, sampleFrames);
			
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
	printf("size = 0x%lx(%ld bytes)\n", size,size);  	
	
	cName = chunkName;
	if (cName == "SSND"){
		printf("dumping SSND chunk\n");
		unsigned long offset = 0;
		unsigned long blockSize = 0;
		fread(&offset, 4, 1, fp);
		fread(&blockSize, 4, 1, fp);
		
		offset = swapByteOrderULong(offset);
		blockSize = swapByteOrderULong(blockSize);
		
		printf("offset = %ld, blockSize = %ld\n", offset, blockSize);
	}
	
	//read samples
	UnsignedWide startMicroSec;
	Microseconds(&startMicroSec);
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();



	printf("loading buffers...");
	//if (channels == 1){		//assuming stereo only?
		//ensure size.
		signed short samples[sampleFrames*channels];
		fread(samples, 2, sampleFrames*channels, fp);
		printf("sampleFrames = %ld\n", sampleFrames);
		for (int i = 0; i < sampleFrames*channels ; i++){
			
			_stlbuffer.push_back(swapByteOrderShort(samples[i]));
			if (0 == (i % 2)){
				_left.push_back((float)samples[i]/SHORT_MAX);
			}
		}
	
	printf("STL Buffer array size = %lu\n", _stlbuffer.size());

	UnsignedWide endMicroSec;
	Microseconds(&endMicroSec);
	float startMicroSecFloat = startMicroSec.lo + startMicroSec.hi*4294967296.0; 
	float endMicroSecFloat = endMicroSec.lo + endMicroSec.hi * 4294967296.0; 
	float duration = (endMicroSecFloat - startMicroSecFloat)/1000;
	printf("done(file reading takes %f[msec]\n", duration);
	printf("done(file reading takes %f[sec]\n", CFAbsoluteTimeGetCurrent() - start);
	
	//もっと高精度のタイマはたぶんこちら
	//http://www.carbondev.com/site/?page=Time
	//timeIntervalSinceDate
	fclose(fp);	
	
	
}

/*
- (NSMutableArray *)buffer{
	return _buffer_l;
}*/

- (NSString *)fileName{
	return _fileName;
}

- (unsigned long) currentFrame{
	return _currentFrame;
}

- (void) setCurrentFrameInRate: (float) rate scribStart:(Boolean)scribStart{
	if (_stlbuffer.size() == 0){
		NSLog(@"aiff is empty now");
		return;
	}
	_currentFrame = (unsigned long)([self totalFrameCount] * rate);
	if(scribStart){
		[self setScrib:YES];
		_scribStartFrame = _currentFrame;
	}
	
	//notify to observers.
	if (_observer){
		[_observer performSelector:_notify_selector];
	}
	
	//NSLog(@"current frame changed to %u", _currentFrame);
}

- (unsigned long) totalFrameCount{
	return _stlbuffer.size() / 2;
}

- (Boolean)scrib{
	return _scrib;
}
- (void) setScrib: (Boolean)b{
	if (b){
		NSLog(@"scribbing on in Aiff");
	}else{
		NSLog(@"scribbing off in Aiff");
	}
	_scrib = b;
}



//break encupsulation
- (std::vector<signed short> *)stlbuffer{
	return _useLowPass ? &_stlbuffer_lowpassed : &_stlbuffer;
}

//also breaking encupsulation!
-(std::vector<float> *) left{
	return &_left;
}

- (void)setUseLowpass:(Boolean)useLowpass{
	_useLowPass = useLowpass;
	if (_useLowPass){
		if (_stlbuffer_lowpassed.size() == 0){
			[self lowpass];
		}
	}
}

//create simple lowpassed samples.
- (void)lowpass{
	_stlbuffer_lowpassed.clear();
	
	//super simple lowpass filter
	for(UInt32 frame = 0; frame < _stlbuffer.size()/2; frame++){

		UInt32 prev_frame = 0;
		if (frame >10) {prev_frame = frame-10;}
		
		float sample_l = _stlbuffer[frame*2]*0.5 + _stlbuffer[prev_frame*2]*0.5;
		float sample_r = _stlbuffer[frame*2+1]*0.5 + _stlbuffer[prev_frame*2+1]*0.5;
		
		_stlbuffer_lowpassed.push_back((signed short) (sample_l));
		_stlbuffer_lowpassed.push_back((signed short) (sample_r));
	}
	NSLog(@"LOWPASS sample created");
}

-(std::vector<std::complex<double> >)getSlowFFTBuffer{
	std::vector<signed short> &stlbuffer =  _useLowPass ? _stlbuffer_lowpassed : _stlbuffer;
	const int SHORT_MAX = 0xFFFF/2;
	
	//get float values (-1.0 to 1.0, left channel only)
	for(int i = 0 ; i < 1024; i++){
		_samples[i] = ( (double)stlbuffer[(_currentFrame + i)*2] / SHORT_MAX);
	}	
	
	Timer timer ; timer.start();
	slowForwardFFT(&_samples[0], 1024, &_result[0]);
	timer.stop();
	//NSLog(@"FFT(slow recursive) for 1024 samples takes %f[msec]", (timer.result())*1000);
	return _result;
}

-(std::vector<std::complex<double> >)getFastFFTBuffer{
	std::vector<signed short> &stlbuffer =  _useLowPass ? _stlbuffer_lowpassed : _stlbuffer;
	const int SHORT_MAX = 0xFFFF/2;
	
	int frame = _currentFrame;
	if (_scrib){
		frame = _scribStartFrame;
	}
	
	//get float values (-1.0 to 1.0, left channel only)
	for(int i = 0 ; i < 1024; i++){
		_samples[i] = ( (double)stlbuffer[(frame+ i)*2] / SHORT_MAX);
	}	
	
	Timer timer ; timer.start();
	fastForwardFFT(&_samples[0], 1024, &_result[0]);
	timer.stop();
	//NSLog(@"FFT(fast) for 1024 samples takes %f[msec]", (timer.result())*1000);
	return _result;
}



//DFTの実装。メインループで300ms程度(debug)かかっている。double版にしても290ms程度
-(std::vector<std::complex<double> >)getDFTBuffer{
	//refer book "Programmers Guide to Sound"

	std::vector<signed short> &stlbuffer =  _useLowPass ? _stlbuffer_lowpassed : _stlbuffer;
	const int SHORT_MAX = 0xFFFF/2;
	
	Timer timer1; timer1.start();
	//get float values (-1.0 to 1.0, left channel only)
	for(int i = 0 ; i < 1024; i++){
		_samples[i] = ( (double)stlbuffer[(_currentFrame + i)*2] / SHORT_MAX);
	}
	timer1.stop();
	//NSLog(@"normalize loop time = %f[msec]", timer1.result());	//ほとんど時間かかっていない。
	
	CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
	struct tms startTms;
	//clock_t startClock = times(&startTms);
	
	static const double twoPi = 2 * 3.1415926536;	//TODO: replace by library constant definition
	for(int f = 0; f < 1024; f++){
		_result[f] = std::complex<double>(0.0);
		for (int t = 0; t < 1024; t++){
			std::complex<double> val = _samples[t];
			
			//std::complex<double>にキャストしておかないと、operator *がないと言われる。
			//std::operator *(complex<t>, complex<t>)は定義されているが、キャストがきかないため。。
			//piをfloatで定義する手もある。
			_result[f] += val * (std::polar(1.0, -twoPi * f * t / 1024));
		}
	}
	CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
	NSLog(@"DFT for 1024 samples takes %f[msec]", (endTime - startTime)*1000);
	
	struct tms endTms;
	//clock_t endClock = times(&endTms);
	NSLog(@"times(): %ul", (endTms.tms_utime + endTms.tms_stime) - (startTms.tms_utime + startTms.tms_stime));
	printf("sysconf(_SC_CLK_TCK) = %f\n", (double)sysconf(_SC_CLK_TCK));
	return _result;	//absして1024で割るとOKか？
}
/*
-(std::vector<complex>)getFFTBuffer{
	return std::vector<complex>();
}*/

//copy buffer and procees _currentFrame
- (Boolean) renderToBuffer:(UInt32)channels sampleCount:(UInt32)sampleCount data:(void *)data{

	//use lowpassed buffer if _useLowPass
	std::vector<signed short> &stlbuffer = _useLowPass ? _stlbuffer_lowpassed : _stlbuffer; 
	
	//currently loop playback
	unsigned int written_frames = 0;
	unsigned short *pBuffer = reinterpret_cast<unsigned short *>(data);
	
	while(true){
		if (written_frames > sampleCount){
			break;
		}
		
		if(_scrib){
			const unsigned int SCRIB_INTERVAL_SAMPLE = 4100;//0.1sec
			if ((_currentFrame - _scribStartFrame) > SCRIB_INTERVAL_SAMPLE){
				_currentFrame = _scribStartFrame;
			}else if(_currentFrame > [self totalFrameCount]){
				_currentFrame = _scribStartFrame;
			}
		}
		
		//loop handling
		if (_currentFrame*2 > stlbuffer.size()){
			_currentFrame = 0;
			NSLog(@"LOOP");
		}
		
		pBuffer[written_frames*2] = stlbuffer[_currentFrame*2];
		pBuffer[written_frames*2+1] = stlbuffer[_currentFrame*2 + 1];
	
		written_frames++;	
		_currentFrame++;
	}
	
	return YES;
}

//observer
- (void)observeFrameChange:(id) observer forSelector:(SEL) sel{
	_observer = observer;
	_notify_selector = sel;
}

@end
