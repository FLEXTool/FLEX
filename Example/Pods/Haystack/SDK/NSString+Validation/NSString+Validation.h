//
//  NSString+Validation.h
//

@interface NSString (Validation)

- (BOOL)isValidEmail;

- (BOOL)isValidEmailWithStrictFilter:(BOOL)strict;

@end
