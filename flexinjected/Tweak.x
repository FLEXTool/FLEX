#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <TargetConditionals.h>
@interface NSObject (topViewController)
- (id)topViewController;
@end
@interface FLEXManager: NSObject
+(id)sharedManager;
-(void)showExplorer;
- (void)_addTVOSGestureRecognizer:(UIViewController *)explorer;
@end


@interface UIWindow (Additions)
- (UIViewController *)visibleViewController;
@end

@interface NSObject (Additions)
- (UIViewController *)topViewController;
@end


@implementation UIWindow (Additions)
- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}
+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}
@end

@implementation NSObject (Additions)
- (UIViewController *)topViewController {
    return [[[UIApplication sharedApplication] keyWindow] visibleViewController];
}
@end

// The dylib constructor sets decryptedIPAPath, spawns a thread to do the app decryption, then exits.
__attribute__ ((constructor)) static void FLEXInjected_main() {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleID = [bundle bundleIdentifier];
    NSDictionary *ourDict = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.nito.flexinjected.plist"];
    NSNumber *value = [ourDict objectForKey:bundleID];
    NSLog(@"[FLEXInjected) bundle ID %@", bundleID);
    if ([value boolValue] == YES) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[FLEXInjected] weouchea...");
        NSString *p = @"/Library/Frameworks/FLEX.framework";
        NSBundle *bundle = [NSBundle bundleWithPath:p];
        [bundle load];
        id flexManager = [%c(FLEXManager) sharedManager];
        UIViewController *tvc = [[UIApplication sharedApplication] topViewController];
        if([tvc respondsToSelector: @selector(tabBarController)]){
            UITabBarController *tabBar = [tvc tabBarController];
            if (tabBar) tvc = tabBar;
        }
        NSLog(@"[FLEXInjected] top view controller: %@ violated...", tvc);
        [flexManager _addTVOSGestureRecognizer:tvc];
        [flexManager showExplorer];
    });
      
        NSLog(@"[FLEXInjected] All done, exiting constructor.");
        
    }
}

