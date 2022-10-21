//
//  FLEXWindowShortcuts.m
//  FLEX
//
//  Created by AnthoPak on 26/09/2022.
//

#import "FLEXWindowShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXObjectExplorerViewController.h"

@implementation FLEXWindowShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIView *)view {
    return [self forObject:view additionalRows:@[
        [FLEXActionShortcut title:@"Animation Speed" subtitle:^NSString *(UIWindow *window) {
            return [NSString stringWithFormat:@"Current speed: %.2f", window.layer.speed];
        } selectionHandler:^(UIViewController *host, UIWindow *window) {
            [FLEXAlert makeAlert:^(FLEXAlert *make) {
                make.title(@"Change Animation Speed");
                make.message([NSString stringWithFormat:@"Current speed: %.2f", window.layer.speed]);
                make.configuredTextField(^(UITextField * _Nonnull textField) {
                    textField.placeholder = @"Default: 1.0";
                    textField.keyboardType = UIKeyboardTypeDecimalPad;
                });
                
                make.button(@"OK").handler(^(NSArray<NSString *> *strings) {
                    CGFloat speedValue = strings.firstObject.floatValue;
                    window.layer.speed = speedValue;

                    // Refresh the host view controller to update the shortcut subtitle, reflecting current speed
                    // TODO: this shouldn't be necessary
                    [(FLEXObjectExplorerViewController *)host reloadData];
                });
                make.button(@"Cancel").cancelStyle();
            } showFrom:host];
        } accessoryType:^UITableViewCellAccessoryType(id  _Nonnull object) {
            return UITableViewCellAccessoryDisclosureIndicator;
        }]
    ]];
}

@end
