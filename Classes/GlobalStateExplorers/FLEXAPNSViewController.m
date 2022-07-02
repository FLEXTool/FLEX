//
//  FLEXAPNSViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 6/28/22.
//  Copyright © 2022 FLEX Team. All rights reserved.
//

#import "FLEXAPNSViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXMutableListSection.h"
#import "FLEXSingleRowSection.h"
#import "NSUserDefaults+FLEX.h"
#import "UIBarButtonItem+FLEX.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"
#import "FLEX-Runtime.h"
#import "flex_fishhook.h"
#import <dlfcn.h>

#define orig(method, ...) if (orig_##method) { orig_##method(__VA_ARGS__); }

@interface FLEXAPNSViewController ()
@property (nonatomic, class) NSData *deviceToken;
@property (nonatomic, class) NSError *registrationError;
@property (nonatomic, readonly, class) NSMutableArray<NSDictionary *> *notifications;

@property (nonatomic) FLEXSingleRowSection *deviceToken;
@property (nonatomic) FLEXMutableListSection<NSDictionary *> *notifications;
@end

@implementation FLEXAPNSViewController

#pragma mark Swizzles

int (*orig_UIApplicationMain)(int argc, char *argv[], NSString *_, NSString *delegateClassName) = nil;
static int flex_apnsHook_UIApplicationMain(int argc, char *argv[], NSString *_, NSString *delegateClassName) {
    [FLEXAPNSViewController hookAppDelegateClass:NSClassFromString(delegateClassName)];
    return orig_UIApplicationMain(argc, argv, _, delegateClassName);
}

+ (void)load { FLEX_EXIT_IF_NO_CTORS()
    if (!NSUserDefaults.standardUserDefaults.flex_enableAPNSCapture) {
        return;
    }
    
    void *uikit = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_LAZY);
    void *uiapplicationmain = dlsym(uikit, "UIApplicationMain");
    if (!uiapplicationmain) {
        return;
    }

    __unused BOOL didHook = flex_rebind_symbols((struct rebinding[1]) {{
        "UIApplicationMain",
        (void *)flex_apnsHook_UIApplicationMain,
        (void **)&orig_UIApplicationMain
    }}, 1) == 0;
}

+ (void)hookAppDelegateClass:(Class)appDelegate {
    auto types_didRegisterForRemoteNotificationsWithDeviceToken = "v@:@@";
    auto types_didFailToRegisterForRemoteNotificationsWithError = "v@:@@";
    auto types_didReceiveRemoteNotification = "v@:@@@?";
    
    auto orig_didRegisterForRemoteNotificationsWithDeviceToken = (void(*)(id, id, id))class_getMethodImplementation(
        appDelegate, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
    );
    auto orig_didFailToRegisterForRemoteNotificationsWithError = (void(*)(id, id, id))class_getMethodImplementation(
        appDelegate, @selector(application:didFailToRegisterForRemoteNotificationsWithError:)
    );
    auto orig_didReceiveRemoteNotification = (void(*)(id, id, id, id))class_getMethodImplementation(
        appDelegate, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
    );
    
    IMP didRegisterForRemoteNotificationsWithDeviceToken = imp_implementationWithBlock(^(id _, id app, NSData *token) {
        self.deviceToken = token;
        orig(didRegisterForRemoteNotificationsWithDeviceToken, _, app, token);
    });
    IMP didFailToRegisterForRemoteNotificationsWithError = imp_implementationWithBlock(^(id _, id app, NSError *error) {
        self.registrationError = error;
        orig(didFailToRegisterForRemoteNotificationsWithError, _, app, error);
    });
    IMP didReceiveRemoteNotification = imp_implementationWithBlock(^(id _, id app, NSDictionary *payload, id handler) {
        // TODO: notify when new notifications are added
        [self.notifications addObject:payload];
        orig(didReceiveRemoteNotification, _, app, payload, handler);
    });
    
    class_replaceMethod(
        appDelegate,
        @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:),
        didRegisterForRemoteNotificationsWithDeviceToken,
        types_didRegisterForRemoteNotificationsWithDeviceToken
    );
    class_replaceMethod(
        appDelegate,
        @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
        didFailToRegisterForRemoteNotificationsWithError,
        types_didFailToRegisterForRemoteNotificationsWithError
    );
    class_replaceMethod(
        appDelegate,
        @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
        didReceiveRemoteNotification,
        types_didReceiveRemoteNotification
    );
}

#pragma mark Class Properties

static NSData *_apnsDeviceToken = nil;
+ (NSData *)deviceToken {
    return _apnsDeviceToken;
}

+ (void)setDeviceToken:(NSData *)deviceToken {
    _apnsDeviceToken = deviceToken;
}

static NSError *_apnsRegistrationError = nil;
+ (NSError *)registrationError {
    return _apnsRegistrationError;
}

+ (void)setRegistrationError:(NSError *)error {
    _apnsRegistrationError = error;
}

+ (NSArray<NSDictionary *> *)notifications {
    static NSMutableArray *_apnsNotifications = nil;
    if (!_apnsNotifications) {
        _apnsNotifications = [NSMutableArray new];
    }
    
    return _apnsNotifications;
}

#pragma mark Instance stuff

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Push Notifications";
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    
    [self addToolbarItems:@[
        [UIBarButtonItem
            flex_itemWithImage:FLEXResources.gearIcon
            target:self
            action:@selector(settingsButtonTapped)
        ],
    ]];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    self.deviceToken = [FLEXSingleRowSection title:@"APNS Device Token" reuse:nil cell:^(UITableViewCell *cell) {
        NSData *token = FLEXAPNSViewController.deviceToken;
        cell.textLabel.text = token ? @(*((NSUInteger *)token.bytes)).stringValue : @"Not yet registered";
        cell.detailTextLabel.text = token.description;
    }];
    self.deviceToken.selectionAction = ^(UIViewController *host) {
        NSData *token = FLEXAPNSViewController.deviceToken;
        if (token) {
            [host.navigationController pushViewController:[
                FLEXObjectExplorerFactory explorerViewControllerForObject:token
            ] animated:YES];
        }
    };
    
    self.notifications = [FLEXMutableListSection list:FLEXAPNSViewController.notifications
        cellConfiguration:^(UITableViewCell *cell, NSDictionary *notif, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            // TODO: date received
//            cell.textLabel.text = [cookie.name stringByAppendingFormat:@" (%@)", cookie.value];
            cell.detailTextLabel.text = notif.description;
        } filterMatcher:^BOOL(NSString *filterText, NSDictionary *notif) {
            return [notif.description localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    self.notifications.customTitle = @"Notifications";
    self.notifications.selectionHandler = ^(UIViewController *host, NSDictionary *notif) {
        [host.navigationController pushViewController:[
            FLEXObjectExplorerFactory explorerViewControllerForObject:notif
        ] animated:YES];
    };
    
    return @[self.deviceToken, self.notifications];
}

- (void)reloadData {
    [self.refreshControl endRefreshing];
    
    self.notifications.customTitle = [NSString stringWithFormat:
        @"%@ notifications", @(self.notifications.filteredList.count)
    ];
    [super reloadData];
}

- (void)settingsButtonTapped {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL enabled = defaults.flex_enableAPNSCapture;

    NSString *apnsToggle = enabled ? @"Disable Capture" : @"Enable Capture";
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Settings")
            .message(@"Enable or disable the capture of push notifications.\n\n")
            .message(@"This will hook UIApplicationMain on launch until it is disabled, ")
            .message(@"and swizzle some app delegate methods. Restart the app for changes to take effect.");
        
        make.button(apnsToggle).destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [defaults flex_toggleBoolForKey:kFLEXDefaultsAPNSCaptureEnabledKey];
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"📌  Push Notifications";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}

@end
