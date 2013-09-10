//
//  YRViewController.m
//  AudioQueue
//
//  Created by yuanrui on 13-9-4.
//  Copyright (c) 2013年 yuanrui. All rights reserved.
//

#import "YRViewController.h"
#import <mach/mach_time.h>

@interface YRViewController ()
{
    NSMutableArray * mArray ;
}

@end

@implementation YRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if (!recordHelper) {
        recordHelper = [[RecordHelper alloc] init] ;
    }
    if (!playHelper) {
        playHelper = [[PlayHelper alloc] init] ;
    }
    if (!mArray) {
        mArray = [[NSMutableArray alloc] init] ;
    }
    [self reloadData] ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated] ;
    /*
    NSArray * mArray1 = [NSArray arrayWithObjects:[NSMutableString stringWithString:@"a"],@"b",@"c",nil] ;
    NSArray * mArrayCopy2 = [mArray1 copy] ;
    NSLog(@"mArray1 retain count: %d",[mArray1 retainCount]) ;
    NSMutableArray * mArrayMCopy1 = [mArray1 mutableCopy] ;
    NSLog(@"mArray1 retain count: %d",[mArray1 retainCount]) ;
    
    NSMutableString * mStr = [NSMutableString stringWithFormat:@"haha"] ;
    NSString * str = [mStr copy] ;
    
    NSArray * arr = @[[NSMutableString stringWithString:@"mutiable"], @"todo"] ;
    NSArray * arr1 = [arr copy] ;
    NSArray * arr2 = [[NSArray alloc] initWithArray:arr copyItems:YES] ;
    NSMutableString * str1 = arr1[0] ;
    [str1 appendString:@".txt"] ;
//    NSMutableString * str2 = arr2[0] ; // error
//    [str2 appendString:@".txt"] ;
    NSLog(@"%@", arr) ;
    NSLog(@"%@", arr1) ;
    NSLog(@"%@", arr2) ;
    
    NSLog(@"retain count:%u", [self retainCount]) ;
    [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        self.index = idx ;
        NSLog(@"retain count:%u", [self retainCount]) ;
    }] ;
    */
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"record" style:UIBarButtonItemStylePlain target:self action:@selector(record:)] autorelease] ;
}

- (NSString *)path:(uint64_t)u64
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * filePath = pathArray[0] ;
    return [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%qu", u64]] ;
}

- (void)record:(id)sender
{
    uint64_t time = mach_absolute_time() ;
    NSString * filePath = [self path:time] ;
    [recordHelper startRecord:filePath] ;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"stop" style:UIBarButtonItemStylePlain target:self action:@selector(stopRecord:)] autorelease] ;
}

- (void)stopRecord:(id)sender
{
    [recordHelper stopRecord] ;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"record" style:UIBarButtonItemStylePlain target:self action:@selector(record:)] autorelease] ;
    [self reloadData] ;
}

- (void)reloadData
{
    [mArray removeAllObjects] ;
    
    NSArray * pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docsDir = pathArray[0] ;
    NSFileManager * localFileManager=[[NSFileManager alloc] init] ;
    NSDirectoryEnumerator * dirEnum = [localFileManager enumeratorAtPath:docsDir] ;
    
    NSString * file = nil ;
    while ((file = [dirEnum nextObject])) {
        NSString * filePath = [docsDir stringByAppendingPathComponent:file] ;
        [mArray addObject:filePath] ;
    }
    [_tableView reloadData] ;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![playHelper isPlaying]) {
        [playHelper startPlay:mArray[indexPath.row]] ;
    } else {
        [playHelper stopPlay] ;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [mArray count] ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * str = @"reuse" ;
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:str] ;
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:str] autorelease] ;
    }
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail ;
    cell.textLabel.text = mArray[indexPath.row] ;
    return cell ;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES ;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString * path = mArray[indexPath.row] ;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:path error:nil] ;
        if (result) {
            [mArray removeObjectAtIndex:indexPath.row] ;
            [_tableView reloadData] ;
        }
    }
}

@end
