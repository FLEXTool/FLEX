//
//  FLEXKeyboardToolbar.h
//  FLEX
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXKBToolbarButton.h"

@interface FLEXKeyboardToolbar : UIView

+ (instancetype)toolbarWithButtons:(NSArray *)buttons;

@property (nonatomic) NSArray<FLEXKBToolbarButton*> *buttons;
@property (nonatomic) UIKeyboardAppearance appearance;

@end
