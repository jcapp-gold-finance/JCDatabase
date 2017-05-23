//
//  StoreModel.m
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//

#import "StoreModel.h"
#import "SQLiteManager.h"
#import <objc/runtime.h>

static NSString * const plistName = @"DaXiangModel.plist";
static NSString * const modelVersionKey = @"versionKey";
static NSString * const modelPropertiesKey = @"propertiesKey";

static NSString *localPropertiesPath = nil;
// 保存本地的模型属性列表
static NSMutableDictionary *mdicLocalProperties = nil;

@implementation StoreModel

+ (void)initialize {
    if (self.class != NSClassFromString(@"StoreModel")) {
        [self p_updateTableMap];
    }
}

#pragma mark - Private Methods
+ (void)p_updateTableMap {
    // 检查模型是否有更新
    NSString *classStr = NSStringFromClass(self);
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    if (self.p_mdicLocalProperties[classStr] == nil) {      // 本地没有该类
        NSLog(@"类是新增的，开始建表");
        // 建表
        StoreModel *model = [[self alloc] init];
        [[SQLiteManager shareManager] addTableWithObject:model FMDatabase:nil rollBack:nil];
        
        // 建表成功 直接插入plist
        self.p_mdicLocalProperties[classStr] = @{
                                                 modelVersionKey : appVersion,
                                                 modelPropertiesKey : [self p_dicPropertiesWithCache:NO]
                                                 };
        [self.p_mdicLocalProperties writeToFile:self.p_localPropertiesPath atomically:YES];
        
    } else {        // 本地有该类，需要进行properties对比
        // 先进行model版本判断
        NSString *modelVersion = self.p_mdicLocalProperties[classStr][modelVersionKey];
        if (![modelVersion isEqualToString:appVersion]) {
            NSLog(@"app版本与model版本不同，开始检查model结构是否有变更");
            
            NSDictionary *dicLocalProperties = self.p_mdicLocalProperties[classStr][modelPropertiesKey];
            NSDictionary *dicProperties = [self p_dicPropertiesWithCache:NO];
            
            void(^syncPlistBlock)() = ^{
                // 更新plist
                self.p_mdicLocalProperties[classStr] = @{
                                                         modelVersionKey : appVersion,
                                                         modelPropertiesKey : dicProperties
                                                         };
                [self.p_mdicLocalProperties writeToFile:self.p_localPropertiesPath atomically:YES];
            };
            
            if (![dicLocalProperties isEqualToDictionary:dicProperties]) {
                NSLog(@"类结构有变更，开始更新数据库对应表结构（暂时只处理新增列的情况）");
                
                NSSet *setLocalP = [NSSet setWithArray:dicLocalProperties.allKeys];
                NSSet *setP = [NSSet setWithArray:dicProperties.allKeys];
                // 新增的key值
                NSMutableSet *msetP = [setP mutableCopy];
                [msetP minusSet:setLocalP];
                
                // 列新增
                NSMutableDictionary *mdicAdd = [NSMutableDictionary dictionary];
                [msetP enumerateObjectsUsingBlock:^(NSString *key, BOOL * _Nonnull stop) {
                    mdicAdd[key] = dicProperties[key];
                }];
                
                // 更新数据库表结构，暂时只管新增列
                StoreModel *model = [[self alloc] init];
                [mdicAdd enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
                    [[SQLiteManager shareManager] addColumnWithObject:model columnName:key columnType:value FMDatabase:nil rollBack:nil];
                }];
                
                // 更新plist
                syncPlistBlock();
            } else {
                NSLog(@"类结构没有变动，无需操作数据库");
                // 更新plist
                syncPlistBlock();
            }
        } else {
            NSLog(@"同一个版本，无需更新");
        }
    }
}

+ (NSMutableDictionary *)p_mdicLocalProperties {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 本地model文件取出
        mdicLocalProperties = [NSMutableDictionary dictionaryWithContentsOfFile:self.p_localPropertiesPath];
        if (mdicLocalProperties == nil) {
            mdicLocalProperties = [NSMutableDictionary dictionary];
        }
    });
    return mdicLocalProperties;
}

// plist文件路径
+ (NSString *)p_localPropertiesPath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localPropertiesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:plistName];
    });
    return localPropertiesPath;
}

+ (NSDictionary *)p_dicPropertiesWithCache:(BOOL)cache {
    if (cache) {
        // 判断缓存中是否有该模型属性列表
        NSDictionary *dicProperties = [self.p_mdicLocalProperties objectForKey:NSStringFromClass(self.class)][modelPropertiesKey];
        if (dicProperties != nil) {
            return dicProperties;
        } else {
            return [self p_dicPropertiesFromModelName:[self.class tableName]];
        }
    } else {
        return [self p_dicPropertiesFromModelName:[self.class tableName]];
    }
}

// 直接获取类属性列表
+ (NSDictionary *)p_dicPropertiesFromModelName:(NSString  *)modelName {
    Class cls = NSClassFromString(modelName);
    // 获取属性列表
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    
    NSMutableDictionary *mdicProperty = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < count; i ++) {
        objc_property_t property = properties[i];
        
        const char *name = property_getName(property);
        const char *type = property_getAttributes(property);
        
        NSString *ocName = [NSString stringWithUTF8String:name];
        NSString *ocType = [NSString stringWithUTF8String:type];
        //排除mid属性
        if ([ocName isEqualToString:@"mid"]) {
            continue;
        }
        //排除model中不用存到数据库中的属性
        if (![[cls ignoredProperties] containsObject:ocName]) {
            [mdicProperty setObject:ocType forKey:ocName];
        }
    }
    free(properties);
    return [mdicProperty copy];
}

#pragma mark - Public Methods
+ (NSString *)primaryKey{
    return @"mid";
}

+ (NSArray *)ignoredProperties{
    return @[];
}

+ (NSString *)tableName{
    return NSStringFromClass([self class]);
}

+ (void)selectObjectsWhere:(NSString *)where backArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    [[SQLiteManager shareManager] selectObjectsByObjectName:[self tableName] where:where backArray:^(NSArray *arr,FMDatabase *db,BOOL *rollBack){
        backArray(arr,db,rollBack);
    } FMDatabase:db rollBack:rollBack];
}
+ (void)allObjectsBackArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    [[SQLiteManager shareManager] selectObjectsByObjectName:[self tableName] where:nil backArray:^(NSArray *arr,FMDatabase *db,BOOL *rollBack) {
        backArray(arr,db,rollBack);
    } FMDatabase:db rollBack:rollBack];
}

- (id)primaryValue{
    id value = [self valueForKey:[[self class] primaryKey]];
    if ([value isKindOfClass:[NSObject class]]) {
        return value;
    }else {
        value = @((long)value);
        return value;
    }
}

// 根据model获取属性列表
+ (NSDictionary *)dicProperties {
    return [self p_dicPropertiesWithCache:YES];
}

@end
