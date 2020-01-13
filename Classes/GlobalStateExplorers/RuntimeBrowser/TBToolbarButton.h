//
//  FLEXToolbarButton.h
//
//  Created by Tanner on 6/11/17.
//

#import <UIKit/UIKit.h>

typedef void (^TBToolbarAction)(NSString *buttonTitle);


@interface TBToolbarButton : UIButton

/// Set to `default` to use the system appearance on iOS 13+
@property (nonatomic) UIKeyboardAppearance appearance;

+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title action:(TBToolbarAction)eventHandler;
+ (instancetype)buttonWithTitle:(NSString *)title action:(TBToolbarAction)action forControlEvents:(UIControlEvents)controlEvents;

/// Adds the event handler for the button.
///
/// @param eventHandler The event handler block.
/// @param controlEvent The type of event.
- (void)addEventHandler:(TBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvents;

@end
