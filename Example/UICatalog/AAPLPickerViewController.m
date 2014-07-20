/*
        File: AAPLPickerViewController.m
    Abstract: A view controller that demonstrates how to use UIPickerView.
     Version: 2.12
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    
*/

#import "AAPLPickerViewController.h"

typedef NS_ENUM(NSInteger, AAPLPickerViewControllerColorComponent) {
    AAPLColorComponentRed = 0,
    AAPLColorComponentGreen,
    AAPLColorComponentBlue,
    AAPLColorComponentCount
};

// The maximum RGB color
#define AAPL_RGB_MAX 255.0

@interface AAPLPickerViewController()<UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate>

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UIView *colorSwatchView;

@property (nonatomic) CGFloat redColorComponent;
@property (nonatomic) CGFloat greenColorComponent;
@property (nonatomic) CGFloat blueColorComponent;

@end


#pragma mark -

@implementation AAPLPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Show that a given row is selected. This is off by default.
    self.pickerView.showsSelectionIndicator = YES;

    [self configurePickerView];
}

// The offset of each color value (from 0 to 255) for red, green, and blue.
- (NSInteger)colorValueOffset {
    return 5;
}

- (NSInteger)numberOfColorValuesPerComponent {
    return (NSInteger)ceil(AAPL_RGB_MAX / (CGFloat)[self colorValueOffset]) + 1;
}

- (void)updateColorSwatchViewBackgroundColor {
    self.colorSwatchView.backgroundColor = [UIColor colorWithRed:self.redColorComponent green:self.greenColorComponent blue:self.blueColorComponent alpha:1];
}


#pragma mark - Configuration

- (void)configurePickerView {
    // Set the default selected rows (the desired rows to initially select will vary by use case).
    [self selectRowInPickerView:13 withColorComponent:AAPLColorComponentRed];
    [self selectRowInPickerView:41 withColorComponent:AAPLColorComponentGreen];
    [self selectRowInPickerView:24 withColorComponent:AAPLColorComponentBlue];
}

- (void)selectRowInPickerView:(NSInteger)row withColorComponent:(AAPLPickerViewControllerColorComponent)colorComponent {
    // Note that the delegate method on UIPickerViewDelegate is not triggered when manually calling -[UIPickerView selectRow:inComponent:animated:].
    // To do this, we fire off the delegate method manually.
    [self.pickerView selectRow:row inComponent:(NSInteger)colorComponent animated:YES];
    [self pickerView:self.pickerView didSelectRow:row inComponent:(NSInteger)colorComponent];
}


#pragma mark - RGB Color Setter Overrides

- (void)setRedColorComponent:(CGFloat)redColorComponent {
    if (_redColorComponent != redColorComponent) {
        _redColorComponent = redColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}

- (void)setGreenColorComponent:(CGFloat)greenColorComponent {
    if (_greenColorComponent != greenColorComponent) {
        _greenColorComponent = greenColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}

- (void)setBlueColorComponent:(CGFloat)blueColorComponent {
    if (_blueColorComponent != blueColorComponent) {
        _blueColorComponent = blueColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return AAPLColorComponentCount;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self numberOfColorValuesPerComponent];
}


#pragma mark - UIPickerViewDelegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSInteger colorValue = row * [self colorValueOffset];

    CGFloat colorComponent = (CGFloat)colorValue / AAPL_RGB_MAX;
    CGFloat redColorComponent = 0;
    CGFloat greenColorComponent = 0;
    CGFloat blueColorComponent = 0;

    switch (component) {
        case AAPLColorComponentRed:
            redColorComponent = colorComponent;
            break;
        case AAPLColorComponentGreen:
            greenColorComponent = colorComponent;
            break;
        case AAPLColorComponentBlue:
            blueColorComponent = colorComponent;
            break;
        default:
            NSLog(@"Invalid row/component combination for picker view.");
            break;
    }

    UIColor *foregroundColor = [UIColor colorWithRed:redColorComponent green:greenColorComponent blue:blueColorComponent alpha:1];

    NSString *titleText = [NSString stringWithFormat:@"%ld", (long)colorValue];

    // Set the foreground color for the attributed string.
    NSDictionary *attributes = @{NSForegroundColorAttributeName: foregroundColor};
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:titleText attributes:attributes];

    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    CGFloat colorComponentValue = ((CGFloat)[self colorValueOffset] * row)/AAPL_RGB_MAX;

    switch (component) {
        case AAPLColorComponentRed:
            self.redColorComponent = colorComponentValue;
            break;

        case AAPLColorComponentGreen:
            self.greenColorComponent = colorComponentValue;
            break;

        case AAPLColorComponentBlue:
            self.blueColorComponent = colorComponentValue;
            break;
            
        default:
            NSLog(@"Invalid row/component combination selected for picker view.");
            break;
    }
}


#pragma mark - UIPickerViewAccessibilityDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component {
    NSString *accessibilityLabel;

    switch (component) {
        case AAPLColorComponentRed:
            accessibilityLabel = NSLocalizedString(@"Red color component value", nil);
            break;
            
        case AAPLColorComponentGreen:
            accessibilityLabel = NSLocalizedString(@"Green color component value", nil);
            break;
            
        case AAPLColorComponentBlue:
            accessibilityLabel = NSLocalizedString(@"Blue color component value", nil);
            break;
            
        default:
            NSLog(@"Invalid row/component combination for picker view.");
            break;
    }

    return accessibilityLabel;
}

@end
