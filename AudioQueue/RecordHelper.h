//
//  RecordHelper.h
//  AudioQueue
//
//  Created by yuanrui on 13-9-4.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordHelper : NSObject

@property (nonatomic, assign, readonly) BOOL isRecording ;

- (void)startRecord:(NSString *)filePath ;
- (void)stopRecord ;

@end
