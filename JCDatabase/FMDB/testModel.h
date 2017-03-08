//
//  testModel.h
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//

#import "StoreModel.h"
//int NSInteger float double NSString BOOL NSData
@interface testModel : StoreModel

@property (nonatomic,assign) int tom2;
@property (nonatomic,assign) short tom3;
@property (nonatomic,assign) NSInteger tom4;
@property (nonatomic,strong)  NSString *tom5;
@property (nonatomic,assign) float tom6;
@property (nonatomic,assign) double tom7;
@property (nonatomic,assign) BOOL tom8;
@property (nonatomic,assign) NSData *data;

@property (nonatomic,assign) BOOL tom82;


@end
