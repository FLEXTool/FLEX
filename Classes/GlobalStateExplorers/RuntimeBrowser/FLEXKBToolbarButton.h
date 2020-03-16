//
//  FLEXKBToolbarButton.h
//  FLEX
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^FLEXKBToolbarAction)(NSString *buttonTitle, BOOL isSuggestion);


@interface FLEXKBToolbarButton : UIButton

/// Set to `default` to use the system appearance on iOS 13+
@property (nonatomic) UIKeyboardAppearance appearance;

+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title action:(FLEXKBToolbarAction)eventHandler;
+ (instancetype)buttonWithTitle:(NSString *)title action:(FLEXKBToolbarAction)action forControlEvents:(UIControlEvents)controlEvents;

/// Adds the event handler for the button.
///
/// @param eventHandler The event handler block.
/// @param controlEvents The type of event.
- (void)addEventHandler:(FLEXKBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvents;

@end

@interface FLEXKBToolbarSuggestedButton : FLEXKBToolbarButton @end
