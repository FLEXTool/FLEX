//
//  FLEXFileBrowserSearchOperation.h
//  FLEX
//
//  Created by 啟倫 陳 on 2014/8/4.
//  Copyright (c) 2014年 f. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FLEXFileBrowserSearchOperationDelegate;

@interface FLEXFileBrowserSearchOperation : NSOperation

@property (nonatomic, weak) id<FLEXFileBrowserSearchOperationDelegate> delegate;

- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString;

@end

@protocol FLEXFileBrowserSearchOperationDelegate <NSObject>

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size;

@end
