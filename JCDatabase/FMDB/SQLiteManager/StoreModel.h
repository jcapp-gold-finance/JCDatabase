//
//  StoreModel.h
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//
//使用规则
//primaryKey的类型必须为NSObject类型或int类型
//属性因为需要确认数值类型，不用NSNumber 支持 int NSInteger float double NSString BOOL NSData 数据库类型为INTEGER，REAL，TEXT，BLOB

#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, StroeModelUpdateType) {
//    StroeModelUpdateTypeNone,
//    StroeModelUpdateTypeCreateTable,
//    StroeModelUpdateTypeAddColumn
//};
@class FMDatabase;
@interface StoreModel : NSObject

@property (nonatomic,assign) int mid;//数据库中自增主键 0时代表是新数据

+ (NSString *)primaryKey;
+ (NSArray *)ignoredProperties;
+ (void)selectObjectsWhere:(NSString *)where backArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
+ (void)allObjectsBackArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack;
+ (NSString *)tableName;
- (id)primaryValue;

/**
 获取该类所有 属性->属性类型 字典
 @return 属性->属性类型 字典
 */
+ (NSDictionary *)dicProperties;

@end
