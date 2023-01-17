//
//  FLEXGlobalsSection.h
//  FLEX
//
//  Created by Tanner Bennett on 7/11/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "Classes/Headers/FLEXTableViewSection.h"
#import "Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXGlobalsSection : FLEXTableViewSection

+ (instancetype)title:(NSString *)title rows:(NSArray<FLEXGlobalsEntry *> *)rows;

@end

NS_ASSUME_NONNULL_END
