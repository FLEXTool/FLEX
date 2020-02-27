//
//  FLEXKeyPathToolbar.m
//  FLEX
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

+ (instancetype)toolbarWithHandler:(TBToolbarAction)tapHandler suggestions:(NSArray<NSString *> *)suggestions {
    NSArray *buttons = [self
        buttonsForKeyPath:TBKeyPath.empty suggestions:suggestions handler:tapHandler
    ];

    TBKeyPathToolbar *me = [self toolbarWithButtons:buttons];
    me.tapHandler = tapHandler;
    return me;
}

+ (NSArray<TBToolbarButton*> *)buttonsForKeyPath:(TBKeyPath *)keyPath
                                     suggestions:(NSArray<NSString *> *)suggestions
                                         handler:(TBToolbarAction)handler {
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
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"*" action:handler]];
                [buttons addObject:[TBToolbarButton buttonWithTitle:@"*." action:handler]];
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
                }
            }

            else if (lastKey.options & TBWildcardOptionsSuffix) {
                if (!lastKeyIsMethod) {
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"*" action:handler]];
                    [buttons addObject:[TBToolbarButton buttonWithTitle:@"*." action:handler]];
                }
            }
        }
    }
    
    for (NSString *suggestion in suggestions) {
        [buttons addObject:[TBToolbarSuggestedButton buttonWithTitle:suggestion action:handler]];
    }

    return buttons;
}

- (void)setKeyPath:(TBKeyPath *)keyPath suggestions:(NSArray<NSString *> *)suggestions {
    self.buttons = [self.class
        buttonsForKeyPath:keyPath suggestions:suggestions handler:self.tapHandler
    ];
}

@end
