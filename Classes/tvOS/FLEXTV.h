//
//  FLEXTV.h
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

//UIFLEXSwitch is actually just a UIButton that says TRUE/FALSE and responds to UISwitch API calls.

@interface UIFLEXSwitch : UIButton <NSCoding>
@property(nullable, nonatomic, strong) UIColor *onTintColor;
@property(nullable, nonatomic, strong) UIColor *thumbTintColor; //here for protocol adherence - ignored
@property(nullable, nonatomic, strong) UIImage *onImage; //ditto above
@property(nullable, nonatomic, strong) UIImage *offImage; //ditto
@property(nonatomic,getter=isOn) BOOL on;
- (instancetype _Nonnull )initWithFrame:(CGRect)frame;      // This class enforces a size appropriate for the control, and so the frame size is ignored.
- (nullable instancetype)initWithCoder:(NSCoder *_Nonnull)coder;
- (void)setOn:(BOOL)on animated:(BOOL)animated; // does not send action
+ (id _Nonnull )newSwitch;
@end
