//
//  FLEXViewControllersViewController.m
//  FLEX
//
//  Created by Tanner Bennett on 2/13/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXViewControllersViewController.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXViewControllersViewController ()
@property (nonatomic, readonly) NSArray<UIViewController *> *controllers;
@end

@implementation FLEXViewControllersViewController

#pragma mark - Initialization

+ (instancetype)controllersForViews:(NSArray<UIView *> *)views {
    return [[self alloc] initWithViews:views];
}

- (id)initWithViews:(NSArray<UIView *> *)views {
    NSParameterAssert(views.count);
    
    self = [self init];
    if (self) {
        _controllers = [views flex_mapped:^id(UIView *view, NSUInteger idx) {
            return [FLEXUtility viewControllerForView:view];
        }];
    }
    
    return self;
}

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"View Controllers at Tap";
    [self disableToolbar];
}


#pragma mark - Private

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.controllers.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"View Controllers";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXDetailCell forIndexPath:indexPath];
    UIViewController *controller = self.controllers[indexPath.row];
    
    cell.textLabel.text = [NSString
        stringWithFormat:@"%@ — %p", NSStringFromClass(controller.class), controller
    ];
    cell.detailTextLabel.text = controller.view.description;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController pushViewController:
        [FLEXObjectExplorerFactory explorerViewControllerForObject:self.controllers[indexPath.row]]
    animated:YES];
}

@end
