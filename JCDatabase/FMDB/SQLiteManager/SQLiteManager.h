//
//  SQLiteManager.h
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//  用于与FMDB解耦

#import <Foundation/Foundation.h>
#import "StoreModel.h"

@interface SQLiteManager : NSObject

+ (instancetype)shareManager;

- (void)addTableWithObject:(StoreModel *)model;
- (void)addColumnWithObject:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType;

- (void)addObject:(StoreModel *)model;
- (void)deleteObject:(StoreModel *)model;
- (void)updateObject:(StoreModel *)model;
- (void)updateObject:(StoreModel *)model byKeys:(NSArray *)arrKeys;
- (void)selectObjectsByObjectName:(NSString *)objectName where:(NSString *)where backArray:(void(^)(NSArray *))backArray;

@end
