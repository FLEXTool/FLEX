//
//  TBKeyboardToolbar.h
//
//  Created by Rudd Fawcett on 12/3/13.
//  Copyright (c) 2013 Rudd Fawcett. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AvailabilityMacros.h>

#import "TBToolbarButton.h"


@interface TBKeyboardToolbar : UIView

+ (instancetype)toolbarWithButtons:(NSArray *)buttons;

- (void)setButtons:(NSArray<TBToolbarButton*> *)buttons animated:(BOOL)animated;

@property (nonatomic) NSArray<TBToolbarButton*> *buttons;
@property (nonatomic) UIKeyboardAppearance appearance;

@end
