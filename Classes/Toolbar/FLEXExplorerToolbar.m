//
//  FLEXExplorerToolbar.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXExplorerToolbar.h"
#import "FLEXToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbar ()

@property (nonatomic, strong, readwrite) FLEXToolbarItem *selectItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *moveItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *globalsItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *closeItem;
@property (nonatomic, strong, readwrite) FLEXToolbarItem *hierarchyItem;
@property (nonatomic, strong, readwrite) UIView *dragHandle;

@property (nonatomic, strong) UIImageView *dragHandleImageView;

@property (nonatomic, strong) UIView *selectedViewDescriptionContainer;
@property (nonatomic, strong) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic, strong) UIView *selectedViewColorIndicator;
@property (nonatomic, strong) UILabel *selectedViewDescriptionLabel;

@property (nonatomic, strong,readwrite) UIView *backgroundView;

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
        [self addSubview:self.backgroundView];

        self.dragHandle = [[UIView alloc] init];
        self.dragHandle.backgroundColor = [UIColor clearColor];
        [self addSubview:self.dragHandle];
        
        UIImage *dragHandle = [FLEXResources dragHandle];
        self.dragHandleImageView = [[UIImageView alloc] initWithImage:dragHandle];
        [self.dragHandle addSubview:self.dragHandleImageView];
        
        UIImage *globalsIcon = [FLEXResources globeIcon];
        self.globalsItem = [FLEXToolbarItem toolbarItemWithTitle:@"menu" image:globalsIcon];
        
        UIImage *listIcon = [FLEXResources listIcon];
        self.hierarchyItem = [FLEXToolbarItem toolbarItemWithTitle:@"views" image:listIcon];
        
        UIImage *selectIcon = [FLEXResources selectIcon];
        self.selectItem = [FLEXToolbarItem toolbarItemWithTitle:@"select" image:selectIcon];
        
        UIImage *moveIcon = [FLEXResources moveIcon];
        self.moveItem = [FLEXToolbarItem toolbarItemWithTitle:@"move" image:moveIcon];
        
        UIImage *closeIcon = [FLEXResources closeIcon];
        self.closeItem = [FLEXToolbarItem toolbarItemWithTitle:@"close" image:closeIcon];

        self.selectedViewDescriptionContainer = [[UIView alloc] init];
        self.selectedViewDescriptionContainer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.95];
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [[UIView alloc] init];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = [UIColor clearColor];
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];
        
        self.selectedViewColorIndicator = [[UIView alloc] init];
        self.selectedViewColorIndicator.backgroundColor = [UIColor redColor];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [[UILabel alloc] init];
        self.selectedViewDescriptionLabel.backgroundColor = [UIColor clearColor];
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];
        
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }
        
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];


    CGRect safeArea = [self safeArea];
    // Drag Handle
    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    self.dragHandle.frame = CGRectMake(CGRectGetMinX(safeArea), CGRectGetMinY(safeArea), [[self class] dragHandleWidth], kToolbarItemHeight);
    CGRect dragHandleImageFrame = self.dragHandleImageView.frame;
    dragHandleImageFrame.origin.x = FLEXFloor((self.dragHandle.frame.size.width - dragHandleImageFrame.size.width) / 2.0);
    dragHandleImageFrame.origin.y = FLEXFloor((self.dragHandle.frame.size.height - dragHandleImageFrame.size.height) / 2.0);
    self.dragHandleImageView.frame = dragHandleImageFrame;
    
    
    // Toolbar Items
    CGFloat originX = CGRectGetMaxX(self.dragHandle.frame);
    CGFloat originY = CGRectGetMinY(safeArea);
    CGFloat height = kToolbarItemHeight;
    CGFloat width = FLEXFloor((CGRectGetWidth(safeArea) - CGRectGetWidth(self.dragHandle.frame)) / [self.toolbarItems count]);
    for (UIView *toolbarItem in self.toolbarItems) {
        toolbarItem.frame = CGRectMake(originX, originY, width, height);
        originX = CGRectGetMaxX(toolbarItem.frame);
    }
    
    // Make sure the last toolbar item goes to the edge to account for any accumulated rounding effects.
    UIView *lastToolbarItem = [self.toolbarItems lastObject];
    CGRect lastToolbarItemFrame = lastToolbarItem.frame;
    lastToolbarItemFrame.size.width = CGRectGetMaxX(safeArea) - lastToolbarItemFrame.origin.x;
    lastToolbarItem.frame = lastToolbarItemFrame;

    self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), kToolbarItemHeight);
    
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = CGRectGetMinX(self.bounds);
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
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

- (void)setToolbarItems:(NSArray<FLEXToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }
    
    // Remove old toolbar items, if any
    for (FLEXToolbarItem *item in _toolbarItems) {
        [item removeFromSuperview];
    }
    
    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXToolbarItem *item in toolbarItems) {
        [self addSubview:item];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor
{
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription
{
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = [selectedViewDescription length] > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont
{
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight
{
    return 44.0;
}

+ (CGFloat)dragHandleWidth
{
    return 30.0;
}

+ (CGFloat)descriptionLabelHeight
{
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding
{
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight
{
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter
{
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding
{
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    return CGSizeMake(size.width, height);
}

- (CGRect)safeArea
{
  CGRect safeArea = self.bounds;
#if FLEX_AT_LEAST_IOS11_SDK
  if (@available(iOS 11, *)) {
    safeArea = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
  }
#endif
  return safeArea;
}

@end
