//
//  NSAttributedString+FLEX.h
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (FLEX)
+ (instancetype)stringByJoiningArray:(NSArray<NSAttributedString *> *)array withSeparator:(NSAttributedString *)separator;
+ (instancetype)stringWithFormat:(NSString *)format, ...;
+ (instancetype)stringWithAttributes:(NSDictionary *)attributes format:(NSString *)format, ...;
- (instancetype)stringByAppendingAttributedString:(NSAttributedString *)aString;
@end
