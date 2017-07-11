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

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [self testMethodListForClass:[NSObject class]];
    [self testMethodListForClass:[NSArray class]];
    [self testMethodListForClass:[UIApplication class]];
    [self testMethodListForClass:[UIView class]];
    [self testMethodListForClass:[NSThread class]];
    [self testMethodListForClass:[CALayer class]];
    [self testMethodListForClass:[NSDictionary class]];
    [self testMethodListForClass:[NSProxy class]];
    [self testMethodListForClass:[NSData class]];
    [self testMethodListForClass:[FLEXManager class]];
    [self testMethodListForClass:[FLEXWindow class]];
    [self testMethodListForClass:[FLEXMultiColumnTableView class]];
    [self testMethodListForClass:[NSString class]];
    [self testMethodListForClass:[NSSet class]];
    [self testMethodListForClass:[NSUndoManager class]];
    [self testMethodListForClass:[NSMutableArray class]];
    [self testMethodListForClass:[NSMutableDictionary class]];
    [self testMethodListForClass:[NSException class]];
    [self testMethodListForClass:[UIImage class]];
    [self testMethodListForClass:[UIViewController class]];
    [self testMethodListForClass:[UIScreen class]];
    [self testMethodListForClass:[UIResponder class]];
    [self testMethodListForClass:[NSNumber class]];
    [self testMethodListForClass:[NSValue class]];
    [self testMethodListForClass:[NSError class]];
    [self testMethodListForClass:[NSNotificationCenter class]];
    [self testMethodListForClass:[NSUserActivity class]];
    [self testMethodListForClass:[NSUserDefaults class]];
    [self testMethodListForClass:[NSExpression class]];
    [self testMethodListForClass:[NSBundle class]];
}

- (void)testMethodListForClass:(Class)class {
    NSLog(@"class: %@", NSStringFromClass(class));
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; ++i) {
        Method method = methods[i];
        NSString *selectorName = NSStringFromSelector(method_getName(method));
        NSArray *prevWay = [self prettyArgumentComponentsForMethod:method];
        if (![prevWay count]) {
            prevWay = @[ selectorName ];
        }
        
        NSArray *newWay = [FLEXRuntimeUtility prettyArgumentComponentsForMethod:method];
        
        XCTAssert([newWay isEqual:prevWay]);
    }
    
    free(methods);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

#pragma mark - Method to test with

- (NSArray *)prettyArgumentComponentsForMethod:(Method)method {
    NSMutableArray *components = [NSMutableArray array];
    
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
