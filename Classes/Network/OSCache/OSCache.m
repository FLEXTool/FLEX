//
//  OSCache.m
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

#import "OSCache.h"
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wgnu"


@interface OSCacheEntry : NSObject

@property (nonatomic, strong) NSObject *object;
@property (nonatomic, assign) NSUInteger cost;
@property (nonatomic, assign) NSInteger sequenceNumber;

@end


@implementation OSCacheEntry

@end


@interface OSCache_Private : NSObject

@property (nonatomic, unsafe_unretained) id<OSCacheDelegate> delegate;
@property (nonatomic, assign) NSUInteger countLimit;
@property (nonatomic, assign) NSUInteger totalCostLimit;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, assign) NSUInteger totalCost;
@property (nonatomic, assign) NSInteger sequenceNumber;

@end


@implementation OSCache_Private
{
    BOOL _delegateRespondsToWillEvictObject;
    BOOL _delegateRespondsToShouldEvictObject;
    BOOL _currentlyCleaning;
    NSMutableArray *_entryPool;
    NSLock *_lock;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        //create storage
        _cache = [[NSMutableDictionary alloc] init];
        _entryPool = [[NSMutableArray alloc] init];
        _lock = [[NSLock alloc] init];
        _totalCost = 0;
        
#if TARGET_OS_IPHONE
        
        //clean up in the event of a memory warning
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanUpAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
#endif
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDelegate:(id<OSCacheDelegate>)delegate
{
    _delegate = delegate;
    _delegateRespondsToShouldEvictObject = [delegate respondsToSelector:@selector(cache:shouldEvictObject:)];
    _delegateRespondsToWillEvictObject = [delegate respondsToSelector:@selector(cache:willEvictObject:)];
}

- (void)setCountLimit:(NSUInteger)countLimit
{
    [_lock lock];
    _countLimit = countLimit;
    [_lock unlock];
    [self cleanUp:NO];
}

- (void)setTotalCostLimit:(NSUInteger)totalCostLimit
{
    [_lock lock];
    _totalCostLimit = totalCostLimit;
    [_lock unlock];
    [self cleanUp:NO];
}

- (NSUInteger)count
{
    return [_cache count];
}

- (void)cleanUp:(BOOL)keepEntries
{
    [_lock lock];
    NSUInteger maxCount = _countLimit ?: INT_MAX;
    NSUInteger maxCost = _totalCostLimit ?: INT_MAX;
    NSUInteger totalCount = _cache.count;
    NSMutableArray *keys = [_cache.allKeys mutableCopy];
    while (totalCount > maxCount || _totalCost > maxCost)
    {
        NSInteger lowestSequenceNumber = INT_MAX;
        OSCacheEntry *lowestEntry = nil;
        id lowestKey = nil;

        //remove oldest items until within limit
        for (id key in keys)
        {
            OSCacheEntry *entry = _cache[key];
            if (entry.sequenceNumber < lowestSequenceNumber)
            {
                lowestSequenceNumber = entry.sequenceNumber;
                lowestEntry = entry;
                lowestKey = key;
            }
        }

        if (lowestKey)
        {
            [keys removeObject:lowestKey];
            if (!_delegateRespondsToShouldEvictObject ||
                [_delegate cache:(OSCache *)self shouldEvictObject:lowestEntry.object])
            {
                if (_delegateRespondsToWillEvictObject)
                {
                    _currentlyCleaning = YES;
                    [self.delegate cache:(OSCache *)self willEvictObject:lowestEntry.object];
                    _currentlyCleaning = NO;
                }
                [_cache removeObjectForKey:lowestKey];
                _totalCost -= lowestEntry.cost;
                totalCount --;
                if (keepEntries)
                {
                    [_entryPool addObject:lowestEntry];
                    lowestEntry.object = nil;
                }
            }
        }
    }
    [_lock unlock];
}

- (void)cleanUpAllObjects
{
    [_lock lock];
    if (_delegateRespondsToShouldEvictObject || _delegateRespondsToWillEvictObject)
    {
        NSArray *keys = [_cache allKeys];
        if (_delegateRespondsToShouldEvictObject)
        {
            //sort, oldest first (in case we want to use that information in our eviction test)
            keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id key1, id key2) {
                OSCacheEntry *entry1 = self->_cache[key1];
                OSCacheEntry *entry2 = self->_cache[key2];
                return (NSComparisonResult)MIN(1, MAX(-1, entry1.sequenceNumber - entry2.sequenceNumber));
            }];
        }
            
        //remove all items individually
        for (id key in keys)
        {
            OSCacheEntry *entry = _cache[key];
            if (!_delegateRespondsToShouldEvictObject || [_delegate cache:(OSCache *)self shouldEvictObject:entry.object])
            {
                if (_delegateRespondsToWillEvictObject)
                {
                    _currentlyCleaning = YES;
                    [_delegate cache:(OSCache *)self willEvictObject:entry.object];
                    _currentlyCleaning = NO;
                }
                [_cache removeObjectForKey:key];
                _totalCost -= entry.cost;
            }
        }
    }
    else
    {
        _totalCost = 0;
        [_cache removeAllObjects];
        _sequenceNumber = 0;
    }
    [_lock unlock];
}

- (void)resequence
{
    //sort, oldest first
    NSArray *entries = [[_cache allValues] sortedArrayUsingComparator:^NSComparisonResult(OSCacheEntry *entry1, OSCacheEntry *entry2) {
        return (NSComparisonResult)MIN(1, MAX(-1, entry1.sequenceNumber - entry2.sequenceNumber));
    }];
    
    //renumber items
    NSInteger index = 0;
    for (OSCacheEntry *entry in entries)
    {
        entry.sequenceNumber = index++;
    }
}

- (id)objectForKey:(id)key
{
    [_lock lock];
    OSCacheEntry *entry = _cache[key];
    entry.sequenceNumber = _sequenceNumber++;
    if (_sequenceNumber < 0)
    {
        [self resequence];
    }
    id object = entry.object;
    [_lock unlock];
    return object;
}

- (id)objectForKeyedSubscript:(id<NSCopying>)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKey:(id)key
{
    [self setObject:obj forKey:key cost:0];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    [self setObject:obj forKey:key cost:0];
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
{
    if (!obj)
    {
        [self removeObjectForKey:key];
        return;
    }
    NSAssert(!_currentlyCleaning, @"It is not possible to modify cache from within the implementation of this delegate method.");
    [_lock lock];
    _totalCost -= [_cache[key] cost];
    _totalCost += g;
    OSCacheEntry *entry = _cache[key];
    if (!entry) {
        entry = [[OSCacheEntry alloc] init];
        _cache[key] = entry;
    }
    entry.object = obj;
    entry.cost = g;
    entry.sequenceNumber = _sequenceNumber++;
    if (_sequenceNumber < 0)
    {
        [self resequence];
    }
    [_lock unlock];
    [self cleanUp:YES];
}

- (void)removeObjectForKey:(id)key
{
    NSAssert(!_currentlyCleaning, @"It is not possible to modify cache from within the implementation of this delegate method.");
    [_lock lock];
    OSCacheEntry *entry = _cache[key];
    if (entry) {
        _totalCost -= entry.cost;
        entry.object = nil;
        [_entryPool addObject:entry];
        [_cache removeObjectForKey:key];
    }
    [_lock unlock];
}

- (void)removeAllObjects
{
    NSAssert(!_currentlyCleaning, @"It is not possible to modify cache from within the implementation of this delegate method.");
    [_lock lock];
    _totalCost = 0;
    _sequenceNumber = 0;
    for (OSCacheEntry *entry in _cache.allValues)
    {
        entry.object = nil;
        [_entryPool addObject:entry];
    }
    [_cache removeAllObjects];
    [_lock unlock];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
    [_lock lock];
    NSUInteger count = [_cache countByEnumeratingWithState:state objects:buffer count:len];
    [_lock unlock];
    return count;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
  if (block)
  {
      [_lock lock];
      [_cache enumerateKeysAndObjectsUsingBlock:^(id key, OSCacheEntry *entry, BOOL *stop) {
         block(key, entry.object, stop);
      }];
      [_lock unlock];
  }
}

//handle unimplemented methods

- (BOOL)isKindOfClass:(Class)aClass
{
    //pretend that we're an NSCache if anyone asks
    if (aClass == [OSCache class] || aClass == [NSCache class])
    {
        return YES;
    }
    return [super isKindOfClass:aClass];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    //protect against calls to unimplemented NSCache methods
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature)
    {
        signature = [NSCache instanceMethodSignatureForSelector:selector];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

    [invocation invokeWithTarget:nil];

#pragma clang diagnostic pop

}

@end


@implementation OSCache

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return (OSCache *)[OSCache_Private allocWithZone:zone];
}

- (id)objectForKeyedSubscript:(__unused id<NSCopying>)key { return nil; }
- (void)setObject:(__unused id)obj forKeyedSubscript:(__unused id<NSCopying>)key {}
- (void)enumerateKeysAndObjectsUsingBlock:(__unused void (^)(id, id, BOOL *))block { }
- (NSUInteger)countByEnumeratingWithState:(__unused NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(__unused NSUInteger)len { return 0; }

@end
