//
//  SQLiteManager.h
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//  用于与FMDB解耦

#import <Foundation/Foundation.h>
#import "StoreModel.h"

@class FMDatabase;

@interface SQLiteManager : NSObject

+ (instancetype)shareManager;

- (void)addTableWithObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)addColumnWithObject:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;

- (void)addObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)deleteObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)updateObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)updateObject:(StoreModel *)model byKeys:(NSArray *)arrKeys FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)deleteAllName:(NSString *)modelName FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
- (void)selectObjectsByObjectName:(NSString *)objectName where:(NSString *)where backArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;

@end
