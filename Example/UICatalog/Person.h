//
//  Person.h
//  UICatalog
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 f. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject <NSCoding>

+ (instancetype)bob;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger age;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) NSNumber *numberOfKids;

@end
