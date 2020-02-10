//
//  ExistentialContainer.h
//  FLEX
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#ifndef ExistentialContainer_h
#define ExistentialContainer_h

#import <Foundation/Foundation.h>

/// AKA "Any"
struct ExistentialContainerBuffer {
    NSInteger a, b, c;
    
    ssize_t size() {
        return sizeof(ExistentialContainerBuffer);
    }
}

struct ExistentialContainer {
    ExistentialContainerBuffer buffer;
    void *type;
    uintptr_t witnessTable;
}

#endif /* ExistentialContainer_h */
