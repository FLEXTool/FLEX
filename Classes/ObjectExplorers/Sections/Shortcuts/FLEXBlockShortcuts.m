//
// FLEXBlockShortcuts.m
//  FLEX
//
//  Created by Tanner on 1/30/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXBlockShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXBlockDescription.h"
#import "FLEXObjectExplorerFactory.h"

#pragma mark - 
@implementation FLEXBlockShortcuts

#pragma mark Overrides

+ (instancetype)forObject:(id)block {
    NSParameterAssert([block isKindOfClass:NSClassFromString(@"NSBlock")]);
    
    FLEXBlockDescription *blockInfo = [FLEXBlockDescription describing:block];
    NSMethodSignature *signature = blockInfo.signature;
    NSArray *blockShortcutRows = @[blockInfo.summary];
    
    if (signature) {
        blockShortcutRows = @[
            blockInfo.summary,
            blockInfo.sourceDeclaration,
            signature.debugDescription,
            [FLEXActionShortcut title:@"View Method Signature"
                subtitle:^NSString *(id block) {
                    return signature.description ?: @"unsupported signature";
                }
                viewer:^UIViewController *(id block) {
                    return [FLEXObjectExplorerFactory explorerViewControllerForObject:signature];
                }
                accessoryType:^UITableViewCellAccessoryType(id view) {
                    if (signature) {
                        return UITableViewCellAccessoryDisclosureIndicator;
                    }
                    return UITableViewCellAccessoryNone;
                }
            ]
        ];
    }
    
    return [self forObject:block additionalRows:blockShortcutRows];
}

- (NSString *)title {
    return @"Metadata";
}

- (NSInteger)numberOfLines {
    return 0;
}

@end
