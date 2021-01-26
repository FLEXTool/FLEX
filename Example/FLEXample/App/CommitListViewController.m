//
//  CommitListViewController.m
//  FLEXample
//
//  Created by Tanner on 3/11/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "CommitListViewController.h"
#import "FLEXample-Swift.h"
#import "Person.h"
#import <FLEX.h>

@interface CommitListViewController ()
@property (nonatomic) FLEXMutableListSection<Commit *> *commits;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, UIImage *> *avatars;
@end

@implementation CommitListViewController

- (id)init {
    // Default style is grouped
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _avatars = [NSMutableDictionary new];
    
    self.title = @"FLEX Commit History";
    self.showsSearchBar = YES;
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem
        flex_itemWithTitle:@"FLEX" target:FLEXManager.sharedManager action:@selector(toggleExplorer)
    ];
    
    // Load and process commits
    NSString *commitsURL = @"https://api.github.com/repos/Flipboard/FLEX/commits";
    [self startDataTask:commitsURL completion:^(NSData *data, NSInteger statusCode, NSError *error) {
        if (statusCode == 200) {
            self.commits.list = [Commit commitsFrom:data];
            [self fadeInNewRows];
        } else {
            [FLEXAlert showAlert:@"Error"
                message:error.localizedDescription ?: @(statusCode).stringValue
                from:self
            ];
        }
    }];
    
    FLEXManager *flex = FLEXManager.sharedManager;
    
    // Register 't' for testing: quickly present an object explorer for debugging
    [flex registerSimulatorShortcutWithKey:@"t" modifiers:0 action:^{
        [flex showExplorer];
        [flex presentTool:^UINavigationController *{
            return [FLEXNavigationController withRootViewController:[FLEXObjectExplorerFactory
                explorerViewControllerForObject:Person.bob
            ]];
        } completion:nil];
    } description:@"Present an object explorer for debugging"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self disableToolbar];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _commits = [FLEXMutableListSection list:@[]
        cellConfiguration:^(__kindof UITableViewCell *cell, Commit *commit, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = commit.firstLine;
            cell.detailTextLabel.text = commit.secondLine;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//            cell.textLabel.numberOfLines = 2;
//            cell.detailTextLabel.numberOfLines = 3;
        
            UIImage *avi = self.avatars[commit.committer.login];
            if (avi) {
                cell.imageView.image = avi;
            } else {
                cell.tag = commit.identifier;
                [self loadImage:commit.committer.avatarUrl completion:^(UIImage *image) {
                    self.avatars[commit.committer.login] = image;
                    if (cell.tag == commit.identifier) {
                        cell.imageView.image = image;
                    } else {
                        [self.tableView reloadRowsAtIndexPaths:@[
                            [NSIndexPath indexPathForRow:row inSection:0]
                        ] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        } filterMatcher:^BOOL(NSString *filterText, Commit *commit) {
            return [commit matchesWithQuery:filterText];
        }
    ];
    
    self.commits.selectionHandler = ^(__kindof UIViewController *host, Commit *commit) {
        [host.navigationController pushViewController:[
            FLEXObjectExplorerFactory explorerViewControllerForObject:commit
        ] animated:YES];
    };
    
    return @[self.commits];
}

// Empty sections are removed by default and we always want this one section
- (NSArray<FLEXTableViewSection *> *)nonemptySections {
    return @[_commits];
}

- (void)fadeInNewRows {
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)loadImage:(NSString *)imageURL completion:(void(^)(UIImage *image))callback {
    [self startDataTask:imageURL completion:^(NSData *data, NSInteger statusCode, NSError *error) {
        if (statusCode == 200) {
            callback([UIImage imageWithData:data]);
        }
    }];
}

- (void)startDataTask:(NSString *)urlString completion:(void (^)(NSData *data, NSInteger statusCode, NSError *error))completionHandler {
//    return;
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger code = [(NSHTTPURLResponse *)response statusCode];
            
            completionHandler(data, code, error);
        });
    }] resume];
}

@end
