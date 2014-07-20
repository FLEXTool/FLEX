/*
        File: AAPLDatePickerController.m
    Abstract: A view controller that demonstrates how to use UIDatePicker.
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

#import "AAPLDatePickerController.h"

@interface AAPLDatePickerController()

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end


#pragma mark -

@implementation AAPLDatePickerController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create a date formatter to be used to format the "date" property of "datePicker".
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

    [self configureDatePicker];
}


#pragma mark - Configuration

- (void)configureDatePicker {
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;

    // Set min/max date for the date picker.
    // As an example we will limit the date between now and 7 days from now.
    NSDate *now = [NSDate date];
    self.datePicker.minimumDate = now;

    NSCalendar *currentCalendar = [NSCalendar currentCalendar];

    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 7;

    NSDate *sevenDaysFromNow = [currentCalendar dateByAddingComponents:dateComponents toDate:now options:0];
    self.datePicker.maximumDate = sevenDaysFromNow;

    // Display the "minutes" interval by increments of 1 minute (this is the default).
    self.datePicker.minuteInterval = 1;

    [self.datePicker addTarget:self action:@selector(updateDatePickerLabel) forControlEvents:UIControlEventValueChanged];

    [self updateDatePickerLabel];
}


#pragma mark - Actions

- (void)updateDatePickerLabel {
    self.dateLabel.text = [self.dateFormatter stringFromDate:self.datePicker.date];
}

@end
