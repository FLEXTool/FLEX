//
//  FHSSnapshotView.h
//  FLEX
//
//  Created by Tanner Bennett on 1/7/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FHSViewSnapshot.h"
#import "FHSRangeSlider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FHSSnapshotViewDelegate <NSObject>

- (void)didSelectView:(FHSViewSnapshot *)snapshot;
- (void)didDeselectView:(FHSViewSnapshot *)snapshot;
- (void)didLongPressView:(FHSViewSnapshot *)snapshot;

@end

@interface FHSSnapshotView : UIView

+ (instancetype)delegate:(id<FHSSnapshotViewDelegate>)delegate;

@property (nonatomic, weak) id<FHSSnapshotViewDelegate> delegate;

@property (nonatomic) NSArray<FHSViewSnapshot *> *snapshots;
@property (nonatomic, nullable) FHSViewSnapshot *selectedView;

/// Views of these classes will have their headers hidden
@property (nonatomic) NSArray<Class> *headerExclusions;

@property (nonatomic, readonly) UISlider *spacingSlider;
@property (nonatomic, readonly) FHSRangeSlider *depthSlider;

- (void)emphasizeViews:(NSArray<UIView *> *)emphasizedViews;

- (void)toggleShowHeaders;
- (void)toggleShowBorders;

- (void)hideView:(FHSViewSnapshot *)view;

@end

NS_ASSUME_NONNULL_END
