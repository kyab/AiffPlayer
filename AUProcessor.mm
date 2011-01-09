//
//  AUProcessor.m
//  AiffPlayer
//
//  Created by koji on 10/12/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <AudioUnit/AudioUnit.h>
#include <AudioUnit/AUComponent.h>

#import "AUProcessor.h"
#import "MacRuby/MacRuby.h"
#include "util.h"

AudioUnit gOutputUnit;

int gCount = 0;
OSStatus MyRender( void                        *inRefCon,
				  AudioUnitRenderActionFlags  *ioActionFlags,
				  const AudioTimeStamp        *inTimeStamp,
				  UInt32                      inBusNumber,
				  UInt32                      inNumberFrames,
				  AudioBufferList             *ioData
				  ){
	
	/*
	//NSLog(@"MyRender");
	if ((gCount % 100) == 0){
		NSLog(@"MyRender," 
			  "%f bus number = %u, frames = %u,"
			  "ratescalar = %u", 
			  inTimeStamp->mSampleTime, 
			  inBusNumber, 
			  inNumberFrames,
			  inTimeStamp->mRateScalar);
		
		NSLog(@"buffer info: mNumberBuffers = %u,"
			  "channels = %u,"
			  "dataByteSize=%u\n", 
			  ioData->mNumberBuffers,
			  ioData->mBuffers[0].mNumberChannels,
			  ioData->mBuffers[0].mDataByteSize);		//16bit,2chの場合はinNumberFrames*4
	}
	gCount++;
	
	UInt32 sampleNum = inNumberFrames;	//in my case
	SInt16 *pBuffer =  (SInt16 *)ioData->mBuffers[0].mData;
	
	
	for(UInt32 i = 0; i< sampleNum; i++){
		int index =  i*2;
		SInt16 sample = 0;//gSinGenerator.gen2();
		pBuffer[index] = sample;
		pBuffer[index+1] = sample;
	}
	 
	return noErr;
	 */
	
	//calling back to AUProcessor::renderCallback
	AUProcessor *processor = (AUProcessor *)inRefCon;
	return [processor renderCallback:ioActionFlags :inTimeStamp :inBusNumber :inNumberFrames :ioData];

}


void logComponentDescription(Component comp, ComponentDescription *pDesc){
	//getting component information
	Handle hComponentName = NewHandle(32);
	Handle hComponentInfo = NewHandle(128);
	OSErr err = GetComponentInfo(comp,
						   pDesc,
						   hComponentName,
						   hComponentInfo,
						   NULL);
	if (noErr == err){
		CFStringRef componentNameRef ;
		componentNameRef = CFStringCreateWithPascalString(
														  NULL, (const unsigned char *)*hComponentName,
														  kCFStringEncodingMacRoman);
		CFStringRef componentInfoRef ;
		componentInfoRef = CFStringCreateWithPascalString(
														  NULL, (const unsigned char *)*hComponentInfo,
														  kCFStringEncodingMacRoman);
		
		NSLog(@"name:%@(%@)", componentNameRef, componentInfoRef);
	}else{
		printf("GetComponentInfo err=%ld\n", (long)err);
	}
}

#define SUCCEEDED(result) (result == noErr)
#define FAILED(result) (result != noErr)
#define LOGENTER	NSLog(@"enter %@()", NSStringFromSelector(_cmd))

@implementation AUProcessor

- (id) init{
	m_aiff = [[Aiff alloc] init];
	return self;
}

- (Aiff *)aiff{
	return m_aiff;
}

- (void) listOutputDevices{
	
	//CAPlayThroughのAudioDeviceListを参考にした。
	
	NSLog(@"AuProcessor::%@()", NSStringFromSelector(_cmd));
	
	/////////////////////
	//デバイスのリストを取得
	OSErr result;
	UInt32 propSize;
	result = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,&propSize,NULL);

	printf("propSize = %u\n", (unsigned int)propSize);
	if (FAILED(result)){
		printf("failed to get device list = %d\n", result);
		return;
	}
	
	int nDevices = propSize / sizeof(AudioDeviceID);
	AudioDeviceID *deviceIDs = new AudioDeviceID[nDevices];
	result = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,&propSize,deviceIDs);
	
	if (FAILED(result)){
		printf("failed to get device list @second call = %d\n", result);
		return;
	}
	
	
	//それぞれのデバイスについて、名前、バッファリストを取得。
	for (int i = 0 ; i < nDevices ; i++){
		UInt32 fakeSize = 256;
		char name[256];
		
		//名前を取得
		result = AudioDeviceGetProperty( deviceIDs[i], 0, 0/*output*/,kAudioDevicePropertyDeviceName, &fakeSize, name);
		printf("%d:%s\n", i, name);
		
		//Outputのみを抽出するには、kAudioDevicePropertyStreamConfigurationを使って更に絞り込む
		
		//バッファリストを取得
		result = AudioDeviceGetPropertyInfo( deviceIDs[i], 0, 0,kAudioDevicePropertyStreamConfiguration, 
											&propSize, NULL);
		if (SUCCEEDED(result)){
			//AudioBufferListは可変長構造体なので、少々面倒なことをする。
			AudioBufferList *bufList = (AudioBufferList *)malloc(propSize);
			result = AudioDeviceGetProperty( deviceIDs[i], 0, 0,kAudioDevicePropertyStreamConfiguration, 
											&propSize, bufList);	
			if (FAILED(result)){
				printf("faild to obrain buffer list = %d \n",result);
				continue;
			}

			NSLog(@"%s\n",@encode(AudioStreamRangedDescription));
			
			Byte *point = (Byte *)bufList;
			do{
				AudioBufferList *current = (AudioBufferList *)point;
				
				if (current ->mNumberBuffers == 0){
					printf("\t no buffer for output\n");
					//even if mNumberBuffers = 0 , propSize at least occupy sizeof(AudioBufferList = 8))
					point += sizeof(AudioBufferList);
					continue;
				}
				
				printf("\t%u buffer found\n", (unsigned int)current->mNumberBuffers);
				for (int i = 0; i < current->mNumberBuffers; i++){
					printf("\t\t %u channels\n", (unsigned int)current->mBuffers[i].mNumberChannels);
				}

				point += sizeof(AudioBufferList) + sizeof(AudioBuffer) * (current->mNumberBuffers - 1);
			
			}while( point < (Byte *)bufList + propSize );
			free(bufList);
		}
		
		
	}
	
	delete [] deviceIDs;
									  
}

- (void) initCoreAudio{

	NSLog(@"initCoreAudio");
	
		
	ComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_DefaultOutput; //ユーザが指定したデフォルトの出力デバイスを使う場合。
	//desc.componentSubType = kAudioUnitSubType_HALOutput;	//AudioDeviceを明示的に指定する場合
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;		//Always Zero
	desc.componentFlagsMask = 0;	//Always Zero
	
	Component comp = FindNextComponent(NULL, &desc);
	if (comp == NULL){
		printf("FindNextComponent failed\n");
		return;
	}
	
	logComponentDescription(comp,&desc);
	
	OSStatus err = OpenAComponent(comp, &gOutputUnit);
	//AudioComponentInstanceNewを使っても良い(10.6以降)
	if (gOutputUnit == NULL){
		printf("OpenAComponent failed = %ld\n", (long)err);
		return ;
	}
	
	NSLog(@"succeeded to Open\n");
	
	[self setFormat];
	[self setCallback];
		
	return;
}

-(void) start{
	LOGENTER;
	OSStatus err = AudioUnitInitialize(gOutputUnit);
	if (FAILED(err)){
		NSLog(@"failed to initialize Output AU err=%d(%s)", err,GetMacOSStatusErrorString(err));
		return;
	}
	
	err = AudioOutputUnitStart(gOutputUnit);
	if(FAILED(err)){
		NSLog(@"failed to start Output AU err = %d(%s)", err,GetMacOSStatusErrorString(err));
		return;
	}
	
	NSLog(@"gOutputUnit successfully started\n");
}

-(void) stop{
	LOGENTER;
	OSStatus err = AudioOutputUnitStop(gOutputUnit);
	if (FAILED(err)){
		NSLog(@"failed to stop Output AU err = %d(%s)", err, GetMacOSStatusErrorString(err));
		return;
	}
	
	err = AudioUnitUninitialize(gOutputUnit);
	if (FAILED(err)){
		NSLog(@"failed to stop Uninitialize AU err = %d(%s)", err, GetMacOSStatusErrorString(err));
		return;
	}
	
	NSLog(@"stopped\n");
}

NSString *EnumToFOURCC(UInt32 val){
	char cc[5];
	cc[4] = '\0';
	
	char *p = (char *)&val;
	cc[0] = p[3];
	cc[1] = p[2];
	cc[2] = p[1];
	cc[3] = p[0];
	NSString *ret = [NSString stringWithUTF8String:cc];
	
	
	return ret;
}

- (void) setFormat{
	UInt32 size;
	Boolean outWritable = false;
	OSStatus result = noErr;
	
	
	result = AudioUnitGetPropertyInfo(gOutputUnit,
											   kAudioUnitProperty_StreamFormat,
											   kAudioUnitScope_Input,	//au's input
											   0,		//output bus
											   &size,
											   &outWritable);
	if (result == noErr){
		printf("size = %u\n", (unsigned int)size);
		if (outWritable == YES){
			printf("writable\n");
		}else{
			printf("read only\n");
		}
	}
	
	AudioStreamBasicDescription streamDescription;
	
	printf("sizeof AudioStreamBasicDescription = %lu\n", sizeof(AudioStreamBasicDescription));
	
	result = AudioUnitGetProperty(gOutputUnit, 
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input, 
								  0,
								  &streamDescription,
								  &size);
	if (noErr == result){
		printf("format are obtained now dumping %p\n", &streamDescription);
		dump_struct(streamDescription);
	}
	NSLog(@"identifier = %@\n",EnumToFOURCC(streamDescription.mFormatID));
	
	//44100,16bit, stereoにする
	streamDescription.mSampleRate = 44100.0;
	streamDescription.mFormatID = kAudioFormatLinearPCM;
	streamDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | 
									   kLinearPCMFormatFlagIsPacked    	;
	streamDescription.mBytesPerPacket = 4;
	streamDescription.mFramesPerPacket = 1;
	streamDescription.mBytesPerFrame = 4;
	streamDescription.mChannelsPerFrame = 2;
	streamDescription.mBitsPerChannel = 16;	//例えば17にしてもSet,Initialize,Startまでは成功するんだけど、再生できない。
	
	
	result = AudioUnitSetProperty(gOutputUnit,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Input,0,
								  		&streamDescription,
								  sizeof(streamDescription));
	
	if (FAILED(result)){
		printf("!failed to set format err= %d\n",(int)result);
		return;
	}
	
	printf("succeeded to set format\n");

	//RenderSinを参考にしてコールバックの設定と再生をしてみる。	
}

-(void) setCallback{
	
	AURenderCallbackStruct callBackInfo;
	callBackInfo.inputProc = MyRender;
	callBackInfo.inputProcRefCon = self;
	
	OSStatus ret = AudioUnitSetProperty(gOutputUnit, 
										kAudioUnitProperty_SetRenderCallback,
										kAudioUnitScope_Input,		//outputにしても成功する
										0,//output bus
										&callBackInfo,
										sizeof(callBackInfo));
	if (FAILED(ret)){
		printf("failed to set callback = %d\n",(int)ret);
	}
	
	printf("succeeded to set callback\n");
		
}


- (Boolean)loadAiff:(NSString *)fileName{
	[m_aiff loadFile:fileName];
	return YES;
}

- (OSStatus) renderCallback:(AudioUnitRenderActionFlags *)ioActionFlags :(const AudioTimeStamp *) inTimeStamp:
(UInt32) inBusNumber: (UInt32) inNumberFrames :(AudioBufferList *)ioData{
	//NSLog(@"MyRender");
	if ((gCount % 100) == 0){
		NSLog(@"MyRender," 
			  "%f bus number = %u, frames = %u,"
			  "ratescalar = %u", 
			  inTimeStamp->mSampleTime, 
			  inBusNumber, 
			  inNumberFrames,
			  inTimeStamp->mRateScalar);
		
		NSLog(@"buffer info: mNumberBuffers = %u,"
			  "channels = %u,"
			  "dataByteSize=%u\n", 
			  ioData->mNumberBuffers,
			  ioData->mBuffers[0].mNumberChannels,
			  ioData->mBuffers[0].mDataByteSize);		//16bit,2chの場合はinNumberFrames*4
	}
	gCount++;
	
	UInt32 channels = ioData->mBuffers[0].mNumberChannels;
	UInt32 sampleNum = inNumberFrames;	//in my case
	void *pBuffer =  (SInt16 *)ioData->mBuffers[0].mData;
	
	[m_aiff renderToBuffer:channels
			   sampleCount:sampleNum
					  data:pBuffer];

	return noErr;
}

@end
