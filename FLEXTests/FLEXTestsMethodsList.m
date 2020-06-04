//
//  FLEXTestMethodList.m
//  FLEXTestMethodList
//
//  Created by Tigran Yesayan on 7/6/17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FLEXRuntimeUtility.h"
#import "FLEXManager.h"
#import "FLEXWindow.h"
#import "FLEXMultiColumnTableView.h"

@interface FLEXRuntimeUtility (Testing)

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString;

@end

@interface FLEXTestMethodList : XCTestCase

@end

@implementation FLEXTestMethodList

- (void)testExample {
    NSArray<Class> *classesToTest = @[
        [NSObject class],
        [NSArray class],
        [UIApplication class],
        [UIView class],
        [NSThread class],
        [CALayer class],
        [NSDictionary class],
        [NSProxy class],
        [NSData class],
        [FLEXManager class],
        [FLEXWindow class],
        [FLEXMultiColumnTableView class],
        [NSString class],
        [NSSet class],
        [NSUndoManager class],
        [NSMutableArray class],
        [NSMutableDictionary class],
        [NSException class],
        [UIImage class],
        [UIViewController class],
        [UIScreen class],
        [UIResponder class],
        [NSNumber class],
        [NSValue class],
        [NSError class],
        [NSNotificationCenter class],
        [NSUserActivity class],
        [NSUserDefaults class],
        [NSExpression class],
        [NSBundle class]
    ];
    
    for (Class cls in classesToTest) {
        [self testMethodListForClass:cls];
    }
}

- (void)testMethodListForClass:(Class)class {
    NSLog(@"class: %@", NSStringFromClass(class));
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        Method method = methods[i];
        NSArray *prevWay = [self prettyArgumentComponentsForMethod:method];
        NSArray *newWay = [FLEXRuntimeUtility prettyArgumentComponentsForMethod:method];
        
        XCTAssertEqualObjects(prevWay, newWay);
    }
    
    free(methods);
}

#pragma mark - Method to test with

- (NSArray *)prettyArgumentComponentsForMethod:(Method)method {
    NSMutableArray *components = [NSMutableArray new];
    
    NSString *selectorName = NSStringFromSelector(method_getName(method));
    NSArray *selectorComponents = [selectorName componentsSeparatedByString:@":"];
    unsigned int numberOfArguments = method_getNumberOfArguments(method);
    
    for (unsigned int argIndex = kFLEXNumberOfImplicitArgs; argIndex < numberOfArguments; argIndex++) {
        char *argType = method_copyArgumentType(method, argIndex);
        NSString *readableArgType = [FLEXRuntimeUtility readableTypeForEncoding:@(argType)];
        free(argType);
        NSString *prettyComponent = [NSString stringWithFormat:@"%@:(%@) ", [selectorComponents objectAtIndex:argIndex - kFLEXNumberOfImplicitArgs], readableArgType];
        [components addObject:prettyComponent];
    }
    
    return components;
}

@end
