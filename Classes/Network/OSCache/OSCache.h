//
//  OSCache.h
//
//  Version 1.2.1
//
//  Created by Nick Lockwood on 01/01/2014.
//  Copyright (C) 2014 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/OSCache
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OSCache <KeyType, ObjectType> : NSCache <NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSUInteger totalCost;

- (id)objectForKeyedSubscript:(KeyType <NSCopying>)key;
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(KeyType key, ObjectType obj, BOOL *stop))block;

@end


@protocol OSCacheDelegate <NSCacheDelegate>
@optional

- (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry;
- (void)cache:(OSCache *)cache willEvictObject:(id)entry;

@end

NS_ASSUME_NONNULL_END
