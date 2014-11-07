//
//  NSString+Additional.m
//

@implementation NSString (Additional)

- (BOOL)endsWith:(NSString *)string
{
    return [self hasSuffix:string];
}

- (BOOL)startsWith:(NSString *)string
{
    return [self hasPrefix:string];
}

@end