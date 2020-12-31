//
//  FLEXRuntimeExporter.h
//  FLEX
//
//  Created by Tanner Bennett on 3/26/20.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A class for exporting all runtime metadata to an SQLite database.
//API_AVAILABLE(ios(10.0))
@interface FLEXRuntimeExporter : NSObject

+ (void)createRuntimeDatabaseAtPath:(NSString *)path
                    progressHandler:(void(^)(NSString *status))progress
                         completion:(void(^)(NSString *_Nullable error))completion;

+ (void)createRuntimeDatabaseAtPath:(NSString *)path
                          forImages:(nullable NSArray<NSString *> *)images
                    progressHandler:(void(^)(NSString *status))progress
                         completion:(void(^)(NSString *_Nullable error))completion;


@end

NS_ASSUME_NONNULL_END
