//
//  FLEXArgumentInputViewFactory.m
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import "FLEXArgumentInputViewFactory.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputTextView.h"

@implementation FLEXArgumentInputViewFactory

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding
{
    return [[FLEXArgumentInputTextView alloc] initWithArgumentTypeEncoding:typeEncoding];
}

@end
