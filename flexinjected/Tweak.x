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

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (id)defaultCenter;
- (void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
- (void)postNotificationName:(id)arg1 object:(id)arg2 userInfo:(id)arg3;
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

@interface LSApplicationProxy: NSObject
+(id)applicationProxyForIdentifier:(id)sender;
+(id)tv_applicationFlatIcon;
-(BOOL)isContainerized;
@end

@implementation NSObject (Additions)
- (UIViewController *)topViewController {
    return [[[UIApplication sharedApplication] keyWindow] visibleViewController];
}
@end

static void sendNotification(NSString *title, NSString *message, UIImage *image) {

    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"message"] = message;
    dict[@"title"] = title;
    dict[@"timeout"] = [NSNumber numberWithInteger:4];
    if (image){
        NSData *imageData = UIImagePNGRepresentation(image);
        if (imageData){
            dict[@"imageData"] = imageData;
        }
    }
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.nito.bulletinh4x/displayBulletin" object:nil userInfo:dict];
}

// The dylib constructor sets decryptedIPAPath, spawns a thread to do the app decryption, then exits.
__attribute__ ((constructor)) static void FLEXInjected_main() {
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleID = [bundle bundleIdentifier];
    NSDictionary *ourDict = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.nito.flexinjected.plist"];
    NSNumber *value = [ourDict objectForKey:bundleID];
    if ([value boolValue] == YES) {
    BOOL sendAlert = true;
    id prox = [%c(LSApplicationProxy) applicationProxyForIdentifier:bundleID];
      UIImage *icon = nil;
      if (prox){
          NSLog(@"[FLEXInjected] found prox: %@", prox);
          if ([prox isContainerized]){
            sendAlert = false;
          } else {
                icon = [prox tv_applicationFlatIcon];
          }
      } else {
          NSString *mcsPath = @"/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices";
          [[NSBundle bundleWithPath:mcsPath] load];
          prox = [%c(LSApplicationProxy) applicationProxyForIdentifier:bundleID];
          if ([prox isContainerized]){
            sendAlert = false;
          } else {
            icon = [prox tv_applicationFlatIcon];
           }
      }
      if (sendAlert){
        NSString *message = [NSString stringWithFormat:@"Injected into bundle: %@", bundleID];
        sendNotification(@"FlexInjected", message, icon);
        NSLog(@"[FLEXInjected) bundle ID %@", bundleID);
      }
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
        
    }
}

