//
//  UIFont+SmallCaps.m
//

#import <CoreText/CoreText.h>

#import "UIFont+SmallCaps.h"

@implementation UIFont (SmallCaps)

- (UIFont *)smallCapFont
{
    UIFontDescriptor *descriptor = [self fontDescriptor];
    
    NSArray *array = @[@{UIFontFeatureTypeIdentifierKey : @(kLowerCaseType), UIFontFeatureSelectorIdentifierKey : @(kLowerCaseSmallCapsSelector)}];
    
    descriptor = [descriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute : array}];
    return [UIFont fontWithDescriptor:descriptor size:0];
}

- (BOOL)isSystemFont
{
    return ([self.familyName isEqualToString:[UIFont systemFontOfSize:12.0f].familyName]) ? YES : NO;
}

- (BOOL)hasSmallCaps
{
    CFArrayRef  fontProperties  =  CTFontCopyFeatures ( ( __bridge CTFontRef ) self ) ;

    NSArray* array = (__bridge NSArray*)fontProperties;
    
    for (NSDictionary* item in array)
    {
        for (id selector in item[@"CTFeatureTypeSelectors"])
        {
            id selectorInfo = selector[@"CTFeatureSelectorName"];
            
            if ([selectorInfo isKindOfClass:[NSString class]] && [selectorInfo isEqualToString:@"Small Capitals"])
            {
                CFRelease(fontProperties);
                
                return YES;
            }
        }
        
    }
    
    CFRelease(fontProperties);
    
    return NO;
}

@end
