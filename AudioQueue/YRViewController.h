//
//  YRViewController.h
//  AudioQueue
//
//  Created by yuanrui on 13-9-4.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecordHelper.h"
#import "PlayHelper.h"

@interface YRViewController : UIViewController
{
    RecordHelper * recordHelper ;
    PlayHelper * playHelper ;
}

@property (nonatomic, retain) IBOutlet UITableView * tableView ;

@property (nonatomic, assign) NSUInteger index ;
@property (nonatomic, retain) NSString * detail ;
@property (nonatomic, copy) void (^completeBlock)(NSUInteger) ;

@end
