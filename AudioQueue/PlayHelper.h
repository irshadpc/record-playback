//
//  PlayHelper.h
//  AudioQueue
//
//  Created by yuanrui on 13-9-5.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayHelper : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying ;

- (void)startPlay:(NSString *)filePath ;
- (void)stopPlay ;

@end
