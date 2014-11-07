//
//  KZAsserts.h
//  Pixle
//
//  Created by Krzysztof Zabłocki(@merowing_, merowing.info) on 07/2013.
//  Copyright (c) 2013 Pixle. All rights reserved.
//
#import "KZAsserts.h"

const NSUInteger KZAssertFailedAssertionCode = 13143542;

NSError *kza_NSErrorMake(NSString *message, NSUInteger code, NSDictionary *aUserInfo) {
  NSMutableDictionary *userInfo = [aUserInfo mutableCopy];
  userInfo[NSLocalizedDescriptionKey] = message;
  NSError *error = [NSError errorWithDomain:@"info.merowing.internal" code:code userInfo:userInfo];
  NSString *source = error.userInfo[@"Source"] ?: @"";
  NSString *function = error.userInfo[@"Function"] ?: @"";
  
#define RED @"\033[fg214,57,30;"
#define CLEAR "\033[fg;"
#define BLUE @"\033[fg63,126,209;"
#define GREEN @"\033[fg0,244,129;"
  printf("%s\n", [[NSString stringWithFormat: RED @"KZAsserts" CLEAR BLUE @" %@" CLEAR @" @ " GREEN @"%@" CLEAR RED @" | %@" CLEAR, function, source, message] UTF8String]);

  return error;
}

static TKZAssertErrorFunction function = NULL;

@implementation KZAsserts

+ (void)registerErrorFunction:(TKZAssertErrorFunction)errorFunction
{
  function = errorFunction;
}

+ (TKZAssertErrorFunction)errorFunction
{
  if (!function) {
    [self registerErrorFunction:kza_NSErrorMake];
  }

  return function;
}

@end
