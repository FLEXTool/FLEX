//
//  FLEXKeyboardToolbar.h
//
//  Created by Tanner on 6/11/17.
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
