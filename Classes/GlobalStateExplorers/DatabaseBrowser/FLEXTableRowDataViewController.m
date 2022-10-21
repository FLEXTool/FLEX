//
//  FLEXTableRowDataViewController.m
//  FLEX
//
//  Created by Chaoshuai Lu on 7/8/20.
//

#import "FLEXTableRowDataViewController.h"
#import "FLEXMutableListSection.h"
#import "FLEXAlert.h"

@interface FLEXTableRowDataViewController ()
@property (nonatomic) NSDictionary<NSString *, NSString *> *rowsByColumn;
@end

@implementation FLEXTableRowDataViewController

#pragma mark - Initialization

+ (instancetype)rows:(NSDictionary<NSString *, id> *)rowData {
    FLEXTableRowDataViewController *controller = [self new];
    controller.rowsByColumn = rowData;
    return controller;
}

#pragma mark - Overrides

- (NSArray<FLEXTableViewSection *> *)makeSections {
    NSDictionary<NSString *, NSString *> *rowsByColumn = self.rowsByColumn;
    
    FLEXMutableListSection<NSString *> *section = [FLEXMutableListSection list:self.rowsByColumn.allKeys
        cellConfiguration:^(UITableViewCell *cell, NSString *column, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = column;
            cell.detailTextLabel.text = rowsByColumn[column].description;
        } filterMatcher:^BOOL(NSString *filterText, NSString *column) {
            return [column localizedCaseInsensitiveContainsString:filterText] ||
                [rowsByColumn[column] localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    section.selectionHandler = ^(UIViewController *host, NSString *column) {
        UIPasteboard.generalPasteboard.string = rowsByColumn[column].description;
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(@"Column Copied to Clipboard");
            make.message(rowsByColumn[column].description);
            make.button(@"Dismiss").cancelStyle();
        } showFrom:host];
    };

    return @[section];
}

@end
