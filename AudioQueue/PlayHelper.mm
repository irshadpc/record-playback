//
//  PlayHelper.m
//  AudioQueue
//
//  Created by yuanrui on 13-9-5.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import "PlayHelper.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3 ;

struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;
    AudioQueueRef                 mQueue;
    AudioQueueBufferRef           mBuffers[kNumberBuffers];
    AudioFileID                   mAudioFile;
    UInt32                        bufferByteSize;
    SInt64                        mCurrentPacket;
    UInt32                        mNumPacketsToRead;
    AudioStreamPacketDescription  *mPacketDescs;
    bool                          mIsRunning;
} ;

static void HandleOutputBuffer (void * aqData, AudioQueueRef inAQ, AudioQueueBufferRef  inBuffer) ;

static void HandleOutputBuffer (void * aqData, AudioQueueRef inAQ, AudioQueueBufferRef  inBuffer)
{
    AQPlayerState *pAqData = (AQPlayerState *) aqData;
    NSLog(@"Handle output") ;
    if (pAqData->mIsRunning == false)
        return ;
    NSLog(@"Handle output running") ;
    UInt32 numBytesReadFromFile;
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    AudioFileReadPackets (pAqData->mAudioFile, false, &numBytesReadFromFile, pAqData->mPacketDescs,
                          pAqData->mCurrentPacket, &numPackets, inBuffer->mAudioData) ;
    if (numPackets > 0) {
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;
        AudioQueueEnqueueBuffer (
                                 pAqData->mQueue,
                                 inBuffer,
                                 (pAqData->mPacketDescs ? numPackets : 0),
                                 pAqData->mPacketDescs
                                 );
        pAqData->mCurrentPacket += numPackets;
    } else {
        AudioQueueStop (pAqData->mQueue, false) ;
        pAqData->mIsRunning = false ;
        NSLog(@"finish play") ;
    }
}
void DeriveBufferSize (AudioStreamBasicDescription &ASBDesc, UInt32 maxPacketSize, Float64 seconds, UInt32 *outBufferSize, UInt32 *outNumPacketsToRead) ;
void DeriveBufferSize (AudioStreamBasicDescription &ASBDesc, UInt32 maxPacketSize, Float64 seconds, UInt32 *outBufferSize, UInt32 *outNumPacketsToRead) {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    
    if (ASBDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime =
        ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize =
        maxBufferSize > maxPacketSize ?
        maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize)
        *outBufferSize = maxBufferSize;
    else {
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

@interface PlayHelper ()
{
    AQPlayerState aqData ;
}

@end
@implementation PlayHelper

- (BOOL)isPlaying
{
    return aqData.mIsRunning ;
}

- (void)log:(OSStatus)status
{
    char * p = (char *)&status ;
    NSLog(@"%ld, %c%c%c%c", status, p[0], p[1], p[2], p[3]) ;
}

- (void)playAudio:(NSString *)filePath
{
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)[filePath UTF8String], [filePath length], false) ;
    OSStatus state = AudioFileOpenURL (audioFileURL, kAudioFileReadPermission, kAudioFileAAC_ADTSType, &aqData.mAudioFile) ;
    [self log:state] ;
    CFRelease (audioFileURL) ;
    UInt32 dataFormatSize = sizeof(aqData.mDataFormat);
    
    state = AudioFileGetProperty(aqData.mAudioFile, kAudioFilePropertyDataFormat, &dataFormatSize, &aqData.mDataFormat) ;
    [self log:state] ;
    state = AudioQueueNewOutput (&aqData.mDataFormat, HandleOutputBuffer, &aqData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &aqData.mQueue) ;
    [self log:state] ;
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    state = AudioFileGetProperty (aqData.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize) ;
    [self log:state] ;
    
    DeriveBufferSize (aqData.mDataFormat, maxPacketSize, 0.5, &aqData.bufferByteSize, &aqData.mNumPacketsToRead) ;
    
    bool isFormatVBR = (aqData.mDataFormat.mBytesPerPacket == 0 || aqData.mDataFormat.mFramesPerPacket == 0) ;
    if (isFormatVBR) {
        aqData.mPacketDescs = (AudioStreamPacketDescription*) malloc (aqData.mNumPacketsToRead * sizeof (AudioStreamPacketDescription));
    } else {
        aqData.mPacketDescs = NULL;
    }
    
    aqData.mCurrentPacket = 0;
    aqData.mIsRunning = true ;
    for (int i = 0; i < kNumberBuffers; ++i) {
        state = AudioQueueAllocateBuffer (aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]) ;
        [self log:state] ;
        HandleOutputBuffer (&aqData, aqData.mQueue, aqData.mBuffers[i]) ;
    }
    
    state = AudioQueueStart (aqData.mQueue, NULL) ;
    [self log:state] ;
    
    do {
        CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0.25, false) ;
    } while (aqData.mIsRunning) ;
    
    CFRunLoopRunInMode (kCFRunLoopDefaultMode, 1, false) ;
}

- (void)startPlay:(NSString *)filePath
{
    if ([self isPlaying]) {
        return ;
    }
    [NSThread detachNewThreadSelector:@selector(playAudio:) toTarget:self withObject:filePath] ;
}

- (void)stopPlay
{
    if (![self isPlaying]) {
        return ;
    }
    AudioQueueStop(aqData.mQueue, false) ;
}

@end
