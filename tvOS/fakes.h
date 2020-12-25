//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXMacros.h"

@protocol UIFakePickerViewDataSource, UIFakePickerViewDelegate;

@interface UIFakePickerView : UIView <NSCoding>

@property(nullable,nonatomic,weak) id<UIFakePickerViewDataSource> dataSource;                // default is nil. weak reference
@property(nullable,nonatomic,weak) id<UIFakePickerViewDelegate>   delegate;                  // default is nil. weak reference
@property(nonatomic) BOOL showsSelectionIndicator API_DEPRECATED("This property has no effect on iOS 7 and later.", ios(2.0, 13.0));

// info that was fetched and cached from the data source and delegate
@property(nonatomic,readonly) NSInteger numberOfComponents;
- (NSInteger)numberOfRowsInComponent:(NSInteger)component;
- (CGSize)rowSizeForComponent:(NSInteger)component;

// returns the view provided by the delegate via pickerView:viewForRow:forComponent:reusingView:
// or nil if the row/component is not visible or the delegate does not implement
// pickerView:viewForRow:forComponent:reusingView:
- (nullable UIView *)viewForRow:(NSInteger)row forComponent:(NSInteger)component;

// Reloading whole view or single component
- (void)reloadAllComponents;
- (void)reloadComponent:(NSInteger)component;

// selection. in this case, it means showing the appropriate row in the middle
- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated;  // scrolls the specified row to center.

- (NSInteger)selectedRowInComponent:(NSInteger)component;                                   // returns selected row. -1 if nothing selected

@end

@protocol UIFakePickerViewDataSource<NSObject>
@required

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIFakePickerView *_Nonnull)pickerView;

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIFakePickerView *_Nonnull)pickerView numberOfRowsInComponent:(NSInteger)component;
@end


@protocol UIFakePickerViewDelegate<NSObject>
@optional

// returns width of column and height of row for each component.
- (CGFloat)pickerView:(UIFakePickerView *_Nonnull)pickerView widthForComponent:(NSInteger)component ;
- (CGFloat)pickerView:(UIFakePickerView *_Nonnull)pickerView rowHeightForComponent:(NSInteger)component ;

// these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
// for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
// If you return back a different object, the old one will be released. the view will be centered in the row rect
- (nullable NSString *)pickerView:(UIFakePickerView *_Nonnull)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component ;
- (nullable NSAttributedString *)pickerView:(UIFakePickerView *_Nonnull)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component API_AVAILABLE(ios(6.0)) ; // attributed title is favored if both methods are implemented
- (UIView *_Nonnull)pickerView:(UIFakePickerView *_Nonnull)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view ;

- (void)pickerView:(UIFakePickerView *_Nonnull)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component ;

@end



@interface UIFakeSwitch : UIButton <NSCoding>
@property(nullable, nonatomic, strong) UIColor *onTintColor;
@property(nullable, nonatomic, strong) UIColor *thumbTintColor;
@property(nullable, nonatomic, strong) UIImage *onImage;
@property(nullable, nonatomic, strong) UIImage *offImage;
@property(nonatomic,getter=isOn) BOOL on;
- (instancetype _Nonnull )initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;      // This class enforces a size appropriate for the control, and so the frame size is ignored.
- (nullable instancetype)initWithCoder:(NSCoder *_Nonnull)coder NS_DESIGNATED_INITIALIZER;
- (void)setOn:(BOOL)on animated:(BOOL)animated; // does not send action
+ (id _Nonnull )newSwitch;
@end

@interface UIFakeSlider: UIControl <NSCoding>
@property(nonatomic) float value;
@property(nonatomic) float minimumValue;
@property(nonatomic) float maximumValue;
@property(nonatomic) float minValue;
@property(nonatomic) float maxValue;
@property(nonatomic) float allowedMinValue;
@property(nonatomic) float allowedMaxValue;
@property(nullable, nonatomic,strong) UIImage *minimumValueImage;
@property(nullable, nonatomic,strong) UIImage *maximumValueImage;

@property(nonatomic,getter=isContinuous) BOOL continuous;

@property(nullable, nonatomic,strong) UIColor *minimumTrackTintColor;
@property(nullable, nonatomic,strong) UIColor *maximumTrackTintColor;
@property(nullable, nonatomic,strong) UIColor *thumbTintColor;

- (void)setValue:(float)value animated:(BOOL)animated;

- (void)setThumbImage:(nullable UIImage *)image forState:(UIControlState)state;
- (void)setMinimumTrackImage:(nullable UIImage *)image forState:(UIControlState)state;
- (void)setMaximumTrackImage:(nullable UIImage *)image forState:(UIControlState)state;

- (nullable UIImage *)thumbImageForState:(UIControlState)state;
- (nullable UIImage *)minimumTrackImageForState:(UIControlState)state;
- (nullable UIImage *)maximumTrackImageForState:(UIControlState)state;

@property(nullable,nonatomic,readonly) UIImage *currentThumbImage;
@property(nullable,nonatomic,readonly) UIImage *currentMinimumTrackImage;
@property(nullable,nonatomic,readonly) UIImage *currentMaximumTrackImage;

// lets a subclass lay out the track and thumb as needed
- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)trackRectForBounds:(CGRect)bounds;
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value;

@end
