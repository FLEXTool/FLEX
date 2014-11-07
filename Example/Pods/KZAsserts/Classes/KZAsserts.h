//
//  KZAsserts.h
//  Pixle
//
//  Created by Krzysztof Zabłocki(@merowing_, merowing.info) on 07/2013.
//  Copyright (c) 2013 Pixle. All rights reserved.
//

#ifndef KZAssertsIncluded

#define KZAssertsIncluded true

extern const NSUInteger KZAssertFailedAssertionCode;

typedef NSError *(*TKZAssertErrorFunction)(NSString *message, NSUInteger code, NSDictionary *userInfo);

@interface KZAsserts : NSObject
+ (void)registerErrorFunction:(TKZAssertErrorFunction)errorFunction;

+ (TKZAssertErrorFunction)errorFunction;
@end

#ifndef KZAMakeError
  #define KZAMakeError(message) KZAsserts.errorFunction([NSString stringWithFormat:@"Condition not satisfied: %@", message], KZAssertFailedAssertionCode, @{@"Source" : [NSString stringWithFormat:@"%s:%d", __FILE__, (int)__LINE__], @"Function" : @(__PRETTY_FUNCTION__)}); do{}while(0)
#endif

#define RED @"\033[fg214,57,30;"
#define CLEAR "\033[fg;"
#define BLUE @"\033[fg63,126,209;"
#define GREEN @"\033[fg0,244,129;"

/**
    AssertTrueOr[X](condition) - if condition fails to be true, on debug builds it will crash by using Assertion, on Release builds it calls error creation and perform specific action. Asserts with block param will execute ^(NSError *){} passed in block with auto-generated NSError.
 */
#define AssertTrueOr(condition, action) { BOOL evaluatedCondition = !!(condition); NSCAssert(evaluatedCondition, @"%@", [NSString stringWithFormat:RED @"KZAsserts" CLEAR BLUE @" %s" CLEAR @" @ " GREEN @"%s:%d" CLEAR RED @" | %@" CLEAR, __PRETTY_FUNCTION__, __FILE__, (int)__LINE__, @"Failed: " @#condition]); if (!evaluatedCondition) { NSError *kza_error = KZAMakeError(@#condition); (void)(kza_error); action }} do{} while(0)

#define AssertTrueOrReturnError(condition) AssertTrueOr(condition, return kza_error;)
#define AssertTrueOrReturnErrorBlock(condition, block) AssertTrueOr(condition, block(kza_error); return kza_error;)

#define AssertTrueOrReturn(condition) AssertTrueOr(condition, return;)
#define AssertTrueOrReturnBlock(condition, block) AssertTrueOr(condition, block(kza_error); return;)

#define AssertTrueOrReturnNo(condition) AssertTrueOr(condition, return NO;)
#define AssertTrueOrReturnNoBlock(condition, block) AssertTrueOr(condition, block(kza_error); return NO;)

#define AssertTrueOrReturnNil(condition) AssertTrueOr(condition, return nil;)
#define AssertTrueOrReturnNilBlock(condition, block) AssertTrueOr(condition, block(kza_error); return nil;)

#define AssertTrueOrContinue(condition) AssertTrueOr(condition, continue;)
#define AssertTrueOrContinueBlock(condition, block) AssertTrueOr(condition, block(kza_error); continue;)

#define AssertTrueOrBreak(condition) AssertTrueOr(condition, break;)
#define AssertTrueOrBreakBlock(condition, block) AssertTrueOr(condition, block(kza_error); break;)

#endif