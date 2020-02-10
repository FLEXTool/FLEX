//
//  SwiftExports.h
//  FLEX
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#ifndef SwiftExports_h
#define SwiftExports_h

extern "C" id swift_allocObject(Class cls, uint32_t requiredSize, uint32_t alignmentMask);

#endif /* SwiftExports_h */
