//
//  Person.h
//  UICatalog
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject <NSCoding>

+ (instancetype)bob;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger age;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) NSNumber *numberOfKids;

@property (nonatomic) NSDecimalNumber *netWorth;

@end

NS_ASSUME_NONNULL_END
