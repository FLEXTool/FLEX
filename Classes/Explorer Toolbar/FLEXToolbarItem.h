//
//  FLEXToolbarItem.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXToolbarItem : UIButton

+ (instancetype)toolbarItemWithTitle:(NSString *)title image:(UIImage *)image;

+ (UIColor *)defaultBackgroundColor;

@end
