//
//  NSString+KeyPaths.h
//  FLEX
//
//  Created by Tanner on 3/26/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (KeyPaths)

- (NSString *)stringByRemovingLastKeyPathComponent;
- (NSString *)stringByReplacingLastKeyPathComponent:(NSString *)replacement;

@end
