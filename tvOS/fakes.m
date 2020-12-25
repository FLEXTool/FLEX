//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "fakes.h"

@implementation UIFakePickerView

- (NSInteger) numberOfComponents {
    return 0;
}
- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    return 0;;
}
- (CGSize)rowSizeForComponent:(NSInteger)component {
    return CGSizeZero;
}

- (nullable UIView *)viewForRow:(NSInteger)row forComponent:(NSInteger)component {
    return nil;
}
// Reloading whole view or single component
- (void)reloadAllComponents {
    
}
- (void)reloadComponent:(NSInteger)component {
    
}

// selection. in this case, it means showing the appropriate row in the middle
- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated {
    
}
- (NSInteger)selectedRowInComponent:(NSInteger)component {
    return -1;
}

@end

@implementation UIFakeSwitch

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    
}

-(instancetype)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
}

- (instancetype)initWithCoder:(id)coder {
    return [super initWithCoder:coder];
}

@end

@implementation UIFakeSlider

- (void)setValue:(float)value animated:(BOOL)animated {
    
}

- (void)setThumbImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}
- (void)setMinimumTrackImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}
- (void)setMaximumTrackImage:(nullable UIImage *)image forState:(UIControlState)state {
    
}

- (nullable UIImage *)thumbImageForState:(UIControlState)state {
    return nil;
}
- (nullable UIImage *)minimumTrackImageForState:(UIControlState)state {
    return nil;
}
- (nullable UIImage *)maximumTrackImageForState:(UIControlState)state {
    return nil;
}

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectZero;
}
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    return CGRectZero;
}

@end
