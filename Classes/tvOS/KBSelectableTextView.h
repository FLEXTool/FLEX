#import <UIKit/UIKit.h>
/**
 UITextView doesn't work the same on tvOS as it does on iOS, we largely need to recreate the experience in a pretty unconventional way.
 Handle focus & showing the keyboard using a zero rect UITextField
 
 */

@interface KBSelectableTextView : UITextView <UITextFieldDelegate>
- (id)initForAutoLayout;
@property (nonatomic, weak) UIViewController *parentView;
@property (readwrite, assign) BOOL focusColorChange;
@property (nonatomic, strong) UIViewController *inputViewController;
@end
