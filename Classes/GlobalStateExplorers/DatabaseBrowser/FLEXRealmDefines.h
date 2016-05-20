//
//  Realm.h
//  FLEX
//
//  Created by Tim Oliver on 16/02/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#if __has_include(<Realm/Realm.h>)
#else

@class RLMObject, RLMResults, RLMRealm, RLMRealmConfiguration, RLMSchema, RLMObjectSchema, RLMProperty;

@interface RLMRealmConfiguration : NSObject
@property (nonatomic, copy) NSURL *fileURL;
@end

@interface RLMRealm : NSObject
@property (nonatomic, readonly) RLMSchema *schema;
+ (RLMRealm *)realmWithConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error;
- (RLMResults *)allObjects:(NSString *)className;
@end

@interface RLMSchema : NSObject
@property (nonatomic, readonly) NSArray *objectSchema;
- (RLMObjectSchema *)schemaForClassName:(NSString *)className;
@end

@interface RLMObjectSchema : NSObject
@property (nonatomic, readonly) NSString *className;
@property (nonatomic, readonly) NSArray *properties;
@end

@interface RLMProperty : NSString
@property (nonatomic, readonly) NSString *name;
@end

@interface RLMResults : NSObject <NSFastEnumeration>
@property (nonatomic, readonly) NSInteger count;
@end

@interface RLMObject : NSObject

@end

#endif