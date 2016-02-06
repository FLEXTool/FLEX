//
//  FLEXRealmDatabaseManager.m
//  FLEX
//
//  Created by Tim Oliver on 28/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "FLEXRealmDatabaseManager.h"

#if __has_include("<Realm/Realm.h>")

#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>

@interface FLEXRealmDatabaseManager ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) RLMRealm *realm;

@end

#endif

@implementation FLEXRealmDatabaseManager

#if __has_include("<Realm/Realm.h>")

- (instancetype)initWithPath:(NSString*)aPath
{
    self = [super init];
    
    if (self) {
        _path = aPath;
    }
    return self;
}

- (BOOL)open
{
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.dynamic = YES;
    configuration.path = self.path;
    
    NSError *error = nil;
    self.realm = [RLMRealm realmWithConfiguration:configuration error:&error];
    
    return (error == nil);
}

- (NSArray *)queryAllTables
{
    NSMutableArray *allTables = [NSMutableArray array];
    RLMSchema *schema = self.realm.schema;
    
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (objectSchema.className == nil) {
            continue;
        }
        
        NSDictionary *dictionary = @{@"name":objectSchema.className};
        [allTables addObject:dictionary];
    }
    
    return allTables;
}

- (NSArray *)queryAllColumnsWithTableName:(NSString *)tableName
{
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    if (objectSchema == nil) {
        return nil;
    }
    
    NSMutableArray *columnNames = [NSMutableArray array];
    for (RLMProperty *property in objectSchema.properties) {
        [columnNames addObject:property.name];
    }
    
    return columnNames;
}

- (NSArray *)queryAllDataWithTableName:(NSString *)tableName
{
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    RLMResults *results = [self.realm allObjects:tableName];
    if (results.count == 0 || objectSchema == nil) {
        return nil;
    }
    
    NSMutableArray *allDataEntries = [NSMutableArray array];
    for (RLMObject *result in results) {
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        for (RLMProperty *property in objectSchema.properties) {
            entry[property.name] = [result valueForKey:property.name];
        }
        
        [allDataEntries addObject:entry];
    }
    
    return allDataEntries;
}

#endif

@end
