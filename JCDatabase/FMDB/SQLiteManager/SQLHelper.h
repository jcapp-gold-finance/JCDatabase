//
//  SQLHelper.h
//  SQLHelper
//
//  Created by 戴奕 on 2017/3/3.
//  Copyright © 2017年 戴奕. All rights reserved.
//

#import <Foundation/Foundation.h>
@class StoreModel;

@interface SQLHelper : NSObject


// 创建表
+ (NSString *)createTableSQLWithModel:(StoreModel *)model;

// 删除表
+ (NSString *)dropTableSQLWithModel:(StoreModel *)model;

// 清空表
+ (NSString *)truncateTableSQLWithModel:(StoreModel *)model;

// 增加列
+ (NSString *)addColumnSQLWithModel:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType;

// 查询数据
+ (NSString *)selectSQLWithModel:(StoreModel *)model;

// 新增数据
+ (NSString *)insertSQLWithModel:(StoreModel *)model insertList:(NSArray **)list;

// 删除数据
+ (NSString *)deleteSQLWithModel:(StoreModel *)model;

// 修改数据
+ (NSString *)updateSQLWithModel:(StoreModel *)model;

+ (NSString *)updateSQLWithModel:(StoreModel *)model byKeys:(NSArray *)keys;

+ (NSString *)selectObjectsByName:(NSString *)objectName where:(NSString *)where;

+ (NSString *)isHaveModelByModel:(StoreModel *)model;

+ (NSString *)isHaveTable;

+ (NSString *)typeFromKey:(NSString *)key;

@end
