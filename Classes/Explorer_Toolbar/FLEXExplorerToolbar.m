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

@property (nonatomic, strong) NSArray *toolbarItems;

@property (nonatomic, strong) UIView *selectedViewDescriptionContainer;
@property (nonatomic, strong) UIView *selectedViewColorIndicator;
@property (nonatomic, strong) UILabel *selectedViewDescriptionLabel;

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSMutableArray *toolbarItems = [NSMutableArray array];
        
        self.dragHandle = [[UIView alloc] init];
        self.dragHandle.backgroundColor = [FLEXToolbarItem defaultBackgroundColor];
        [self addSubview:self.dragHandle];
        
        UIImage *dragHandle = [FLEXResources dragHandle];
        self.dragHandleImageView = [[UIImageView alloc] initWithImage:dragHandle];
        [self.dragHandle addSubview:self.dragHandleImageView];
        
        UIImage *globalsIcon = [FLEXResources globeIcon];
        self.globalsItem = [FLEXToolbarItem toolbarItemWithTitle:@"menu" image:globalsIcon];
        [self addSubview:self.globalsItem];
        [toolbarItems addObject:self.globalsItem];
        
        UIImage *listIcon = [FLEXResources listIcon];
        self.hierarchyItem = [FLEXToolbarItem toolbarItemWithTitle:@"views" image:listIcon];
        [self addSubview:self.hierarchyItem];
        [toolbarItems addObject:self.hierarchyItem];
        
        UIImage *selectIcon = [FLEXResources selectIcon];
        self.selectItem = [FLEXToolbarItem toolbarItemWithTitle:@"select" image:selectIcon];
        [self addSubview:self.selectItem];
        [toolbarItems addObject:self.selectItem];
        
        UIImage *moveIcon = [FLEXResources moveIcon];
        self.moveItem = [FLEXToolbarItem toolbarItemWithTitle:@"move" image:moveIcon];
        [self addSubview:self.moveItem];
        [toolbarItems addObject:self.moveItem];
        
        UIImage *closeIcon = [FLEXResources closeIcon];
        self.closeItem = [FLEXToolbarItem toolbarItemWithTitle:@"close" image:closeIcon];
        [self addSubview:self.closeItem];
        [toolbarItems addObject:self.closeItem];
        
        self.toolbarItems = toolbarItems;
        self.backgroundColor = [UIColor clearColor];
        
        self.selectedViewDescriptionContainer = [[UIView alloc] init];
        self.selectedViewDescriptionContainer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.95];
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];
        
        self.selectedViewColorIndicator = [[UIView alloc] init];
        self.selectedViewColorIndicator.backgroundColor = [UIColor redColor];
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [[UILabel alloc] init];
        self.selectedViewDescriptionLabel.backgroundColor = [UIColor clearColor];
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Drag Handle
    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    self.dragHandle.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, [[self class] dragHandleWidth], kToolbarItemHeight);
    CGRect dragHandleImageFrame = self.dragHandleImageView.frame;
    dragHandleImageFrame.origin.x = FLEXFloor((self.dragHandle.frame.size.width - dragHandleImageFrame.size.width) / 2.0);
    dragHandleImageFrame.origin.y = FLEXFloor((self.dragHandle.frame.size.height - dragHandleImageFrame.size.height) / 2.0);
    self.dragHandleImageView.frame = dragHandleImageFrame;
    
    
    // Toolbar Items
    CGFloat originX = CGRectGetMaxX(self.dragHandle.frame);
    CGFloat originY = self.bounds.origin.y;
    CGFloat height = kToolbarItemHeight;
    CGFloat width = FLEXFloor((CGRectGetMaxX(self.bounds) - originX) / [self.toolbarItems count]);
    for (UIView *toolbarItem in self.toolbarItems) {
        toolbarItem.frame = CGRectMake(originX, originY, width, height);
        originX = CGRectGetMaxX(toolbarItem.frame);
    }
    
    // Make sure the last toolbar item goes to the edge to account for any accumulated rounding effects.
    UIView *lastToolbarItem = [self.toolbarItems lastObject];
    CGRect lastToolbarItemFrame = lastToolbarItem.frame;
    lastToolbarItemFrame.size.width = CGRectGetMaxX(self.bounds) - lastToolbarItemFrame.origin.x;
    lastToolbarItem.frame = lastToolbarItemFrame;
    
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    descriptionContainerFrame.size.width = self.bounds.size.width;
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;
    
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

@end
