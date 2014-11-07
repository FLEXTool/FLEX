//
//  NSString+Validation.m
//

@implementation NSString (Validation)

- (BOOL)isValidEmail
{
    return [self isValidEmailWithStrictFilter:YES];
}

- (BOOL)isValidEmailWithStrictFilter:(BOOL)strict
{
    //
    // Discussion http://stackoverflow.com/questions/3139619/check-that-an-email-address-is-valid-on-ios
    //
    
    BOOL stricterFilter = strict;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:self];
}
@end
