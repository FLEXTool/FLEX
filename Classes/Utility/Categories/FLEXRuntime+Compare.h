//
//  FLEXRuntime+Compare.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Classes/Utility/Runtime/Objc/Reflection/FLEXProperty.h"
#import "Classes/Utility/Runtime/Objc/Reflection/FLEXIvar.h"
#import "Classes/Utility/Runtime/Objc/Reflection/FLEXMethodBase.h"
#import "Classes/Utility/Runtime/Objc/Reflection/FLEXProtocol.h"

@interface FLEXProperty (Compare)
- (NSComparisonResult)compare:(FLEXProperty *)other;
@end

@interface FLEXIvar (Compare)
- (NSComparisonResult)compare:(FLEXIvar *)other;
@end

@interface FLEXMethodBase (Compare)
- (NSComparisonResult)compare:(FLEXMethodBase *)other;
@end

@interface FLEXProtocol (Compare)
- (NSComparisonResult)compare:(FLEXProtocol *)other;
@end
