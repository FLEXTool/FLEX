#import <UIKit/UIKit.h>

@interface KBSelectableTextView : UITextView <UITextFieldDelegate>

- (id)initForAutoLayout;
@property (nonatomic, weak) UIViewController *parentView;
@property (readwrite, assign) BOOL focusColorChange;
@property (nonatomic, strong) UIViewController *inputViewController;
@end
