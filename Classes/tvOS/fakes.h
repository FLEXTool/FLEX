//
//  fakes.h
//  FLEX
//
//  Created by Kevin Bradley on 12/22/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

/*
 
 Feel like this class requires some documentation / commentary.
 
 there are a variaty of classes that are either forbidden or non-existant on tvOS. Initially to get things building
 to find out what i needed to fix outside of missing classes i figured i'd be easiet to stub out "fake' versions
 of the classes that responded to the bare minimum for API complaince to have them appear as empty elements
 rather than preventing building or creating crashes.
 
 */

#import <UIKit/UIKit.h>
#import "FLEXMacros.h"
#import "KBSlider.h"
#import "KBDatePickerView.h"

/**
 
 PREFACE:
 
 Doing UISearchController integration on tvOS is a nightmare. as is ANY integration with the keyboard or having it presented to the end user.
 I made an attempt to get a more native UI/UX to tvOS for this part but couldn't wrap my head around a way to get it to work in a reasonable amount of time
 so i came up with this kludge to get search working in a reasonable sense as quickly as possible for tvOS.

 IMPLEMENTATION:
 
 This UIButton is added as the view of a UITabBarButtonItem as the left bar button item & there is a zero rect text field embedded in this button,
 this is the chicnary necessary to get a keyboard to appear reliably when the text field becomes the first responder.
 the drawback to this approach is the view appears in a mostly opaque and newly minted UISystemInputViewController with a UIKeyboard on it.
 to make this approach workable I wait for 0.1 seconds and then decrease the alpha value of the 'topViewController' which happens to be
 our UISystemInputViewController. this allows the user to see the changes update underneath the view while the search is executed!
 
 */

/// some of the iOS versions of these values are at different indexes - reused the same names and just replaced UI->TV images of these are available in tvOSAccessoryImages

typedef NS_ENUM(NSInteger, TVTableViewCellAccessoryType) {
    TVTableViewCellAccessoryNone,
    TVTableViewCellAccessoryDisclosureIndicator,
    TVTableViewCellAccessoryCheckmark               = 3,
    TVTableViewCellAccessoryChevron                 = 5,
    TVTableViewCellAccessoryChevronOpen,
    TVTableViewCellAccessoryChevronDisclosureButton,
    TVTableViewCellAccessoryChevronOpenDisclosureButton,
    TVTableViewCellAccessoryDetailDisclosureButton      = 10,
    TVTableViewCellAccessoryDetailButton                = 12
};

@interface KBSearchButton: UIButton <UITextFieldDelegate>
@property UISearchBar * _Nullable searchBar; //keep a reference to the search bar to add our text value to the search bar field immediately.
- (void)triggerSearchField;
@end

//UIFakeSwitch is actually just a UIButton that says TRUE/FALSE and responds to UISwitch API calls.

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

//Stub slider, any instances that still use this are only in the snapshot baesd views which dont work yet, this will be pruned once that update is made.

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
