#import "KBSelectableTextView.h"
#import "NSObject+FLEX_Reflection.h"
@interface KBSelectableTextView(){
    NSString *_startValue;
    NSString *_endValue;
}

@property UITextField *_backingTextField; //i absolutely hate this but i cant figure out how to get a keyboard editing view to present from a UITextView manually.

@end

@implementation KBSelectableTextView


- (BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    return [__backingTextField becomeFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _startValue = textField.text;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _endValue = textField.text;
    if (_startValue != _endValue && _endValue.length > 0){
        [self setText:textField.text];
    }
}

- (void)_sharedInitialize {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
     tap.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
     [self addGestureRecognizer:tap];
     self.selectable = YES;
     self.userInteractionEnabled = YES;
     self.scrollEnabled = NO;
     self.layoutManager.allowsNonContiguousLayout = NO;
     self.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
     self.focusColorChange = YES;
     __backingTextField = [[UITextField alloc] initWithFrame:CGRectZero];
     [self addSubview:__backingTextField];
    __backingTextField.delegate = self;
    __backingTextField.text = self.text;
    __backingTextField.placeholder = self.text;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self _sharedInitialize];
    return self;
}

- (id)initForAutoLayout
{
    self = [super init];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self _sharedInitialize];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    
}

- (BOOL)isSelectable
{
    return YES;
}

- (BOOL)canBecomeFocused
{
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    if (self.focusColorChange == NO) {
        [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
        return;
    }
    if (context.nextFocusedView == self)
    {
        [coordinator addCoordinatedAnimations:^{
            
            UIColor *whiteAlpha = [UIColor colorWithWhite:1 alpha:.3];
            self.layer.backgroundColor = whiteAlpha.CGColor;
            self.layer.shadowOffset = CGSizeMake(5.0, 5.0);
            self.layer.shadowRadius = 4;
            self.layer.shadowOpacity = 1.0;
            self.layer.shadowColor = [UIColor blackColor].CGColor;
        } completion:^{
        }];
        
    } else {
        [coordinator addCoordinatedAnimations:^{
            self.layer.backgroundColor = [UIColor clearColor].CGColor;
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowRadius = 0;
            self.layer.shadowOpacity = 0;
            self.layer.shadowColor = [UIColor clearColor].CGColor;
        } completion:^{
        }];
    }
}

- (void)tap {
    
    NSLog(@"[FLEXLog] tapped");
    if(self.inputViewController == nil){
        if (self.inputView){
            NSLog(@"[FLEXLog] unhandled input view type: %@", self.inputView);
        }
        [self becomeFirstResponder];
    } else {
        [[self topViewController] presentViewController:self.inputViewController animated:true completion:nil];
    }
}

@end
