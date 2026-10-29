//
//  FLEXRecommendation.m
//  FLEX
//
//  Created by [Your Team] on 2025-06-26.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXRecommendation.h"

@implementation FLEXRecommendation

+ (instancetype)createWithTitle:(NSString *)title
                          subtitle:(NSString *)subtitle
                   relevantObject:(id)object
                              action:(NSString *)action {
    FLEXRecommendation *rec = [[FLEXRecommendation alloc] init];
    rec.title = title;
    rec.subtitle = subtitle;
    rec.relevantObject = object;
    rec.action = action;
    return rec;
}

@end