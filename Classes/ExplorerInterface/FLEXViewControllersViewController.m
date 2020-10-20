//
//  FLEXViewControllersViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 2/13/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXViewControllersViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXMutableListSection.h"
#import "FLEXUtility.h"

@interface FLEXViewControllersViewController ()
@property (nonatomic, readonly) FLEXMutableListSection *section;
@property (nonatomic, readonly) NSArray<UIViewController *> *controllers;
@end

@implementation FLEXViewControllersViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (instancetype)controllersForViews:(NSArray<UIView *> *)views {
    return [[self alloc] initWithViews:views];
}

- (id)initWithViews:(NSArray<UIView *> *)views {
    NSParameterAssert(views.count);
    
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _controllers = [views flex_mapped:^id(UIView *view, NSUInteger idx) {
            return [FLEXUtility viewControllerForView:view];
        }];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"View Controllers at Tap";
    self.showsSearchBar = YES;
    [self disableToolbar];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _section = [FLEXMutableListSection list:self.controllers
        cellConfiguration:^(UITableViewCell *cell, UIViewController *controller, NSInteger row) {
            cell.textLabel.text = [NSString
                stringWithFormat:@"%@ — %p", NSStringFromClass(controller.class), controller
            ];
            cell.detailTextLabel.text = controller.view.description;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    } filterMatcher:^BOOL(NSString *filterText, UIViewController *controller) {
        return [NSStringFromClass(controller.class) localizedCaseInsensitiveContainsString:filterText];
    }];
    
    self.section.selectionHandler = ^(UIViewController *host, UIViewController *controller) {
        [host.navigationController pushViewController:
            [FLEXObjectExplorerFactory explorerViewControllerForObject:controller]
        animated:YES];
    };
    
    self.section.customTitle = @"View Controllers";
    return @[self.section];
}


#pragma mark - Private

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
