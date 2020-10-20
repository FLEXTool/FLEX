//
//  FHSViewSnapshot.h
//  FLEX
//
//  Created by Tanner Bennett on 1/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FHSView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FHSViewSnapshot : NSObject

+ (instancetype)snapshotWithView:(FHSView *)view;

@property (nonatomic, readonly) FHSView *view;

@property (nonatomic, readonly) NSString *title;
/// Whether or not this view item should be visually distinguished
@property (nonatomic, readwrite) BOOL important;

@property (nonatomic, readonly) CGRect frame;
@property (nonatomic, readonly) BOOL hidden;
@property (nonatomic, readonly) UIImage *snapshotImage;

@property (nonatomic, readonly) NSArray<FHSViewSnapshot *> *children;
@property (nonatomic, readonly) NSString *summary;

/// Returns a different color based on whether or not the view is important
@property (nonatomic, readonly) UIColor *headerColor;

- (FHSViewSnapshot *)snapshotForView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
