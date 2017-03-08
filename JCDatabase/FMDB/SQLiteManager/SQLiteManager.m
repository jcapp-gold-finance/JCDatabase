//
//  SQLiteManager.m
//  FMDBTest
//
//  Created by wenjie hua on 2017/3/3.
//  Copyright © 2017年 jingcheng. All rights reserved.
//

#import "SQLiteManager.h"
#import <FMDB.h>
#import "SQLHelper.h"

@interface SQLiteManager()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, assign) BOOL isOpened;

@end

@implementation SQLiteManager
+ (instancetype)shareManager{
    static SQLiteManager *manager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL] init];
    });
    
    return manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return [self shareManager];
}

+ (instancetype)copyWithZone:(struct _NSZone *)zone{
    return [self shareManager];
}

- (instancetype)copy {
    return self;
}

#pragma mark - Public Methods
- (void)addTableWithObject:(StoreModel *)model {
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [wSelf executeUpdate:[SQLHelper createTableSQLWithModel:model] FMDatabase:db arr:nil];
        NSLog(@"建表成功");
    }];
}

- (void)addColumnWithObject:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType {
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([wSelf isTableOK:[[model class] tableName] FMDatabase:db]) {
            //表存在，则更新数据
            NSString *strSQL = [SQLHelper addColumnSQLWithModel:model columnName:columnName columnType:columnType];
            NSLog(@"新增列的SQL : %@",strSQL);
            [wSelf executeUpdate:strSQL FMDatabase:db arr:nil];
        } else {
            //表不存在
            NSLog(@"使用错误，该表不存在");
        }
    }];
}

- (void)addObject:(StoreModel *)model{
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([wSelf isTableOK:[[model class] tableName] FMDatabase:db]) {
            //表存在，则更新数据
            if ([wSelf isModelHadInTable:model FMDatabase:db]){
                //已经存在的一条数据
                NSString *strSQL = [SQLHelper updateSQLWithModel:model];
                [wSelf executeUpdate:strSQL FMDatabase:db arr:nil];
            }else {
                //插入新数据
                NSArray *arrValues;
                NSString *strSQL = [SQLHelper insertSQLWithModel:model insertList:&arrValues];
                [wSelf executeUpdate:strSQL FMDatabase:db arr:arrValues];
            }
        }else {
            //表不存在，先创表，再插入数据
            if ([wSelf executeUpdate:[SQLHelper createTableSQLWithModel:model] FMDatabase:db arr:nil]) {
                NSArray *arrValues;
                NSString *strSQL = [SQLHelper insertSQLWithModel:model insertList:&arrValues];
                [wSelf executeUpdate:strSQL FMDatabase:db arr:arrValues];
            }
        }
    }];
}

// 删数据
- (void)deleteObject:(StoreModel *)model{
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([wSelf isTableOK:[[model class] tableName] FMDatabase:db]) {
            if ([wSelf isModelHadInTable:model FMDatabase:db]){
                NSString *strSQL = [SQLHelper deleteSQLWithModel:model];
                if (strSQL.length > 0) {
                    [wSelf executeUpdate:strSQL FMDatabase:db arr:nil];
                }
            }else {
                NSLog(@"使用错误，该数据不存在");
            }
        }else {
            NSLog(@"使用错误，该表不存在");
        }
    }];
}

// 更新数据
- (void)updateObject:(StoreModel *)model{
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([wSelf isTableOK:[[model class] tableName] FMDatabase:db]) {
            //表存在
            if ([wSelf isModelHadInTable:model FMDatabase:db]){
                //已经存在的一条数据
                NSString *strSQL = [SQLHelper updateSQLWithModel:model];
                [wSelf executeUpdate:strSQL FMDatabase:db arr:nil];
            }else {
                NSLog(@"使用错误，该数据不存在");
            }
        }else {
            NSLog(@"使用错误，该表不存在");
        }
    }];
}


- (void)updateObject:(StoreModel *)model byKeys:(NSArray *)arrKeys{
    __weak typeof(self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([wSelf isTableOK:[[model class] tableName] FMDatabase:db]) {
            //表存在
            if ([wSelf isModelHadInTable:model FMDatabase:db]){
                //已经存在的一条数据
                NSString *strSQL = [SQLHelper updateSQLWithModel:model byKeys:arrKeys];
                [wSelf executeUpdate:strSQL FMDatabase:db arr:nil];
            }else {
                NSLog(@"使用错误，该数据不存在");
            }
        }else {
            NSLog(@"使用错误，该表不存在");
        }
    }];
}

- (void)selectObjectsByObjectName:(NSString *)objectName where:(NSString *)where backArray:(void(^)(NSArray *))backArray{
    Class ObjectClass = NSClassFromString(objectName);
    if (![ObjectClass isSubclassOfClass:[StoreModel class]]) {
        return;
    }

    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *strSQL = [SQLHelper selectObjectsByName:objectName where: where];
        
        if (strSQL.length > 0) {
            FMResultSet *rs = [db executeQuery:strSQL];
            NSDictionary *dic = [ObjectClass dicProperties];
            NSMutableArray *marr = [[NSMutableArray alloc] init];
            while ([rs next]) {
                StoreModel *object = [[ObjectClass alloc] init];
                for (NSString *key in dic.allKeys) {
                    NSString *strType = [dic objectForKey:key];
                    if ([strType hasPrefix:@"T@\"NSData\""]) {
                        [object setValue:[rs dataForColumn:key] forKey:key];
                    }else if ([strType hasPrefix:@"T@\"NSString\""]){
                        [object setValue:[rs stringForColumn:key] forKey:key];
                    }else if ([strType hasPrefix:@"Td"] ){
                        [object setValue:@([rs doubleForColumn:key]) forKey:key];
                    }else if ([strType hasPrefix:@"Tf"]){
                        [object setValue:@([rs doubleForColumn:key]) forKey:key];
                    }else if ([strType hasPrefix:@"Ti"] || [key hasPrefix:@"Tq"] || [key hasPrefix:@"Ts"]){
                        [object setValue:@([rs longLongIntForColumn:key]) forKey:key];
                    }else if ([strType hasPrefix:@"TB"]) {
                        [object setValue:@([rs boolForColumn:key]) forKey:key];
                    }
                }
                [marr addObject:object];
            }
            backArray((NSArray *)marr);
        }
    }];
}

#pragma mark - Private Methods
- (BOOL) isTableOK:(NSString *)tableName FMDatabase:(FMDatabase *)db
{
    FMResultSet *rs = [db executeQuery:[SQLHelper isHaveTable],tableName];
    while ([rs next])
    {
        NSInteger count = [rs intForColumn:@"count"];
        if (0 == count)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) isModelHadInTable:(StoreModel *)model FMDatabase:(FMDatabase *)db{
    if ([[[model class] primaryKey] isEqualToString:@"mid"]) {
        if ([model valueForKey:@"mid"] == 0) {
            return NO;
        }
    }
    NSString *strSQL = [SQLHelper isHaveModelByModel:model];
    if (strSQL.length > 0) {
        FMResultSet *rs = [db executeQuery:strSQL];
        while ([rs next]) {
            return YES;
            break;
        }
    }
    
    return NO;
}

- (BOOL)executeUpdate:(NSString *)sql FMDatabase:(FMDatabase *)db arr:(NSArray *)arr{
    if (sql.length > 0) {
        if (arr.count > 0) {
            return [db executeUpdate:sql withArgumentsInArray:arr];
        }else{
            return [db executeUpdate:sql];
        }
        
    }else{
        return NO;
    }
}




#pragma mark - setter and getter Methods
- (NSString *)dbName{
    if (_dbName == nil) {
        _dbName = @"DaXiangDB.sqlite";
    }
    return _dbName;
}

- (NSString *)path{
    if (_path == nil) {
        //DB绝对路径
        NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        //数据库名字
        _path = [documentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",self.dbName]];
    }
    return _path;
}

- (FMDatabaseQueue *)dbQueue{
    if (_dbQueue == nil) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.path];
    }
    return _dbQueue;
}

@end
