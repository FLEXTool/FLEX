//
//  FLEXShortcutsFactory+Defaults.m
//  FLEX
//
//  Created by Tanner Bennett on 8/29/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXShortcutsFactory+Defaults.h"
#import "FLEXShortcut.h"
#import "FLEXRuntimeUtility.h"
#import "NSObject+FLEX_Reflection.h"

#pragma mark - UIApplication

@implementation FLEXShortcutsFactory (UIApplication)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    // sharedApplication class property possibly not added
    // as a literal class property until iOS 10
    FLEXRuntimeUtilityTryAddObjectProperty(
        2, sharedApplication, UIApplication.flex_metaclass, UIApplication, PropertyKey(ReadOnly)
    );
    
    self.append.classProperties(@[@"sharedApplication"]).forClass(UIApplication.flex_metaclass);
    self.append.properties(@[
        @"delegate", @"keyWindow", @"windows"
    ]).forClass(UIApplication.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[
            @"connectedScenes", @"openSessions", @"supportsMultipleScenes"
        ]).forClass(UIApplication.class);
    }
}

@end

#pragma mark - Views

@implementation FLEXShortcutsFactory (Views)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    // A quirk of UIView and some other classes: a lot of the `@property`s are
    // not actually properties from the perspective of the runtime.
    //
    // We add these properties to the class at runtime if they haven't been added yet.
    // This way, we can use our property editor to access and change them.
    // The property attributes match the declared attributes in their headers.

    // UIView, public
    Class UIView_ = UIView.class;
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, frame, UIView_, CGRect);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, alpha, UIView_, CGFloat);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, clipsToBounds, UIView_, BOOL);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, opaque, UIView_, BOOL, PropertyKeyGetter(isOpaque));
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, hidden, UIView_, BOOL, PropertyKeyGetter(isHidden));
    FLEXRuntimeUtilityTryAddObjectProperty(2, backgroundColor, UIView_, UIColor, PropertyKey(Copy));
    FLEXRuntimeUtilityTryAddObjectProperty(6, constraints, UIView_, NSArray, PropertyKey(ReadOnly));
    FLEXRuntimeUtilityTryAddObjectProperty(2, subviews, UIView_, NSArray, PropertyKey(ReadOnly));
    FLEXRuntimeUtilityTryAddObjectProperty(2, superview, UIView_, UIView, PropertyKey(ReadOnly));

    // UIButton, private
    FLEXRuntimeUtilityTryAddObjectProperty(2, font, UIButton.class, UIFont, PropertyKey(ReadOnly));
    
    // Only available since iOS 3.2, but we never supported iOS 3, so who cares
    NSArray *ivars = @[@"_gestureRecognizers"];
    NSArray *methods = @[@"sizeToFit", @"setNeedsLayout", @"removeFromSuperview"];

    // UIView
    self.append.ivars(ivars).methods(methods).properties(@[
        @"frame", @"bounds", @"center", @"transform",
        @"backgroundColor", @"alpha", @"opaque", @"hidden",
        @"clipsToBounds", @"userInteractionEnabled", @"layer",
        @"superview", @"subviews"
    ]).forClass(UIView.class);

    // UILabel
    self.append.ivars(ivars).methods(methods).properties(@[
        @"text", @"attributedText", @"font", @"frame",
        @"textColor", @"textAlignment", @"numberOfLines",
        @"lineBreakMode", @"enabled", @"backgroundColor",
        @"alpha", @"hidden", @"preferredMaxLayoutWidth",
        @"superview", @"subviews"
    ]).forClass(UILabel.class);

    // UIWindow
    self.append.ivars(ivars).properties(@[
        @"rootViewController", @"windowLevel", @"keyWindow",
        @"frame", @"bounds", @"center", @"transform",
        @"backgroundColor", @"alpha", @"opaque", @"hidden",
        @"clipsToBounds", @"userInteractionEnabled", @"layer",
        @"subviews"
    ]).forClass(UIWindow.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[@"windowScene"]).forClass(UIWindow.class);
    }

    ivars = @[@"_targetActions", @"_gestureRecognizers"];
    
    // Property was added in iOS 10 but we want it on iOS 9 too
    FLEXRuntimeUtilityTryAddObjectProperty(9, allTargets, UIControl.class, NSArray, PropertyKey(ReadOnly));

    // UIControl
    self.append.ivars(ivars).methods(methods).properties(@[
        @"enabled", @"allTargets", @"frame",
        @"backgroundColor", @"hidden", @"clipsToBounds",
        @"userInteractionEnabled", @"superview", @"subviews"
    ]).forClass(UIControl.class);

    // UIButton
    self.append.ivars(ivars).properties(@[
        @"titleLabel", @"font", @"imageView", @"tintColor",
        @"currentTitle", @"currentImage", @"enabled", @"frame",
        @"superview", @"subviews"
    ]).forClass(UIButton.class);
    
    // UIImageView
    self.append.properties(@[
        @"image", @"animationImages", @"frame", @"bounds", @"center",
        @"transform", @"alpha", @"hidden", @"clipsToBounds",
        @"userInteractionEnabled", @"layer", @"superview", @"subviews",
    ]).forClass(UIImageView.class);
}

@end


#pragma mark - View Controllers

@implementation FLEXShortcutsFactory (ViewControllers)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    // toolbarItems is not really a property, make it one 
    FLEXRuntimeUtilityTryAddObjectProperty(3, toolbarItems, UIViewController.class, NSArray);
    
    // UIViewController
    self.append
        .properties(@[
            @"viewIfLoaded", @"title", @"navigationItem", @"toolbarItems", @"tabBarItem",
            @"childViewControllers", @"navigationController", @"tabBarController", @"splitViewController",
            @"parentViewController", @"presentedViewController", @"presentingViewController",
        ]).methods(@[@"view"]).forClass(UIViewController.class);
}

@end


#pragma mark - UIImage

@implementation FLEXShortcutsFactory (UIImage)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    self.append.methods(@[
        @"CGImage", @"CIImage"
    ]).properties(@[
        @"scale", @"size", @"capInsets",
        @"alignmentRectInsets", @"duration", @"images"
    ]).forClass(UIImage.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[@"symbolImage"]).forClass(UIImage.class);
    }
}

@end


#pragma mark - NSBundle

@implementation FLEXShortcutsFactory (NSBundle)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    self.append.properties(@[
        @"bundleIdentifier", @"principalClass",
        @"infoDictionary", @"bundlePath",
        @"executablePath", @"loaded"
    ]).forClass(NSBundle.class);
}

@end


#pragma mark - Classes

@implementation FLEXShortcutsFactory (Classes)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    self.append.classMethods(@[@"new", @"alloc"]).forClass(NSObject.flex_metaclass);
}

@end


#pragma mark - Activities

@implementation FLEXShortcutsFactory (Activities)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    // Property was added in iOS 10 but we want it on iOS 9 too
    FLEXRuntimeUtilityTryAddNonatomicProperty(9, item, UIActivityItemProvider.class, id, PropertyKey(ReadOnly));
    
    self.append.properties(@[
        @"item", @"placeholderItem", @"activityType"
    ]).forClass(UIActivityItemProvider.class);

    self.append.properties(@[
        @"activityItems", @"applicationActivities", @"excludedActivityTypes", @"completionHandler"
    ]).forClass(UIActivityViewController.class);
}

@end


#pragma mark - Blocks

@implementation FLEXShortcutsFactory (Blocks)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    self.append.methods(@[@"invoke"]).forClass(NSClassFromString(@"NSBlock"));
}

@end

#pragma mark - Foundation

@implementation FLEXShortcutsFactory (Foundation)

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    self.append.properties(@[
        @"configuration", @"delegate", @"delegateQueue", @"sessionDescription",
    ]).methods(@[
        @"dataTaskWithURL:", @"finishTasksAndInvalidate", @"invalidateAndCancel",
    ]).forClass(NSURLSession.class);
    
    self.append.methods(@[
        @"cachedResponseForRequest:", @"storeCachedResponse:forRequest:",
        @"storeCachedResponse:forDataTask:", @"removeCachedResponseForRequest:",
        @"removeCachedResponseForDataTask:", @"removeCachedResponsesSinceDate:",
        @"removeAllCachedResponses",
    ]).forClass(NSURLCache.class);
    
    
    self.append.methods(@[
        @"postNotification:", @"postNotificationName:object:userInfo:",
        @"addObserver:selector:name:object:", @"removeObserver:",
        @"removeObserver:name:object:",
    ]).forClass(NSNotificationCenter.class);
    
    // NSTimeZone class properties aren't real properties
    FLEXRuntimeUtilityTryAddObjectProperty(2, localTimeZone, NSTimeZone.flex_metaclass, NSTimeZone);
    FLEXRuntimeUtilityTryAddObjectProperty(2, systemTimeZone, NSTimeZone.flex_metaclass, NSTimeZone);
    FLEXRuntimeUtilityTryAddObjectProperty(2, defaultTimeZone, NSTimeZone.flex_metaclass, NSTimeZone);
    FLEXRuntimeUtilityTryAddObjectProperty(2, knownTimeZoneNames, NSTimeZone.flex_metaclass, NSArray);
    FLEXRuntimeUtilityTryAddObjectProperty(2, abbreviationDictionary, NSTimeZone.flex_metaclass, NSDictionary);
    
    self.append.classMethods(@[
        @"timeZoneWithName:", @"timeZoneWithAbbreviation:", @"timeZoneForSecondsFromGMT:", @"", @"", @"", 
    ]).forClass(NSTimeZone.flex_metaclass);
    
    self.append.classProperties(@[
        @"defaultTimeZone", @"systemTimeZone", @"localTimeZone"
    ]).forClass(NSTimeZone.class);
}

@end
