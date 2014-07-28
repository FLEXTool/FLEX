//
//  FLEXArgumentInputFontsPickerView.m
//  UICatalog
//
//  Created by 啟倫 陳 on 2014/7/27.
//  Copyright (c) 2014年 f. All rights reserved.
//

#import "FLEXArgumentInputFontsPickerView.h"
#import "FLEXRuntimeUtility.h"

@interface FLEXArgumentInputFontsPickerView ()

@property (nonatomic, strong) NSMutableArray *availableFonts;

@end


@implementation FLEXArgumentInputFontsPickerView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding
{
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        
        [self createAvailableFonts];
        
        self.targetSize = FLEXArgumentInputViewSizeSmall;
        
        self.inputTextView.inputView = ({
            UIPickerView *fontsPicker = [UIPickerView new];
            fontsPicker.dataSource = self;
            fontsPicker.delegate = self;
            fontsPicker.showsSelectionIndicator = YES;
            fontsPicker;
        });
        
    }
    return self;
}

- (void)setInputValue:(id)inputValue
{
    self.inputTextView.text = inputValue;

    if ([self.availableFonts indexOfObject:inputValue] == NSNotFound) {
        [self.availableFonts insertObject:inputValue atIndex:0];
    }
    
    [(UIPickerView*)self.inputTextView.inputView selectRow:[self.availableFonts indexOfObject:inputValue]
                                               inComponent:0
                                                  animated:NO];
    
}

- (id)inputValue
{
    return [self.inputTextView.text length] > 0 ? [self.inputTextView.text copy] : nil;
}

#pragma mark - private

- (void)createAvailableFonts
{
    NSMutableArray *unsortedFontsArray = [NSMutableArray array];

    for (NSString *eachFontFamily in [UIFont familyNames]) {
        
        for (NSString *eachFontName in [UIFont fontNamesForFamilyName:eachFontFamily]) {
            [unsortedFontsArray addObject:eachFontName];
        }
        
    }
    
    self.availableFonts = [NSMutableArray arrayWithArray:[unsortedFontsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    
    return [self.availableFonts count];
    
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    
    if (!view) {
        view = [UILabel new];
        [(UILabel*)view setBackgroundColor:[UIColor clearColor]];
        [(UILabel*)view setTextAlignment:NSTextAlignmentCenter];
    }
    
    UIFont *font = [UIFont fontWithName:self.availableFonts[row] size:15.0];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:font
                                                                     forKey:NSFontAttributeName];
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:self.availableFonts[row] attributes:attributesDictionary];
    
    [(UILabel*)view setAttributedText:attributesString];
    [view sizeToFit];
    
    return view;
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.inputTextView.text = self.availableFonts[row];
}

@end
