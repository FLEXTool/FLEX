//
//  FLEXKeychainViewController.m
//  FLEX
//
//  Created by ray on 2019/8/17.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXKeychain.h"
#import "FLEXKeychainQuery.h"
#import "FLEXKeychainViewController.h"
#import "FLEXTableViewCell.h"
#import "FLEXMutableListSection.h"
#import "FLEXUtility.h"
#import "UIPasteboard+FLEX.h"
#import "UIBarButtonItem+FLEX.h"

@interface FLEXKeychainViewController ()
@property (nonatomic, readonly) FLEXMutableListSection<NSDictionary *> *section;
@end

@implementation FLEXKeychainViewController

- (id)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[
        [UIBarButtonItem flex_systemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashPressed:)],
        [UIBarButtonItem flex_systemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)],
    ];

    [self reloadData];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _section = [FLEXMutableListSection list:FLEXKeychain.allAccounts.mutableCopy
        cellConfiguration:^(__kindof FLEXTableViewCell *cell, NSDictionary *item, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
            id account = item[kFLEXKeychainAccountKey];
            if ([account isKindOfClass:[NSString class]]) {
                cell.textLabel.text = account;
            } else {
                cell.textLabel.text = [NSString stringWithFormat:
                    @"[%@]\n\n%@",
                    NSStringFromClass([account class]),
                    [account description]
                ];
            }
        } filterMatcher:^BOOL(NSString *filterText, NSDictionary *item) {
            // Loop over contents of the keychain item looking for a match
            for (NSString *field in item.allValues) {
                if ([field isKindOfClass:[NSString class]]) {
                    if ([field localizedCaseInsensitiveContainsString:filterText]) {
                        return YES;
                    }
                }
            }
            
            return NO;
        }
    ];
    
    return @[self.section];
}

/// We always want to show this section
- (NSArray<FLEXTableViewSection *> *)nonemptySections {
    return @[self.section];
}

- (void)reloadSections {
    self.section.list = FLEXKeychain.allAccounts.mutableCopy;
}

- (void)refreshSectionTitle {
    self.section.customTitle = FLEXPluralString(
        self.section.filteredList.count, @"items", @"item"
    );
}

- (void)reloadData {
    [self reloadSections];
    [self refreshSectionTitle];
    [super reloadData];
}


#pragma mark - Private

- (FLEXKeychainQuery *)queryForItemAtIndex:(NSInteger)idx {
    NSDictionary *item = self.section.filteredList[idx];

    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = item[kFLEXKeychainWhereKey];
    query.account = item[kFLEXKeychainAccountKey];
    [query fetch:nil];

    return query;
}

- (void)deleteItem:(NSDictionary *)item {
    NSError *error = nil;
    BOOL success = [FLEXKeychain
        deletePasswordForService:item[kFLEXKeychainWhereKey]
        account:item[kFLEXKeychainAccountKey]
        error:&error
    ];

    if (!success) {
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(@"Error Deleting Item");
            make.message(error.localizedDescription);
        } showFrom:self];
    }
}


#pragma mark Buttons

- (void)trashPressed:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.title(@"Clear Keychain");
        make.message(@"This will remove all keychain items for this app.\n");
        make.message(@"This action cannot be undone. Are you sure?");
        make.button(@"Yes, clear the keychain").destructiveStyle().handler(^(NSArray *strings) {
            for (id account in self.section.list) {
                [self deleteItem:account];
            }

            [self reloadData];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}

- (void)addPressed {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Add Keychain Item");
        make.textField(@"Service name, i.e. Instagram");
        make.textField(@"Account");
        make.textField(@"Password");
        make.button(@"Cancel").cancelStyle();
        make.button(@"Save").handler(^(NSArray<NSString *> *strings) {
            // Display errors
            NSError *error = nil;
            if (![FLEXKeychain setPassword:strings[2] forService:strings[0] account:strings[1] error:&error]) {
                [FLEXAlert showAlert:@"Error" message:error.localizedDescription from:self];
            }

            [self reloadData];
        });
    } showFrom:self];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"🔑  Keychain";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    FLEXKeychainViewController *viewController = [self new];
    viewController.title = [self globalsEntryTitle:row];

    return viewController;
}


#pragma mark - Table View Data Source

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style == UITableViewCellEditingStyleDelete) {
        // Update the model
        NSDictionary *toRemove = self.section.filteredList[ip.row];
        [self deleteItem:toRemove];
        [self.section mutate:^(NSMutableArray *list) {
            [list removeObject:toRemove];
        }];
    
        // Delete the row
        [tv deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // Update the title by refreshing the section without disturbing the delete animation
        //
        // This is an ugly hack, but literally nothing else works, save for manually getting
        // the header and setting its title, which I personally think is worse since it
        // would need to make assumptions about the default style of the header (CAPS)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self refreshSectionTitle];
            [tv reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}


#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXKeychainQuery *query = [self queryForItemAtIndex:indexPath.row];
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(query.service);
        make.message(@"Service: ").message(query.service);
        make.message(@"\nAccount: ").message(query.account);
        make.message(@"\nPassword: ").message(query.password);

        make.button(@"Copy Service").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.service];
        });
        make.button(@"Copy Account").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.account];
        });
        make.button(@"Copy Password").handler(^(NSArray<NSString *> *strings) {
            [UIPasteboard.generalPasteboard flex_copy:query.password];
        });
        make.button(@"Dismiss").cancelStyle();
        
    } showFrom:self];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
