//
//  FLEXKeyPathTokenizer.h
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPath.h"


@interface TBKeyPathTokenizer : NSObject

+ (NSUInteger)tokenCountOfString:(NSString *)userInput;
+ (TBKeyPath *)tokenizeString:(NSString *)userInput;

+ (BOOL)allowedInKeyPath:(NSString *)text;

@end
