//
//  FLEXExplorerToolbar.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXExplorerToolbar.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbar ()

@property (nonatomic, readwrite) FLEXExplorerToolbarItem *globalsItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *hierarchyItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *selectItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *recentItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *moveItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *closeItem;
@property (nonatomic, readwrite) UIView *dragHandle;

@property (nonatomic) UIImageView *dragHandleImageView;

@property (nonatomic) UIView *selectedViewDescriptionContainer;
@property (nonatomic) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic) UIView *selectedViewColorIndicator;
@property (nonatomic) UILabel *selectedViewDescriptionLabel;

@property (nonatomic,readwrite) UIView *backgroundView;
@property (nonatomic) UIVisualEffectView *backgroundGlassView API_AVAILABLE(ios(26.0));
@property (nonatomic) UIVisualEffectView *descriptionGlassView API_AVAILABLE(ios(26.0));

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Background
        if (@available(iOS 26, *)) {
            UIGlassEffect *glassEffect = [[UIGlassEffect alloc] init];
            self.backgroundGlassView = [[UIVisualEffectView alloc] initWithEffect:glassEffect];
            self.backgroundGlassView.clipsToBounds = YES;
            self.backgroundGlassView.layer.cornerRadius = 16;
            [self addSubview:self.backgroundGlassView];
            self.backgroundView = self.backgroundGlassView;
        } else {
            self.backgroundView = [UIView new];
            self.backgroundView.backgroundColor = [FLEXColor secondaryBackgroundColorWithAlpha:0.95];
            [self addSubview:self.backgroundView];
        }

        // Drag handle
        self.dragHandle = [UIView new];
        self.dragHandle.backgroundColor = UIColor.clearColor;
        self.dragHandleImageView = [[UIImageView alloc] initWithImage:FLEXResources.dragHandle];
        self.dragHandleImageView.tintColor = [FLEXColor.iconColor colorWithAlphaComponent:0.666];
        [self.dragHandle addSubview:self.dragHandleImageView];
        [self addSubview:self.dragHandle];
        
        // Buttons
        if (@available(iOS 26, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
            self.globalsItem   = [FLEXExplorerToolbarItem itemWithTitle:@"menu" image:[UIImage systemImageNamed:@"wrench.fill" withConfiguration:config]];
            self.hierarchyItem = [FLEXExplorerToolbarItem itemWithTitle:@"views" image:[UIImage systemImageNamed:@"square.3.layers.3d.top.filled" withConfiguration:config]];
            self.selectItem    = [FLEXExplorerToolbarItem itemWithTitle:@"select" image:[UIImage systemImageNamed:@"rectangle.and.hand.point.up.left.filled" withConfiguration:config]];
            self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"recent" image:[UIImage systemImageNamed:@"clock.fill" withConfiguration:config]];
            self.moveItem      = [FLEXExplorerToolbarItem itemWithTitle:@"move" image:[UIImage systemImageNamed:@"arrow.up.and.down.and.arrow.left.and.right" withConfiguration:config] sibling:self.recentItem];
            self.closeItem     = [FLEXExplorerToolbarItem itemWithTitle:@"close" image:[UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config]];
        } else {
            self.globalsItem   = [FLEXExplorerToolbarItem itemWithTitle:@"menu" image:FLEXResources.globalsIcon];
            self.hierarchyItem = [FLEXExplorerToolbarItem itemWithTitle:@"views" image:FLEXResources.hierarchyIcon];
            self.selectItem    = [FLEXExplorerToolbarItem itemWithTitle:@"select" image:FLEXResources.selectIcon];
            self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"recent" image:FLEXResources.recentIcon];
            self.moveItem      = [FLEXExplorerToolbarItem itemWithTitle:@"move" image:FLEXResources.moveIcon sibling:self.recentItem];
            self.closeItem     = [FLEXExplorerToolbarItem itemWithTitle:@"close" image:FLEXResources.closeIcon];
        }

        // Selected view box //
        
        if (@available(iOS 26, *)) {
            UIGlassEffect *descGlassEffect = [[UIGlassEffect alloc] init];
            self.descriptionGlassView = [[UIVisualEffectView alloc] initWithEffect:descGlassEffect];
            self.descriptionGlassView.clipsToBounds = YES;
            self.descriptionGlassView.layer.cornerRadius = [[self class] descriptionContainerHeight] / 2.0;
            self.descriptionGlassView.hidden = YES;
            [self addSubview:self.descriptionGlassView];
            self.selectedViewDescriptionContainer = self.descriptionGlassView;
        } else {
            self.selectedViewDescriptionContainer = [UIView new];
            self.selectedViewDescriptionContainer.backgroundColor = [FLEXColor tertiaryBackgroundColorWithAlpha:0.95];
            self.selectedViewDescriptionContainer.hidden = YES;
            [self addSubview:self.selectedViewDescriptionContainer];
        }

        self.selectedViewDescriptionSafeAreaContainer = [UIView new];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = UIColor.clearColor;
        if (@available(iOS 26, *)) {
            [self.descriptionGlassView.contentView addSubview:self.selectedViewDescriptionSafeAreaContainer];
        } else {
            [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];
        }
        
        self.selectedViewColorIndicator = [UIView new];
        self.selectedViewColorIndicator.backgroundColor = UIColor.redColor;
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [UILabel new];
        self.selectedViewDescriptionLabel.backgroundColor = UIColor.clearColor;
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];
        
        // toolbarItems
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];


    CGRect safeArea = [self safeArea];
    // Drag Handle
    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    CGFloat topPadding = 0;
    if (@available(iOS 26, *)) {
        topPadding = [[self class] glassVerticalPadding];
    }

    self.dragHandle.frame = CGRectMake(CGRectGetMinX(safeArea), CGRectGetMinY(safeArea) + topPadding, [[self class] dragHandleWidth], kToolbarItemHeight);
    CGRect dragHandleImageFrame = self.dragHandleImageView.frame;
    dragHandleImageFrame.origin.x = FLEXFloor((self.dragHandle.frame.size.width - dragHandleImageFrame.size.width) / 2.0);
    dragHandleImageFrame.origin.y = FLEXFloor((self.dragHandle.frame.size.height - dragHandleImageFrame.size.height) / 2.0);
    self.dragHandleImageView.frame = dragHandleImageFrame;


    // Toolbar Items
    CGFloat originX = CGRectGetMaxX(self.dragHandle.frame);
    CGFloat originY = CGRectGetMinY(safeArea) + topPadding;
    CGFloat height = kToolbarItemHeight;
    CGFloat width = FLEXFloor((CGRectGetWidth(safeArea) - CGRectGetWidth(self.dragHandle.frame)) / self.toolbarItems.count);
    for (FLEXExplorerToolbarItem *toolbarItem in self.toolbarItems) {
        toolbarItem.currentItem.frame = CGRectMake(originX, originY, width, height);
        originX = CGRectGetMaxX(toolbarItem.currentItem.frame);
    }
    
    // Make sure the last toolbar item goes to the edge to account for any accumulated rounding effects.
    UIView *lastToolbarItem = self.toolbarItems.lastObject.currentItem;
    CGRect lastToolbarItemFrame = lastToolbarItem.frame;
    CGFloat rightEdge = CGRectGetMaxX(safeArea);
    if (@available(iOS 26, *)) {
        const CGFloat kGlassInset = [[self class] glassHorizontalInset];
        rightEdge = CGRectGetWidth(self.bounds) - kGlassInset;
    }
    lastToolbarItemFrame.size.width = rightEdge - lastToolbarItemFrame.origin.x;
    lastToolbarItem.frame = lastToolbarItemFrame;

    if (@available(iOS 26, *)) {
        const CGFloat kGlassInset = [[self class] glassHorizontalInset];
        const CGFloat kGlassPadding = [[self class] glassVerticalPadding];
        self.backgroundView.frame = CGRectMake(
            kGlassInset, 0,
            CGRectGetWidth(self.bounds) - kGlassInset * 2, kToolbarItemHeight + kGlassPadding * 2
        );
    } else {
        self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), kToolbarItemHeight);
    }
    
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    if (@available(iOS 26, *)) {
        const CGFloat kGlassInset = [[self class] glassHorizontalInset];
        const CGFloat kGlassGap = 2;
        descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds) - kGlassInset * 2;
        descriptionContainerFrame.size.height = kDescriptionContainerHeight;
        descriptionContainerFrame.origin.x = kGlassInset;
        descriptionContainerFrame.origin.y = CGRectGetMaxY(self.backgroundView.frame) + kGlassGap;
    } else {
        descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
        descriptionContainerFrame.size.height = kDescriptionContainerHeight;
        descriptionContainerFrame.origin.x = CGRectGetMinX(self.bounds);
        descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    }
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;

    CGRect descriptionSafeAreaContainerFrame = CGRectZero;
    descriptionSafeAreaContainerFrame.size.width = CGRectGetWidth(safeArea);
    descriptionSafeAreaContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionSafeAreaContainerFrame.origin.x = CGRectGetMinX(safeArea);
    descriptionSafeAreaContainerFrame.origin.y = CGRectGetMinY(safeArea);
    self.selectedViewDescriptionSafeAreaContainer.frame = descriptionSafeAreaContainerFrame;

    // Selected View Color
    CGRect selectedViewColorFrame = CGRectZero;
    selectedViewColorFrame.size.width = kSelectedViewColorDiameter;
    selectedViewColorFrame.size.height = kSelectedViewColorDiameter;
    selectedViewColorFrame.origin.x = kHorizontalPadding;
    selectedViewColorFrame.origin.y = FLEXFloor((kDescriptionContainerHeight - kSelectedViewColorDiameter) / 2.0);
    self.selectedViewColorIndicator.frame = selectedViewColorFrame;
    self.selectedViewColorIndicator.layer.cornerRadius = ceil(selectedViewColorFrame.size.height / 2.0);
    
    // Selected View Description
    CGRect descriptionLabelFrame = CGRectZero;
    CGFloat descriptionOriginX = CGRectGetMaxX(selectedViewColorFrame) + kHorizontalPadding;
    descriptionLabelFrame.size.height = kDescriptionLabelHeight;
    descriptionLabelFrame.origin.x = descriptionOriginX;
    descriptionLabelFrame.origin.y = kDescriptionVerticalPadding;
    descriptionLabelFrame.size.width = CGRectGetMaxX(self.selectedViewDescriptionContainer.bounds) - kHorizontalPadding - descriptionOriginX;
    self.selectedViewDescriptionLabel.frame = descriptionLabelFrame;
}


#pragma mark - Setter Overrides

- (void)setToolbarItems:(NSArray<FLEXExplorerToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }
    
    // Remove old toolbar items, if any
    for (FLEXExplorerToolbarItem *item in _toolbarItems) {
        [item.currentItem removeFromSuperview];
    }
    
    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXExplorerToolbarItem *item in toolbarItems) {
        [self addSubview:item.currentItem];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor {
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription {
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = selectedViewDescription.length > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight {
    return 44.0;
}

+ (CGFloat)glassVerticalPadding {
    return 6.0;
}

+ (CGFloat)glassHorizontalInset {
    return 4.0;
}

+ (CGFloat)dragHandleWidth {
    return FLEXResources.dragHandle.size.width;
}

+ (CGFloat)descriptionLabelHeight {
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding {
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight {
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter {
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding {
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    if (@available(iOS 26, *)) {
        height += [[self class] glassVerticalPadding] * 2;
    }
    return CGSizeMake(size.width, height);
}

- (CGRect)safeArea {
    CGRect safeArea = self.bounds;
    if (@available(iOS 11.0, *)) {
        safeArea = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
    }

    return safeArea;
}

@end
