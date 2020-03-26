//
//  FLEXLayerShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXLayerShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXImagePreviewViewController.h"
#import "NSString+SyntaxHighlighting.h"

@implementation FLEXLayerShortcuts

+ (instancetype)forObject:(CALayer *)layer {
    return [self forObject:layer additionalRows:@[
        [FLEXActionShortcut title:@"Preview Image".attributedString subtitle:nil
            viewer:^UIViewController *(id layer) {
                return [FLEXImagePreviewViewController previewForLayer:layer];
            }
            accessoryType:^UITableViewCellAccessoryType(id layer) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end
