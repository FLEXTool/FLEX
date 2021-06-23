//
//  FLEXNewRootClass.h
//  FLEXTests
//
//  Created by Tanner on 12/30/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Root class with one method
OBJC_ROOT_CLASS
@interface FLEXNewRootClass {
    Class isa OBJC_ISA_AVAILABILITY;
}

- (void)theOnlyMethod;

@end
