//
//  UIMenu+FLEX.m
//  FLEX
//
//  Created by Tanner on 1/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIMenu+FLEX.h"

@implementation UIMenu (FLEX)

+ (instancetype)flex_inlineMenuWithTitle:(NSString *)title image:(UIImage *)image children:(NSArray *)children {
    return [UIMenu
        menuWithTitle:title
        image:image
        identifier:nil
        options:UIMenuOptionsDisplayInline
        children:children
    ];
}

- (instancetype)flex_collapsed {
    return [UIMenu
        menuWithTitle:@""
        image:nil
        identifier:nil
        options:UIMenuOptionsDisplayInline
        children:@[[UIMenu
            menuWithTitle:self.title
            image:self.image
            identifier:self.identifier
            options:0
            children:self.children
        ]]
    ];
}

@end
