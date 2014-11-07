//
//  NSArray+Class.m
//

#import "NSArray+Class.h"

@implementation NSArray (Class)

- (BOOL)containsObjectOfClass:(Class)objectClass
{
    for (id object in self)
    {
        if ([object isMemberOfClass:objectClass])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)containsObjectOfInheritedClass:(Class)objectClass
{
    for (id object in self)
    {
        if ([object isKindOfClass:objectClass])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)containsAllObjectsOfClass:(Class)objectClass
{
    for (id object in self)
    {
        if (![object isMemberOfClass:objectClass])
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)containsAllObjectsOfInheritedClass:(Class)objectClass
{
    for (id object in self)
    {
        if (![object isKindOfClass:objectClass])
        {
            return NO;
        }
    }
    
    return YES;
}

@end
