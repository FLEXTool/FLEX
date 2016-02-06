//
//  FLEXRealmDatabaseManager.m
//  FLEX
//
//  Created by Tim Oliver on 28/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "FLEXRealmDatabaseManager.h"

//#if __has_include("<Realm/Realm.h>")

#import <Realm/Realm.h>

@interface FLEXRealmDatabaseManager ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) RLMRealm *realm;

@end

@implementation FLEXRealmDatabaseManager

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
    return nil;
}

- (NSArray *)queryAllDataWithTableName:(NSString *)tableName
{
    return nil;
}

@end

//#endif
