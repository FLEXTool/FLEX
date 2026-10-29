#import <UIKit/UIKit.h>
#import "FLEXManager.h"

static BOOL FLEXLoaderDidShowExplorer = NO;

static void FLEXLoaderShowExplorer(void) {
    if (FLEXLoaderDidShowExplorer) {
        return;
    }

    FLEXLoaderDidShowExplorer = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[FLEXManager sharedManager] showExplorer];
    });
}

%ctor {
    if (NSProcessInfo.processInfo.environment[@"FLEX_LOADER_DISABLED"]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *application = UIApplication.sharedApplication;
        if (application.applicationState != UIApplicationStateBackground) {
            FLEXLoaderShowExplorer();
        }

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:NSOperationQueue.mainQueue
                                                      usingBlock:^(__unused NSNotification *notification) {
            FLEXLoaderShowExplorer();
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:NSOperationQueue.mainQueue
                                                      usingBlock:^(__unused NSNotification *notification) {
            FLEXLoaderShowExplorer();
        }];
    });
}
