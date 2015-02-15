//
//  FLEXUtility.m
//  Flipboard
//
//  Created by Ryan Olson on 4/18/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXUtility.h"
#import "FLEXResources.h"
#import <ImageIO/ImageIO.h>

@implementation FLEXUtility

+ (UIColor *)consistentRandomColorForObject:(id)object
{
    CGFloat hue = (((NSUInteger)object >> 4) % 256) / 255.0;
    return [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
}

+ (NSString *)descriptionForView:(UIView *)view includingFrame:(BOOL)includeFrame
{
    NSString *description = [[view class] description];
    
    NSString *viewControllerDescription = [[[self viewControllerForView:view] class] description];
    if ([viewControllerDescription length] > 0) {
        description = [description stringByAppendingFormat:@" (%@)", viewControllerDescription];
    }
    
    if (includeFrame) {
        description = [description stringByAppendingFormat:@" %@", [self stringForCGRect:view.frame]];
    }
    
    if ([view.accessibilityLabel length] > 0) {
        description = [description stringByAppendingFormat:@" · %@", view.accessibilityLabel];
    }
    
    return description;
}

+ (NSString *)stringForCGRect:(CGRect)rect
{
    return [NSString stringWithFormat:@"{(%g, %g), (%g, %g)}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

+ (UIViewController *)viewControllerForView:(UIView *)view
{
    UIViewController *viewController = nil;
    SEL viewDelSel = NSSelectorFromString([NSString stringWithFormat:@"%@ewDelegate", @"_vi"]);
    if ([view respondsToSelector:viewDelSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        viewController = [view performSelector:viewDelSel];
#pragma clang diagnostic pop
    }
    return viewController;
}

+ (NSString *)detailDescriptionForView:(UIView *)view
{
    return [NSString stringWithFormat:@"frame %@", [self stringForCGRect:view.frame]];
}

+ (UIImage *)circularImageWithColor:(UIColor *)color radius:(CGFloat)radius
{
    CGFloat diameter = radius * 2.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), NO, 0.0);
    CGContextRef imageContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(imageContext, [color CGColor]);
    CGContextFillEllipseInRect(imageContext, CGRectMake(0, 0, diameter, diameter));
    UIImage *circularImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return circularImage;
}

+ (UIColor *)scrollViewGrayColor
{
    return [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
}

+ (UIColor *)hierarchyIndentPatternColor
{
    static UIColor *patternColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *indentationPatternImage = [FLEXResources hierarchyIndentPattern];
        patternColor = [UIColor colorWithPatternImage:indentationPatternImage];
    });
    return patternColor;
}

+ (NSString *)applicationImageName
{
    return [[NSBundle mainBundle] executablePath];
}

+ (NSString *)applicationName
{
    return [[[FLEXUtility applicationImageName] componentsSeparatedByString:@"/"] lastObject];
}

+ (NSString *)safeDescriptionForObject:(id)object
{
    // Don't assume that we have an NSObject subclass.
    // Check to make sure the object responds to the description methods.
    NSString *description = nil;
    if ([object respondsToSelector:@selector(debugDescription)]) {
        description = [object debugDescription];
    } else if ([object respondsToSelector:@selector(description)]) {
        description = [object description];
    }
    return description;
}

+ (UIFont *)defaultFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+ (UIFont *)defaultTableViewCellLabelFont
{
    return [self defaultFontOfSize:12.0];
}

+ (NSString *)stringByEscapingHTMLEntitiesInString:(NSString *)originalString
{
    static NSDictionary *escapingDictionary = nil;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        escapingDictionary = @{ @" " : @"&nbsp;",
                                @">" : @"&gt;",
                                @"<" : @"&lt;",
                                @"&" : @"&amp;",
                                @"'" : @"&apos;",
                                @"\"" : @"&quot;",
                                @"«" : @"&laquo;",
                                @"»" : @"&raquo;"
                                };
        regex = [NSRegularExpression regularExpressionWithPattern:@"(&|>|<|'|\"|«|»)" options:0 error:NULL];
    });
    
    NSMutableString *mutableString = [originalString mutableCopy];
    
    NSArray *matches = [regex matchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length])];
    for (NSTextCheckingResult *result in [matches reverseObjectEnumerator]) {
        NSString *foundString = [mutableString substringWithRange:result.range];
        NSString *replacementString = escapingDictionary[foundString];
        if (replacementString) {
            [mutableString replaceCharactersInRange:result.range withString:replacementString];
        }
    }
    
    return [mutableString copy];
}

+ (UIInterfaceOrientationMask)infoPlistSupportedInterfaceOrientationsMask
{
    NSArray *supportedOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
    UIInterfaceOrientationMask supportedOrientationsMask = 0;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskPortrait;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskLandscapeRight"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeRight;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskPortraitUpsideDown"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeLeft;
    }
    return supportedOrientationsMask;
}

+ (NSString *)searchBarPlaceholderText
{
    return @"Filter";
}

+ (BOOL)isImagePathExtension:(NSString *)extension
{
    // https://developer.apple.com/library/ios/documentation/uikit/reference/UIImage_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40006890-CH3-SW3
    return [@[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"] containsObject:extension];
}

+ (UIImage *)thumbnailedImageWithMaxPixelDimension:(NSInteger)dimension fromImageData:(NSData *)data
{
    UIImage *thumbnail = nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, 0);
    if (imageSource) {
        NSDictionary *options = @{ (__bridge id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                   (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                   (__bridge id)kCGImageSourceThumbnailMaxPixelSize : @(dimension) };

        CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        if (scaledImageRef) {
            thumbnail = [UIImage imageWithCGImage:scaledImageRef];
            CFRelease(scaledImageRef);
        }
        CFRelease(imageSource);
    }
    return thumbnail;
}

+ (NSString *)stringFromRequestDuration:(NSTimeInterval)duration
{
    NSString *string = @"0s";
    if (duration > 0.0) {
        if (duration < 1.0) {
            string = [NSString stringWithFormat:@"%dms", (int)(duration * 1000)];
        } else if (duration < 10.0) {
            string = [NSString stringWithFormat:@"%.2fs", duration];
        } else {
            string = [NSString stringWithFormat:@"%.1fs", duration];
        }
    }
    return string;
}

+ (NSString *)statusCodeStringFromURLResponse:(NSURLResponse *)response
{
    NSString *httpResponseString = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *statusCodeDescription = nil;
        if (httpResponse.statusCode == 200) {
            // Prefer OK to the default "no error"
            statusCodeDescription = @"OK";
        } else {
            statusCodeDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
        }
        httpResponseString = [NSString stringWithFormat:@"%ld %@", (long)httpResponse.statusCode, statusCodeDescription];
    }
    return httpResponseString;
}

+ (NSDictionary *)queryDictionaryFromURL:(NSURL *)url
{
    NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionary];

    // [a=1, b=2, c=3]
    NSArray *queryComponents = [url.query componentsSeparatedByString:@"&"];
    for (NSString *keyValueString in queryComponents) {
        // [a, 1]
        NSArray *components = [keyValueString componentsSeparatedByString:@"="];
        if ([components count] == 2) {
            NSString *key = [[components firstObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *value = [[components lastObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [queryDictionary setObject:value forKey:key];
        }
    }

    return queryDictionary;
}

+ (NSString *)prettyJSONStringFromData:(NSData *)data
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
    // NSJSONSerialization escapes forward slashes. We want pretty json, so run through and unescape the slashes.
    return [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
}

@end
