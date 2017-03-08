//
//  ViewController.m
//  FMDB
//
//  Created by wenjie hua on 2017/3/6.
//  Copyright © 2017年 jingcheng. All rights reserved.
//

#import "ViewController.h"
#import "testModel.h"
#import "SQLiteManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10000];
    
    for (NSInteger i = 0; i < 10000; i++) {
        testModel *model = [[testModel alloc] init];
        model.tom2 = 32;
        model.tom3 = 0;
        model.tom4 = 19;
        model.tom5 = @"tom3333322";
        model.tom6 = 8.0;
        model.tom7 = 12.44;
        //    model.mid = 2;
        model.tom8 = YES;
        
        [arr addObject:model];
    }
    
//    NSDate *date1 = [NSDate date];
//    for (testModel *model in arr) {
//        [[SQLiteManager shareManager] addObject:model];
////        [[SQLiteManager shareManager] updateObject:model byKeys:@[@"tom6"]];
//    }
//    NSDate *date2 = [NSDate date];
//    NSTimeInterval tOffset = [date2 timeIntervalSinceDate:date1];
//    NSLog(@"用时：%.3f 秒", tOffset);
//
//    
//    NSDate *date3 = [NSDate date];
////    [[SQLiteManager shareManager] deleteObject:model];
//    [[SQLiteManager shareManager] selectObjectsByObjectName:[testModel tableName] where:@"" backArray:^(NSArray *arr) {
//        NSLog(@"%@",arr);
//        NSDate *date4 = [NSDate date];
//        NSTimeInterval tOffset1 = [date4 timeIntervalSinceDate:date3];
//        NSLog(@"用时：%.3f 秒", tOffset1);
//    }];

    [[SQLiteManager shareManager] copy];

}


@end
