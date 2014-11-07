#import "HSMath.h"

#define ARC4RANDOM_MAX 0x100000000

@implementation HSMath

+ (double)degreesToRadians:(double)angle
{
    return (angle / 180.0 * M_PI);
}

+ (double)radiansToDegrees:(double)radians
{
    return (radians * 180.0 / M_PI);
}

+ (double)random
{
    return (double)arc4random() / ARC4RANDOM_MAX;
}

+ (double)randomBetweenMin:(double)min max:(double)max
{
    return ((max - min) * [self random]) + min;
}

+ (NSInteger)randomIntegerBetweenMin:(NSInteger)min max:(NSInteger)max
{
    NSInteger scope = max + 1 - min;
    
    NSInteger rand = arc4random_uniform((u_int32_t)scope);
    
    return (min + rand);
}

+ (NSInteger)greatestCommonDivisorForA:(NSInteger)a b:(NSInteger)b
{
    NSInteger t;
    NSInteger r;
    
    if (a < b)
    {
        t = a;
        a = b;
        b = t;
    }
    
    r = a % b;
    
    if (r == 0)
    {
        return b;
    }
    else
    {
        return [self greatestCommonDivisorForA:b b:r];
    }
}

@end
