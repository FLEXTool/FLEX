//
//  TBKeyPathToolbar.m
//  TBTweakViewController
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyPathToolbar.h"
#import "TBKeyPathTokenizer.h"


@interface TBKeyPathToolbar ()
@property (nonatomic, copy) TBToolbarAction tapHandler;
@end

@implementation TBKeyPathToolbar

+ (instancetype)toolbarWithHandler:(TBToolbarAction)tapHandler {
    TBKeyPath *emptyKeyPath = [TBKeyPathTokenizer tokenizeString:@""];
    NSArray *buttons = [self buttonsForKeyPath:emptyKeyPath handler:tapHandler];

    TBKeyPathToolbar *me = [self toolbarWithButtons:buttons];
    me.tapHandler = tapHandler;
    return me;
}

+ (NSArray<TBToolbarButton*> *)buttonsForKeyPath:(TBKeyPath *)keyPath handler:(TBToolbarAction)handler {
    NSMutableArray *buttons = [NSMutableArray array];
    TBToken *lastKey = nil;
    BOOL lastKeyIsMethod = NO;

    if (keyPath.methodKey) {
        lastKey = keyPath.methodKey;
        lastKeyIsMethod = YES;
    } else {
        lastKey = keyPath.classKey ?: keyPath.bundleKey;
    }

    switch (lastKey.options) {
        case TBWildcardOptionsNone:
        case TBWildcardOptionsAny:
            if (lastKeyIsMethod) {
                if (!keyPath.instanceMethods) {
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"-" action:handler]];
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"+" action:handler]];
                }
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"*" action:handler]];
            } else {
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"*." action:handler]];
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"*" action:handler]];
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"." action:handler]];
            }
            break;

        default: {
            if (lastKey.options & TBWildcardOptionsPrefix) {
                if (lastKeyIsMethod) {
                    if (lastKey.string.length) {
                        [buttons addObject:[TBToolbarButton buttonWithTitle:@"*" action:handler]];
                    }
                } else {
                    if (lastKey.string.length) {
                        [buttons addObject:[TBToolbarButton buttonWithTitle:@"*." action:handler]];
                    }
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"." action:handler]];
                }
            }

            else if (lastKey.options & TBWildcardOptionsSuffix) {
                if (!lastKeyIsMethod) {
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"*." action:handler]];
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"." action:handler]];
                }
            }
        }
    }

    return buttons;
}

- (void)setKeyPath:(TBKeyPath *)keyPath animated:(BOOL)animated {
    NSArray *buttons = [TBKeyPathToolbar buttonsForKeyPath:keyPath handler:self.tapHandler];
    [self setButtons:buttons animated:animated];
}

@end
