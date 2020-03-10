//
//  FLEXRuntimeBrowserToolbar.m
//  FLEX
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXRuntimeBrowserToolbar.h"
#import "FLEXRuntimeKeyPathTokenizer.h"

@interface FLEXRuntimeBrowserToolbar ()
@property (nonatomic, copy) FLEXKBToolbarAction tapHandler;
@end

@implementation FLEXRuntimeBrowserToolbar

+ (instancetype)toolbarWithHandler:(FLEXKBToolbarAction)tapHandler suggestions:(NSArray<NSString *> *)suggestions {
    NSArray *buttons = [self
        buttonsForKeyPath:FLEXRuntimeKeyPath.empty suggestions:suggestions handler:tapHandler
    ];

    FLEXRuntimeBrowserToolbar *me = [self toolbarWithButtons:buttons];
    me.tapHandler = tapHandler;
    return me;
}

+ (NSArray<FLEXKBToolbarButton*> *)buttonsForKeyPath:(FLEXRuntimeKeyPath *)keyPath
                                     suggestions:(NSArray<NSString *> *)suggestions
                                         handler:(FLEXKBToolbarAction)handler {
    NSMutableArray *buttons = [NSMutableArray new];
    FLEXSearchToken *lastKey = nil;
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
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"-" action:handler]];
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"+" action:handler]];
                }
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
            } else {
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
            }
            break;

        default: {
            if (lastKey.options & TBWildcardOptionsPrefix) {
                if (lastKeyIsMethod) {
                    if (lastKey.string.length) {
                        [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    }
                } else {
                    if (lastKey.string.length) {
                        [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
                    }
                }
            }

            else if (lastKey.options & TBWildcardOptionsSuffix) {
                if (!lastKeyIsMethod) {
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
                }
            }
        }
    }
    
    for (NSString *suggestion in suggestions) {
        [buttons addObject:[FLEXKBToolbarSuggestedButton buttonWithTitle:suggestion action:handler]];
    }

    return buttons;
}

- (void)setKeyPath:(FLEXRuntimeKeyPath *)keyPath suggestions:(NSArray<NSString *> *)suggestions {
    self.buttons = [self.class
        buttonsForKeyPath:keyPath suggestions:suggestions handler:self.tapHandler
    ];
}

@end
