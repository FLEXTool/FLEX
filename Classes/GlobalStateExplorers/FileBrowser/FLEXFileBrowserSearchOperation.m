//
//  FLEXFileBrowserSearchOperation.m
//  FLEX
//
//  Created by 啟倫 陳 on 2014/8/4.
//  Copyright (c) 2014年 f. All rights reserved.
//

#import "FLEXFileBrowserSearchOperation.h"

@implementation NSMutableArray (FLEXStack)

- (void)flex_push:(id)anObject {
    [self addObject:anObject];
}

- (id)flex_pop {
    id anObject = self.lastObject;
    [self removeLastObject];
    return anObject;
}

@end

@interface FLEXFileBrowserSearchOperation ()

@property (nonatomic) NSString *path;
@property (nonatomic) NSString *searchString;

@end

@implementation FLEXFileBrowserSearchOperation

#pragma mark - private

- (uint64_t)totalSizeAtPath:(NSString *)path {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
    uint64_t totalSize = [attributes fileSize];
    
    for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
        attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
        totalSize += [attributes fileSize];
    }
    return totalSize;
}

#pragma mark - instance method

- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString {
    self = [super init];
    if (self) {
        self.path = currentPath;
        self.searchString = searchString;
    }
    return self;
}

#pragma mark - methods to override

- (void)main {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<NSString *> *searchPaths = [NSMutableArray new];
    NSMutableDictionary<NSString *, NSNumber *> *sizeMapping = [NSMutableDictionary new];
    uint64_t totalSize = 0;
    NSMutableArray<NSString *> *stack = [NSMutableArray new];
    [stack flex_push:self.path];
    
    //recursive found all match searchString paths, and precomputing there size
    while (stack.count) {
        NSString *currentPath = [stack flex_pop];
        NSArray<NSString *> *directoryPath = [fileManager contentsOfDirectoryAtPath:currentPath error:nil];
        
        for (NSString *subPath in directoryPath) {
            NSString *fullPath = [currentPath stringByAppendingPathComponent:subPath];
            
            if ([[subPath lowercaseString] rangeOfString:[self.searchString lowercaseString]].location != NSNotFound) {
                [searchPaths addObject:fullPath];
                if (!sizeMapping[fullPath]) {
                    uint64_t fullPathSize = [self totalSizeAtPath:fullPath];
                    totalSize += fullPathSize;
                    [sizeMapping setObject:@(fullPathSize) forKey:fullPath];
                }
            }
            BOOL isDirectory;
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
                [stack flex_push:fullPath];
            }
            
            if ([self isCancelled]) {
                return;
            }
        }
    }
    
    //sort
    NSArray<NSString *> *sortedArray = [searchPaths sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        uint64_t pathSize1 = [sizeMapping[path1] unsignedLongLongValue];
        uint64_t pathSize2 = [sizeMapping[path2] unsignedLongLongValue];
        if (pathSize1 < pathSize2) {
            return NSOrderedAscending;
        } else if (pathSize1 > pathSize2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    if ([self isCancelled]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate fileBrowserSearchOperationResult:sortedArray size:totalSize];
    });
}

@end
