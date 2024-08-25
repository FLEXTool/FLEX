//
//  FLEXArgumentInputFontsPickerView.m
//  FLEX
//
//  Created by 啟倫 陳 on 2014/7/27.
//  Copyright (c) 2014年 f. All rights reserved.
//

#import "FLEXArgumentInputFontsPickerView.h"
#import "FLEXRuntimeUtility.h"

@interface FLEXArgumentInputFontsPickerView ()

@property (nonatomic) NSMutableArray<NSString *> *availableFonts;

@end


@implementation FLEXArgumentInputFontsPickerView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.targetSize = FLEXArgumentInputViewSizeSmall;
        [self createAvailableFonts];
        self.inputTextView.inputView = [self createFontsPicker];
    }
    return self;
}

- (void)setInputValue:(id)inputValue {
    self.inputTextView.text = inputValue;
    if ([self.availableFonts indexOfObject:inputValue] == NSNotFound) {
        [self.availableFonts insertObject:inputValue atIndex:0];
    }
    [(UIPickerView *)self.inputTextView.inputView selectRow:[self.availableFonts indexOfObject:inputValue] inComponent:0 animated:NO];
}

- (id)inputValue {
    return self.inputTextView.text.length > 0 ? [self.inputTextView.text copy] : nil;
}

#pragma mark - private

- (UIPickerView*)createFontsPicker {
    UIPickerView *fontsPicker = [UIPickerView new];
    fontsPicker.dataSource = self;
    fontsPicker.delegate = self;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Deprecated in iOS 13; from then on, selection is always shown
    fontsPicker.showsSelectionIndicator = YES;
    #pragma clang diagnostic pop

    return fontsPicker;
}

- (void)createAvailableFonts {
    NSMutableArray<NSString *> *unsortedFontsArray = [NSMutableArray new];
    for (NSString *eachFontFamily in UIFont.familyNames) {
        for (NSString *eachFontName in [UIFont fontNamesForFamilyName:eachFontFamily]) {
            [unsortedFontsArray addObject:eachFontName];
        }
    }
    self.availableFonts = [NSMutableArray arrayWithArray:[unsortedFontsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.availableFonts.count;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *fontLabel;
    if (!view) {
        fontLabel = [UILabel new];
        fontLabel.backgroundColor = UIColor.clearColor;
        fontLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        fontLabel = (UILabel*)view;
    }
    UIFont *font = [UIFont fontWithName:self.availableFonts[row] size:15.0];
    NSDictionary<NSString *, id> *attributesDictionary = [NSDictionary<NSString *, id> dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:self.availableFonts[row] attributes:attributesDictionary];
    fontLabel.attributedText = attributesString;
    [fontLabel sizeToFit];
    return fontLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.inputTextView.text = self.availableFonts[row];
}

@end
