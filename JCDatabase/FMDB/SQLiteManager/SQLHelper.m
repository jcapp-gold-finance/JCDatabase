//
//  SQLHelper.m
//  SQLHelper
//
//  Created by 戴奕 on 2017/3/3.
//  Copyright © 2017年 戴奕. All rights reserved.
//

#import "SQLHelper.h"
#import "StoreModel.h"
#import <objc/runtime.h>

@implementation SQLHelper

// 创建表
+ (NSString *)createTableSQLWithModel:(StoreModel *)model {
    if ([[[model class] primaryKey] isEqualToString:@"mid"]) {
        NSMutableString *mStr = [NSMutableString stringWithFormat:@"create table %@ (mid INTEGER PRIMARY KEY AUTOINCREMENT",[[model class] tableName]];
        NSDictionary *dicProperties = [model.class dicProperties];
            for (NSString *key in dicProperties.allKeys) {
                // 属性类型
                NSString *strType = [dicProperties objectForKey:key];
                // 数据库类型映射
                NSString *type = [self typeFromKey:strType];
                if (type.length > 0) {
                    [mStr appendFormat:@",%@ %@",key,type];
                }
            }
            [mStr appendString:@")"];
        return mStr;
    }else {
        NSDictionary *dicProperties = [model.class dicProperties];
        NSString *strPrimaryKey = [[model class] primaryKey];
        NSString *strType = [dicProperties objectForKey:strPrimaryKey];
        
        NSString *type = [self typeFromKey:strType];
        NSMutableString *mStr = [NSMutableString stringWithFormat:@"create table %@ (",[[model class] tableName]];
        if (type.length > 0) {
            [mStr appendFormat:@"%@ %@ primary key",strPrimaryKey,type];
        }
        
        for (NSString *key in dicProperties.allKeys) {
            if ([key isEqualToString:strPrimaryKey]) {
                continue;
            }
            NSString *strType = [dicProperties objectForKey:key];
            NSString *type = [self typeFromKey:strType];
            if (type.length > 0) {
                [mStr appendFormat:@",%@ %@",key,type];
            }
        }
        [mStr appendString:@")"];
        return mStr;
    }
}

// 删除表
+ (NSString *)dropTableSQLWithModel:(StoreModel *)model {
    return nil;
}

// 清空表
+ (NSString *)truncateTableSQLWithModel:(StoreModel *)model {
    NSMutableString *mstr = [NSMutableString stringWithFormat:@"DELETE FROM %@",[[model class] tableName]];
    return mstr;
}

+ (NSString *)truncateTableSQLWithModelName:(NSString *)modelName{
    NSMutableString *mstr = [NSMutableString stringWithFormat:@"DELETE FROM %@",modelName];
    return mstr;
}

// 增加列
+ (NSString *)addColumnSQLWithModel:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType {
    if (columnName == nil || columnName.length == 0 || columnType == nil || columnType.length == 0) {
        return nil;
    }
    NSMutableString *mStr = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", [[model class] tableName], columnName, [self typeFromKey:columnType]];
    return mStr;
}

// 查询数据
+ (NSString *)selectSQLWithModel:(StoreModel *)model {
    return [self selectObjectsByName:[[model class] tableName] where:nil];
}

// 新增数据
+ (NSString *)insertSQLWithModel:(StoreModel *)model insertList:(NSArray **)list {
    NSDictionary *dicProperties = [model.class dicProperties];
    if (dicProperties.allKeys.count > 0) {
        NSMutableString *mstr = [NSMutableString stringWithFormat:@"INSERT INTO %@ ",[[model class] tableName]];
        NSMutableString *subStr1 = [[NSMutableString alloc] initWithString:@"("];
        NSMutableString *subStr2 = [[NSMutableString alloc] initWithString:@"("];
        NSMutableArray *marr = [[NSMutableArray alloc] init];
        for (NSString *key in dicProperties.allKeys) {
            if ([model valueForKey:key] != nil) {
                [subStr1 appendFormat:@"%@ ,",key];
                [subStr2 appendString:@"? ,"];
                [marr addObject:[model valueForKey:key]];
            }
        }
        if ([subStr1 hasSuffix:@","] &&[subStr2 hasSuffix:@","] ) {
            [subStr1 replaceCharactersInRange:NSMakeRange(subStr1.length - 1, 1) withString:@")"];
            [subStr2 replaceCharactersInRange:NSMakeRange(subStr2.length - 1, 1) withString:@")"];
            [mstr appendFormat:@"%@ VALUES %@",subStr1,subStr2];
            *list = marr;
            return mstr;
        }else {
            return nil;
        }
        
    }else {
        return nil;
    }
}

// 删除数据
+ (NSString *)deleteSQLWithModel:(StoreModel *)model {
    id value = [model valueForKey:[[model class] primaryKey]];
    if (value != nil) {
        NSString *key = [[model class] primaryKey];
        NSMutableString *mstr = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'",[[model class] tableName],key,value];
        return mstr;
    }
    return nil;
}

// 修改数据
+ (NSString *)updateSQLWithModel:(StoreModel *)model{
    return [self updateSQLWithModel:model byKeys:nil];
}

+ (NSString *)updateSQLWithModel:(StoreModel *)model byKeys:(NSArray *)keys{
    NSDictionary *dicProperties = [model.class dicProperties];
    if (dicProperties.allKeys.count > 0) {
        NSMutableString *mstr = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[[model class] tableName]];
        for (NSString *key in dicProperties.allKeys) {
            if ([key isEqualToString:[[model class] primaryKey]]) {
                continue;
            }
            if ([model valueForKey:key] != nil && (keys == nil || [keys containsObject:key])) {
                [mstr appendFormat:@" %@ = '%@',",key,[model valueForKey:key]];
            }
        }
        
        if ([mstr containsString:@"="]) {
            
            if ([mstr hasSuffix:@","]) {
                id value = [model valueForKey:[[model class] primaryKey]];
                NSString *key = [[model class] primaryKey];
                [mstr replaceCharactersInRange:NSMakeRange(mstr.length - 1, 1) withString:[NSString stringWithFormat:@"WHERE %@ = '%@'",key,value]];
            }
            return mstr;
        }else {
            return nil;
        }
    }else {
        return nil;
    }
}

+ (NSString *)isHaveTable{
    return @"SELECT count(*) as 'count' from sqlite_master where type ='table' and name = ?";
}
+ (NSString *)isHaveModelByModel:(StoreModel *)model{
    NSString *key = [[model class] primaryKey];
    id value = [model valueForKey:key];
    return [NSString stringWithFormat:@"select * from %@ where %@ = '%@'",[[model class] tableName],key,value];
}

+ (NSString *)selectObjectsByName:(NSString *)objectName where:(NSString *)where{
    if (where.length > 0) {
        return [NSString stringWithFormat:@"select * from %@ %@",objectName,where];
    }else{
        return [NSString stringWithFormat:@"select * from %@",objectName];
    }
   
}

+ (NSString *)typeFromKey:(NSString *)key{
    if ([key hasPrefix:@"T@\"NSData\""]) {
        return @"BLOB";
    }else if ([key hasPrefix:@"T@\"NSString\""]){
        return @"TEXT";
    }else if ([key hasPrefix:@"Td"] || [key hasPrefix:@"Tf"]){
        return @"REAL";
    }else if ([key hasPrefix:@"Ti"] || [key hasPrefix:@"Tq"] || [key hasPrefix:@"Ts"]){
        return @"INTEGEER";
    }else if ([key hasPrefix:@"TB"]) {
        return @"BOOLEAN";
    }else{
        return nil;
    }
}

@end
