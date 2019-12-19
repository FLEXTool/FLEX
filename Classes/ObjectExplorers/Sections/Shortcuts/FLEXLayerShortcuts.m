//
//  FLEXLayerShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXLayerShortcuts.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXLayerShortcuts ()
@property (nonatomic, readonly) CALayer *layer;
@end

@implementation FLEXLayerShortcuts

#pragma mark - Internal

- (CALayer *)layer {
    return self.object;
}

#pragma mark - Internal

- (UIViewController *)imagePreviewViewController {
    if (!CGRectIsEmpty(self.layer.bounds)) {
        UIGraphicsBeginImageContextWithOptions(self.layer.bounds.size, NO, 0.0);
        CGContextRef imageContext = UIGraphicsGetCurrentContext();
        [self.layer renderInContext:imageContext];
        UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [FLEXImagePreviewViewController forImage:previewImage];
    }

    return nil;
}


#pragma mark - Overrides

+ (instancetype)forObject:(CALayer *)layer {
    return [self forObject:layer additionalRows:@[@"Preview"]];
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    if (row == 0) {
        return [self imagePreviewViewController];
    }

    return [super viewControllerToPushForRow:row];
}

@end
