//
//  NSUserDefaults+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (FLEX)

@property (nonatomic) double flex_toolbarTopMargin;

@property (nonatomic) BOOL flex_cacheOSLogMessages;

@property (nonatomic) BOOL flex_explorerHidesRedundantIvars;
@property (nonatomic) BOOL flex_explorerHidesRedundantMethods;

@end
