//
//  NSArray+PropertyList.m
//

#import "NSObject+PropertyList.h"

@implementation NSObject (PropertyList)

- (BOOL)isPropertyList
{
    return [[self class] isObjectPropertyListItem:self];
}

+ (BOOL)isObjectPropertyListItem:(id)object
{
    //
    // Recursively search for an element that could not be a property list.
    //
    if ([object isKindOfClass:[NSArray class]])
    {
        //
        // All items in array should be a property list
        //
        for (id value in object)
        {
            if (![self isObjectPropertyListItem:value])
            {
                return NO;
            }
        }

        return YES;
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        NSArray* keys = [object allKeys];
        
        //
        // All keys in dictionary must be strings
        //
        for (id key in keys)
        {
            if (![key isKindOfClass:[NSString class]])
            {
                return NO;
            }
        }
        
        //
        // All objects in dictionary must also be property lists.
        //
        
        NSArray* values = [object allValues];
        
        for (id value in values)
        {
            if (![self isObjectPropertyListItem:value])
            {
                return NO;
            }
        }
        
        return YES;
    }
    else if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSData class]] || [object isKindOfClass:[NSDate class]] || [object isKindOfClass:[NSNumber class]])
    {
        return YES;
    }
    
    return NO;
}
@end
