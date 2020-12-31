//
//  FLEXBundleShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXBundleShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXRuntimeExporter.h"
#import "FLEXTableListViewController.h"
#import "FLEXFileBrowserController.h"

#pragma mark -
@implementation FLEXBundleShortcuts
#pragma mark Overrides

+ (instancetype)forObject:(NSBundle *)bundle {
    __weak __typeof(self) weakSelf = self;
    return [self forObject:bundle additionalRows:@[
        [FLEXActionShortcut
            title:@"Browse Bundle Directory" subtitle:nil
            viewer:^UIViewController *(NSBundle *bundle) {
                return [FLEXFileBrowserController path:bundle.bundlePath];
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"Browse Bundle as Database…" subtitle:nil
            selectionHandler:^(UIViewController *host, NSBundle *bundle) {
                __strong __typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf promptToExportBundleAsDatabase:bundle host:host];
                }
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
    ]];
}

+ (void)promptToExportBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Save As…").message(
            @"The database be saved in the Library folder. "
            "Depending on the number of classes, it may take "
            "10 minutes or more to finish exporting. 20,000 "
            "classes takes about 7 minutes."
        );
        make.configuredTextField(^(UITextField *field) {
            field.placeholder = @"FLEXRuntimeExport.objc.db";
            field.text = [NSString stringWithFormat:
                @"%@.objc.db", bundle.executablePath.lastPathComponent
            ];
        });
        make.button(@"Start").handler(^(NSArray<NSString *> *strings) {
            [self browseBundleAsDatabase:bundle host:host name:strings[0]];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:host];
}

+ (void)browseBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host name:(NSString *)name {
    NSParameterAssert(name.length);

    UIAlertController *progress = [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Generating Database");
        // Some iOS version glitch out of there is
        // no initial message and you add one later
        make.message(@"…");
    }];

    [host presentViewController:progress animated:YES completion:^{
        // Generate path to store db
        NSString *path = [NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory, NSUserDomainMask, YES
        )[0] stringByAppendingPathComponent:name];

        progress.message = [path stringByAppendingString:@"\n\nCreating database…"];

        // Generate db and show progress
        [FLEXRuntimeExporter createRuntimeDatabaseAtPath:path
            forImages:@[bundle.executablePath]
            progressHandler:^(NSString *status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress.message = [progress.message
                        stringByAppendingFormat:@"\n%@", status
                    ];
                    [progress.view setNeedsLayout];
                    [progress.view layoutIfNeeded];
                });
            } completion:^(NSString *error) {
                // Display error if any
                if (error) {
                    progress.title = @"Error";
                    progress.message = error;
                    [progress addAction:[UIAlertAction
                        actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]
                    ];
                }
                // Browse database
                else {
                    [progress dismissViewControllerAnimated:YES completion:nil];
                    [host.navigationController pushViewController:[
                        [FLEXTableListViewController alloc] initWithPath:path
                    ] animated:YES];
                }
            }
        ];
    }];
}

@end
