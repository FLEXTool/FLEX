//
//  FLEXScopeCarousel.m
//  FLEX
//
//  Created by Tanner Bennett on 7/17/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXScopeCarousel.h"
#import "FLEXCarouselCell.h"
#import "FLEXColor.h"
#import "UIView+FLEX_Layout.h"

const CGFloat kCarouselItemSpacing = 0;
NSString * const kCarouselCellReuseIdentifier = @"kCarouselCellReuseIdentifier";

@interface FLEXScopeCarousel () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, readonly) UICollectionView *collectionView;
@property (nonatomic, readonly) FLEXCarouselCell *sizingCell;

@property (nonatomic, readonly) id dynamicTypeObserver;
@property (nonatomic, readonly) NSMutableArray *dynamicTypeHandlers;

@property (nonatomic) BOOL constraintsInstalled;
@end

@implementation FLEXScopeCarousel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = FLEXColor.primaryBackgroundColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        _dynamicTypeHandlers = [NSMutableArray new];
        
        CGSize itemSize = CGSizeZero;
        if (@available(iOS 10.0, *)) {
            itemSize = UICollectionViewFlowLayoutAutomaticSize;
        }

        // Collection view layout
        UICollectionViewFlowLayout *layout = ({
            UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            layout.sectionInset = UIEdgeInsetsZero;
            layout.minimumLineSpacing = kCarouselItemSpacing;
            layout.itemSize = itemSize;
            layout.estimatedItemSize = itemSize;
            layout;
        });

        // Collection view
        _collectionView = ({
            UICollectionView *cv = [[UICollectionView alloc]
                initWithFrame:CGRectZero
                collectionViewLayout:layout
            ];
            cv.showsHorizontalScrollIndicator = NO;
            cv.backgroundColor = UIColor.clearColor;
            cv.delegate = self;
            cv.dataSource = self;
            [cv registerClass:[FLEXCarouselCell class] forCellWithReuseIdentifier:kCarouselCellReuseIdentifier];

            [self addSubview:cv];
            cv;
        });


        // Sizing cell
        _sizingCell = [FLEXCarouselCell new];
        self.sizingCell.title = @"NSObject";

        // Dynamic type
        __weak __typeof(self) weakSelf = self;
        _dynamicTypeObserver = [NSNotificationCenter.defaultCenter
            addObserverForName:UIContentSizeCategoryDidChangeNotification
            object:nil queue:nil usingBlock:^(NSNotification *note) {
                [self.collectionView setNeedsLayout];
                [self setNeedsUpdateConstraints];

                // Notify observers
                __typeof(self) self = weakSelf;
                for (void (^block)(FLEXScopeCarousel *) in self.dynamicTypeHandlers) {
                    block(self);
                }
            }
        ];
    }

    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self.dynamicTypeObserver];
}

#pragma mark - Overrides

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    CGFloat width = 1.f / UIScreen.mainScreen.scale;

    // Draw hairline
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, FLEXColor.hairlineColor.CGColor);
    CGContextSetLineWidth(context, width);
    CGContextMoveToPoint(context, 0, rect.size.height - width);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height - width);
    CGContextStrokePath(context);
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {
    if (!self.constraintsInstalled) {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.collectionView pinEdgesToSuperview];
        
        self.constraintsInstalled = YES;
    }
    
    [super updateConstraints];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(
        UIViewNoIntrinsicMetric,
        [self.sizingCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height
    );
}

#pragma mark - Public

- (void)setItems:(NSArray<NSString *> *)items {
    NSParameterAssert(items.count);

    _items = items.copy;

    // Refresh list, select first item initially
    [self.collectionView reloadData];
    self.selectedIndex = 0;
}

- (void)setSelectedIndex:(NSInteger)idx {
    NSParameterAssert(idx < self.items.count);

    _selectedIndex = idx;
    NSIndexPath *path = [NSIndexPath indexPathForItem:idx inSection:0];
    [self.collectionView selectItemAtIndexPath:path
                                      animated:YES
                                scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:path];
}

- (void)registerBlockForDynamicTypeChanges:(void (^)(FLEXScopeCarousel *))handler {
    [self.dynamicTypeHandlers addObject:handler];
}

#pragma mark - UICollectionView

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    if (@available(iOS 10.0, *)) {
//        return UICollectionViewFlowLayoutAutomaticSize;
//    }
    
    self.sizingCell.title = self.items[indexPath.item];
    return [self.sizingCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FLEXCarouselCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:kCarouselCellReuseIdentifier
                                                                           forIndexPath:indexPath];
    cell.title = self.items[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectedIndex = indexPath.item; // In case self.selectedIndex didn't trigger this call

    if (self.selectedIndexChangedAction) {
        self.selectedIndexChangedAction(indexPath.row);
    }

    // TODO: dynamically choose a scroll position. Very wide items should
    // get "Left" while smaller items should not scroll at all, unless
    // they are only partially on the screen, in which case they
    // should get "HorizontallyCentered" to bring them onto the screen.
    // For now, everything goes to the left, as this has a similar effect.
    [collectionView scrollToItemAtIndexPath:indexPath
                           atScrollPosition:UICollectionViewScrollPositionLeft
                                   animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
