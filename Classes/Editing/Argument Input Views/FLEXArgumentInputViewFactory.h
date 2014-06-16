//
//  FLEXArgumentInputViewFactory.h
//  FLEXInjected
//
//  Created by Ryan Olson on 6/15/14.
//
//

#import <Foundation/Foundation.h>

@class FLEXArgumentInputView;

@interface FLEXArgumentInputViewFactory : NSObject

+ (FLEXArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding;

@end
