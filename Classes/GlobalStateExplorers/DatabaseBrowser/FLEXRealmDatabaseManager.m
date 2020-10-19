//
//  FLEXRealmDatabaseManager.m
//  FLEX
//
//  Created by Tim Oliver on 28/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "FLEXRealmDatabaseManager.h"
#import "NSArray+FLEX.h"
#import "FLEXSQLResult.h"

#if __has_include(<Realm/Realm.h>)
#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#else
#import "FLEXRealmDefines.h"
#endif

@interface FLEXRealmDatabaseManager ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic) RLMRealm *realm;

@end

@implementation FLEXRealmDatabaseManager
static Class RLMRealmClass = nil;

+ (void)load {
    RLMRealmClass = NSClassFromString(@"RLMRealm");
}

+ (instancetype)managerForDatabase:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    if (!RLMRealmClass) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _path = path;
        
        if (![self open]) {
            return nil;
        }
    }
    
    return self;
}

- (BOOL)open {
    Class configurationClass = NSClassFromString(@"RLMRealmConfiguration");
    if (!RLMRealmClass || !configurationClass) {
        return NO;
    }
    
    NSError *error = nil;
    id configuration = [configurationClass new];
    [(RLMRealmConfiguration *)configuration setFileURL:[NSURL fileURLWithPath:self.path]];
    self.realm = [RLMRealmClass realmWithConfiguration:configuration error:&error];
    
    return (error == nil);
}

- (NSArray<NSString *> *)queryAllTables {
    // Map each schema to its name
    NSArray<NSString *> *tableNames = [self.realm.schema.objectSchema flex_mapped:^id(RLMObjectSchema *schema, NSUInteger idx) {
        return schema.className ?: nil;
    }];

    return [tableNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray<NSString *> *)queryAllColumnsOfTable:(NSString *)tableName {
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    // Map each column to its name
    return [objectSchema.properties flex_mapped:^id(RLMProperty *property, NSUInteger idx) {
        return property.name;
    }];
}

- (NSArray<NSArray *> *)queryAllDataInTable:(NSString *)tableName {
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    RLMResults *results = [self.realm allObjects:tableName];
    if (results.count == 0 || !objectSchema) {
        return nil;
    }
    
    // Map results to an array of rows
    return [NSArray flex_mapped:results block:^id(RLMObject *result, NSUInteger idx) {
        // Map each row to an array of the values of its properties 
        return [objectSchema.properties flex_mapped:^id(RLMProperty *property, NSUInteger idx) {
            return [result valueForKey:property.name] ?: NSNull.null;
        }];
    }];
}

@end
