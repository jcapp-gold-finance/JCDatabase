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
- (void)addTableWithObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self addTableWithObject2:model FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf addTableWithObject2:model FMDatabase:db rollBack:rollback];
        }];

    }
}

- (void)addColumnWithObject:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self addColumnWithObject2:model columnName:columnName columnType:columnType FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf addColumnWithObject2:model columnName:columnName columnType:columnType FMDatabase:db rollBack:rollback];
        }];
    }
}

- (void)addObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self addObject2:model FMDatabase:db rollBack:rollBack];
    }else {
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf addObject2:model FMDatabase:db rollBack:rollback];
        }];
    }
}

// 删数据
- (void)deleteObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self deleteObject2:model FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf deleteObject2:model FMDatabase:db rollBack:rollback];
        }];
    }
}

- (void)deleteAllName:(NSString *)modelName FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    Class ObjectClass = NSClassFromString(modelName);
    if (![ObjectClass isSubclassOfClass:[StoreModel class]]) {
        return;
    }
    
    if (db) {
        [self deleteAllName2:modelName FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf deleteAllName2:modelName FMDatabase:db rollBack:rollback];
        }];
    }
}

// 更新数据
- (void)updateObject:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self updateObject2:model FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf updateObject2:model FMDatabase:db rollBack:rollback];
        }];
    }
}


- (void)updateObject:(StoreModel *)model byKeys:(NSArray *)arrKeys FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if (db) {
        [self updateObject2:model byKeys:arrKeys FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf updateObject2:model byKeys:arrKeys FMDatabase:db rollBack:rollback];
        }];

    }
}



- (void)selectObjectsByObjectName:(NSString *)objectName where:(NSString *)where backArray:(void(^)(NSArray *,FMDatabase *,BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    Class ObjectClass = NSClassFromString(objectName);
    if (![ObjectClass isSubclassOfClass:[StoreModel class]]) {
        return;
    }
    
    if (db) {
        [self selectObjectsByObjectName2:objectName where:where backArray:backArray FMDatabase:db rollBack:rollBack];
    }else{
        __weak typeof(self) wSelf = self;
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [wSelf selectObjectsByObjectName2:objectName where:where backArray:backArray FMDatabase:db rollBack:rollback];
        }];
    }
}


#pragma mark - Private Methods
- (void)selectObjectsByObjectName2:(NSString *)objectName where:(NSString *)where backArray:(void (^)(NSArray *, FMDatabase *, BOOL *))backArray FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    Class ObjectClass = NSClassFromString(objectName);
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
        backArray([marr copy],db,rollBack);
    }
}

- (void)updateObject2:(StoreModel *)model byKeys:(NSArray *)arrKeys FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:[[model class] tableName] FMDatabase:db]) {
        //表存在
        if ([self isModelHadInTable:model FMDatabase:db]){
            //已经存在的一条数据
            NSString *strSQL = [SQLHelper updateSQLWithModel:model byKeys:arrKeys];
            [self executeUpdate:strSQL FMDatabase:db arr:nil];
        }else {
            NSLog(@"使用错误，该数据不存在");
        }
    }else {
        NSLog(@"使用错误，该表不存在");
    }
}

// 更新数据
- (void)updateObject2:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:[[model class] tableName] FMDatabase:db]) {
        //表存在
        if ([self isModelHadInTable:model FMDatabase:db]){
            //已经存在的一条数据
            NSString *strSQL = [SQLHelper updateSQLWithModel:model];
            [self executeUpdate:strSQL FMDatabase:db arr:nil];
        }else {
            NSLog(@"使用错误，该数据不存在");
        }
    }else {
        NSLog(@"使用错误，该表不存在");
    }
}

- (void)deleteAllName2:(NSString *)modelName FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:modelName FMDatabase:db]) {
        NSString *strSQL = [SQLHelper truncateTableSQLWithModelName:modelName];
        if (strSQL.length > 0) {
            [self executeUpdate:strSQL FMDatabase:db arr:nil];
        }
    }else {
        NSLog(@"使用错误，该表不存在");
    }
}

// 删数据
- (void)deleteObject2:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:[[model class] tableName] FMDatabase:db]) {
        if ([self isModelHadInTable:model FMDatabase:db]){
            NSString *strSQL = [SQLHelper deleteSQLWithModel:model];
            if (strSQL.length > 0) {
                [self executeUpdate:strSQL FMDatabase:db arr:nil];
            }
        }else {
            NSLog(@"使用错误，该数据不存在");
        }
    }else {
        NSLog(@"使用错误，该表不存在");
    }
}

- (void)addObject2:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:[[model class] tableName] FMDatabase:db]) {
        //表存在，则更新数据
        if ([self isModelHadInTable:model FMDatabase:db]){
            //已经存在的一条数据
            NSString *strSQL = [SQLHelper updateSQLWithModel:model];
            [self executeUpdate:strSQL FMDatabase:db arr:nil];
        }else {
            //插入新数据
            NSArray *arrValues;
            NSString *strSQL = [SQLHelper insertSQLWithModel:model insertList:&arrValues];
            [self executeUpdate:strSQL FMDatabase:db arr:arrValues];
        }
    }else {
        //表不存在，先创表，再插入数据
        if ([self executeUpdate:[SQLHelper createTableSQLWithModel:model] FMDatabase:db arr:nil]) {
            NSArray *arrValues;
            NSString *strSQL = [SQLHelper insertSQLWithModel:model insertList:&arrValues];
            [self executeUpdate:strSQL FMDatabase:db arr:arrValues];
        }
    }
}

- (void)addColumnWithObject2:(StoreModel *)model columnName:(NSString *)columnName columnType:(NSString *)columnType FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    if ([self isTableOK:[[model class] tableName] FMDatabase:db]) {
        //表存在，则更新数据
        NSString *strSQL = [SQLHelper addColumnSQLWithModel:model columnName:columnName columnType:columnType];
        NSLog(@"新增列的SQL : %@",strSQL);
        [self executeUpdate:strSQL FMDatabase:db arr:nil];
    } else {
        //表不存在
        NSLog(@"使用错误，该表不存在");
    }
}

- (void)addTableWithObject2:(StoreModel *)model FMDatabase:(FMDatabase *)db rollBack:(BOOL *)rollBack{
    [self executeUpdate:[SQLHelper createTableSQLWithModel:model] FMDatabase:db arr:nil];
    NSLog(@"建表成功");
}



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
