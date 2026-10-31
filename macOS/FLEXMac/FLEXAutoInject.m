//
//  FLEXAutoInject.m
//  FLEX (macOS)
//
//  Lets FLEX.framework's binary double as an injectable dylib. When the
//  framework is loaded into a host process via DYLD_INSERT_LIBRARIES with
//  the FLEX_AUTO_SHOW environment variable set, FLEX attaches itself to the
//  host's AppKit interface automatically.
//
//  This is inert in normal use: without FLEX_AUTO_SHOW the constructor returns
//  immediately, so linking FLEX the usual way behaves exactly as before.
//

#import <AppKit/AppKit.h>
#import "FLEXManager.h"

// FLEX_AUTO_SHOW controls what happens on injection:
//   unset  -> do nothing (normal linking)
//   "0"    -> install the "Explore with FLEX" menu item, but stay hidden
//   "1"    -> also show the FLEX toolbar immediately
static NSString * const kFLEXAutoShowEnvKey = @"FLEX_AUTO_SHOW";

static void FLEXAutoInjectPresent(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *value = getenv(kFLEXAutoShowEnvKey.UTF8String);
        BOOL show = value && atoi(value) != 0;

        // Start recording network traffic by default so injected apps trace
        // out of the box. Set FLEX_NO_NETWORK=1 to opt out.
        if (!getenv("FLEX_NO_NETWORK")) {
            FLEXManager.sharedManager.networkDebuggingEnabled = YES;
        }

        [FLEXManager.sharedManager installMainMenuItem];
        if (show) {
            [FLEXManager.sharedManager showExplorer];
        }

        NSLog(@"[FLEX] Injected into %@ (pid %d). Press ⌥⌘F or use the menu to toggle FLEX.",
              NSProcessInfo.processInfo.processName, NSProcessInfo.processInfo.processIdentifier);
    });
}

__attribute__((constructor))
static void FLEXAutoInject(void) {
    @autoreleasepool {
        // Only act when explicitly injected; never interfere with apps that
        // simply link FLEX and drive it themselves.
        if (!getenv(kFLEXAutoShowEnvKey.UTF8String)) {
            return;
        }

        // The framework loads before the host builds its NSApplication, so
        // wait for the app to finish launching. Also arm a fallback in case
        // the host sets up AppKit without posting the usual notification.
        __block id observer = [NSNotificationCenter.defaultCenter
            addObserverForName:NSApplicationDidFinishLaunchingNotification
            object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                FLEXAutoInjectPresent();
                if (observer) {
                    [NSNotificationCenter.defaultCenter removeObserver:observer];
                    observer = nil;
                }
            }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (NSApp) {
                FLEXAutoInjectPresent();
            }
        });
    }
}
