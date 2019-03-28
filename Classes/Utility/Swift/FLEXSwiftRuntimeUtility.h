//
//  FLEXSwiftRuntimeUtility.h
//  FLEX
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXSwiftRuntimeUtility : NSObject

+ (BOOL)swiftRuntimeAvailable;
+ (Class)SwiftObjectClass;
+ (BOOL)isSwiftObjectOrClass:(id)objectOrClass;

+ (id)performSelector:(SEL)selector onSwiftObject:(id)object withArguments:(NSArray *)arguments error:(NSError * __autoreleasing *)error;

@end
