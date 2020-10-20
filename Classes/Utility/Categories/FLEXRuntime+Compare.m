//
//  FLEXRuntime+Compare.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXRuntime+Compare.h"

@implementation FLEXProperty (Compare)

- (NSComparisonResult)compare:(FLEXProperty *)other {
    NSComparisonResult r = [self.name caseInsensitiveCompare:other.name];
    if (r == NSOrderedSame) {
        // TODO make sure empty image name sorts above an image name
        return [self.imageName ?: @"" compare:other.imageName];
    }

    return r;
}

@end

@implementation FLEXIvar (Compare)

- (NSComparisonResult)compare:(FLEXIvar *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end

@implementation FLEXMethodBase (Compare)

- (NSComparisonResult)compare:(FLEXMethodBase *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end

@implementation FLEXProtocol (Compare)

- (NSComparisonResult)compare:(FLEXProtocol *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end
