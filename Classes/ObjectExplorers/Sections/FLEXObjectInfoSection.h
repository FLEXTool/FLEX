//
//  FLEXObjectInfoSection.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/// \c FLEXTableViewSection itself doesn't know about the object being explored.
/// Subclasses might need this info to provide useful information about the object. Instead
/// of adding an abstract class to the class hierarchy, subclasses can conform to this protocol
/// to indicate that the only info they need to be initialized is the object being explored.
@protocol FLEXObjectInfoSection <NSObject>

+ (instancetype)forObject:(id)object;

@end
