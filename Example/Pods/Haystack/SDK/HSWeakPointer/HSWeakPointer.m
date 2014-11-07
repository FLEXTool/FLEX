#import "HSWeakPointer.h"

@implementation HSWeakPointer

- (BOOL)isValid
{
    return (self.object != nil);
}

+ (instancetype)weakPointerWithObject:(id)object
{
    HSWeakPointer* pointer = [[[self class] alloc] init];
    pointer.object = object;
    
    return pointer;
}

@end
