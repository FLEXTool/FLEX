//
//  FLEXNewRootClass.m
//  FLEXTests
//
//  Created by Tanner on 12/30/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXNewRootClass.h"
#import <objc/runtime.h>

@implementation FLEXNewRootClass

+ (id)alloc {
    FLEXNewRootClass *obj = (__bridge id)calloc(1, class_getInstanceSize(self));
    object_setClass(obj, self);
    return obj;
}

- (void)theOnlyMethod { }

- (void)retain { }
- (void)release { }

@end
