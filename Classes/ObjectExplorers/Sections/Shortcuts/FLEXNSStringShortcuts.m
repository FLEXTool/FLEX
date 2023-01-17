//
//  FLEXNSStringShortcuts.m
//  FLEX
//
//  Created by Tanner on 3/29/21.
//

#import "Classes/ObjectExplorers/Sections/Shortcuts/FLEXNSStringShortcuts.h"
#import "Classes/Headers/FLEXObjectExplorerFactory.h"
#import "Classes/Headers/FLEXShortcut.h"

@implementation FLEXNSStringShortcuts

+ (instancetype)forObject:(NSString *)string {
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytesNoCopy:(void *)string.UTF8String length:length freeWhenDone:NO];
    
    return [self forObject:string additionalRows:@[
        [FLEXActionShortcut title:@"UTF-8 Data" subtitle:^NSString *(id _) {
            return data.description;
        } viewer:^UIViewController *(id _) {
            return [FLEXObjectExplorerFactory explorerViewControllerForObject:data];
        } accessoryType:^UITableViewCellAccessoryType(id _) {
            return UITableViewCellAccessoryDisclosureIndicator;
        }]
    ]];
}

@end
