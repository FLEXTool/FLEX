//
//  FLEXRecommendation.h
//  FLEX
//
//  Created by [Your Team] on 2025-06-26.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXRecommendation : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) id relevantObject;
@property (nonatomic, copy) NSString *action;
+ (instancetype)createWithTitle:(NSString *)title
                          subtitle:(NSString *)subtitle
                   relevantObject:(id)object
                              action:(NSString *)action;
@end

NS_ASSUME_NONNULL_END