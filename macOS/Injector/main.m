//
//  main.m
//  FLEX Injector
//

#import <Cocoa/Cocoa.h>
#import "InjectorAppDelegate.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        InjectorAppDelegate *delegate = [InjectorAppDelegate new];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        return NSApplicationMain(argc, argv);
    }
}
