//
//  FLEXHierarchyTableViewCell.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-02.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXHierarchyTableViewCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, assign) NSInteger viewDepth;
@property (nonatomic, strong) UIColor *viewColor;

@end
