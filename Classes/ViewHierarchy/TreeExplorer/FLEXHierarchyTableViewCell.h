//
//  FLEXHierarchyTableViewCell.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-02.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXHierarchyTableViewCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic) NSInteger viewDepth;
@property (nonatomic) UIColor *randomColorTag;
@property (nonatomic) UIColor *indicatedViewColor;

@end
