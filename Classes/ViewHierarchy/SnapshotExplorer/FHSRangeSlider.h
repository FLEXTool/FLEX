//
//  FHSRangeSlider.h
//  FLEX
//
//  Created by Tanner Bennett on 1/7/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FHSRangeSlider : UIControl

@property (nonatomic) CGFloat allowedMinValue;
@property (nonatomic) CGFloat allowedMaxValue;
@property (nonatomic) CGFloat minValue;
@property (nonatomic) CGFloat maxValue;

@end

NS_ASSUME_NONNULL_END
