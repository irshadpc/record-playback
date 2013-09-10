//
//  RecordHelper.m
//  AudioQueue
//
//  Created by yuanrui on 13-9-4.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import "RecordHelper.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3 ;

struct AQRecorderState {
    AudioStreamBasicDescription  mDataFormat;                   // 2
    AudioQueueRef                mQueue;                        // 3
    AudioQueueBufferRef          mBuffers[kNumberBuffers];      // 4
    AudioFileID                  mAudioFile;                    // 5
    UInt32                       bufferByteSize;                // 6
    SInt64                       mCurrentPacket;                // 7
    bool                         mIsRunning;                    // 8
};

static void HandleInputBuffer (void *aqData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumPackets,
                               const AudioStreamPacketDescription *inPacketDesc) ;

static void HandleInputBuffer (void                                 *aqData,
                               AudioQueueRef                        inAQ,
                               AudioQueueBufferRef                  inBuffer,
                               const AudioTimeStamp                 *inStartTime,
                               UInt32                               inNumPackets,
                               const AudioStreamPacketDescription   *inPacketDesc)
{
    NSLog(@"is main thread:%u", [NSThread isMainThread]) ;
    AQRecorderState *pAqData = (AQRecorderState *) aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    if (AudioFileWritePackets (pAqData->mAudioFile,
                               false,
                               inBuffer->mAudioDataByteSize,
                               inPacketDesc,
                               pAqData->mCurrentPacket,
                               &inNumPackets,
                               inBuffer->mAudioData) == noErr) {
        pAqData->mCurrentPacket += inNumPackets;
    }
    if (pAqData->mIsRunning == 0)
        return;
    
    AudioQueueEnqueueBuffer (pAqData->mQueue, inBuffer, 0, NULL) ;
}

void DeriveBufferSize (AudioQueueRef                audioQueue,
                       AudioStreamBasicDescription  &ASBDescription,
                       Float64                      seconds,
                       UInt32                       *outBufferSize) ;
void DeriveBufferSize (AudioQueueRef                audioQueue,
                       AudioStreamBasicDescription  &ASBDescription,
                       Float64                      seconds,
                       UInt32                       *outBufferSize) {
    static const int maxBufferSize = 0x50000;                 // 5
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;       // 6
    if (maxPacketSize == 0) {                                 // 7
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               // in Mac OS X v10.5, instead use
                               //   kAudioConverterPropertyMaximumOutputPacketSize
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime =
    ASBDescription.mSampleRate * maxPacketSize * seconds; // 8
    *outBufferSize =
    UInt32 (numBytesForTime < maxBufferSize ?
            numBytesForTime : maxBufferSize);                     // 9
}

@interface RecordHelper ()
{
    AQRecorderState aqData ;
}

@end

@implementation RecordHelper

- (BOOL)isRecording
{
    return aqData.mIsRunning ;
}

- (void)log:(OSStatus)status
{
    char * p = (char *)&status ;
    NSLog(@"%ld, %c%c%c%c", status, p[0], p[1], p[2], p[3]) ;
}

- (void)startRecord:(NSString *)filePath
{
    if (aqData.mIsRunning) {
        return ;
    }
    aqData.mDataFormat.mSampleRate = 44100.0 ;
    aqData.mDataFormat.mFormatID = kAudioFormatMPEG4AAC ;
    aqData.mDataFormat.mFormatFlags = 0 ;
    aqData.mDataFormat.mChannelsPerFrame = 2 ;
    aqData.mDataFormat.mBitsPerChannel = 0 ;
    aqData.mDataFormat.mFramesPerPacket = 1024 ;
    aqData.mDataFormat.mBytesPerFrame = 0 ;// aqData.mDataFormat.mChannelsPerFrame * sizeof (SInt16) ;
    aqData.mDataFormat.mBytesPerPacket = 0 ;// aqData.mDataFormat.mFramesPerPacket * aqData.mDataFormat.mBytesPerFrame ;
    
    OSStatus result = AudioQueueNewInput(&aqData.mDataFormat, HandleInputBuffer, &aqData, NULL, kCFRunLoopCommonModes, 0, &aqData.mQueue) ;
    [self log:result] ;
    
    AudioFileTypeID fileType = kAudioFileAAC_ADTSType ;
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *) [filePath UTF8String], [filePath length], false) ;
    AudioFileCreateWithURL (audioFileURL, fileType, &aqData.mDataFormat, kAudioFileFlags_EraseFile, &aqData.mAudioFile) ;
    
    DeriveBufferSize (aqData.mQueue, aqData.mDataFormat, 0.5, &aqData.bufferByteSize) ;
    aqData.bufferByteSize = 0x8000 ;
    for (int i = 0; i < kNumberBuffers; ++i) {
        result = AudioQueueAllocateBuffer (aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]);
        [self log:result] ;
        result = AudioQueueEnqueueBuffer (aqData.mQueue, aqData.mBuffers[i], 0, NULL);
        [self log:result] ;
    }
    
    result = AudioQueueStart (aqData.mQueue, NULL) ;
    [self log:result] ;
    aqData.mCurrentPacket = 0 ;
    aqData.mIsRunning = true ;
}

- (void)stopRecord
{
    if (!aqData.mIsRunning) {
        return ;
    }
    AudioQueueStop (aqData.mQueue,true) ;
    aqData.mIsRunning = false ;
}

@end
