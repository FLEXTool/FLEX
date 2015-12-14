//
//  AAPLCatalogTableTableViewController.m
//  UICatalog
//
//  Created by Ryan Olson on 7/17/14.

#import "AAPLCatalogTableTableViewController.h"

#if DEBUG
// FLEX should only be compiled and used in debug builds.
#import <FLEX/FLEX.h>
#endif

@implementation AAPLCatalogTableTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if DEBUG
    [self registerViewControllerBasedOption];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"FLEX" style:UIBarButtonItemStylePlain target:self action:@selector(flexButtonTapped:)];
#endif
}

- (void)flexButtonTapped:(id)sender
{
#if DEBUG
    // This call shows the FLEX toolbar if it's not already shown.
    [[FLEXManager sharedManager] showExplorer];
#endif
}

- (void)registerViewControllerBasedOption
{
    // create UIViewController subclass
    UIViewController *viewController = [[UIViewController alloc] init];

    // fill it with some stuff
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    infoLabel.text = @"Add switches, notes or whatewer you wish to provide your testers with superpowers!";
    infoLabel.numberOfLines = 0;
    infoLabel.textAlignment = NSTextAlignmentCenter;

    UIView *view = viewController.view;
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview:infoLabel];

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[infoLabel]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(infoLabel)]];

    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[infoLabel]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(infoLabel)]];



    // return it in viewControllerFutureBlock
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"🛃  Custom Superpowers"
                                   viewControllerFutureBlock:^id{
                                       return viewController;
                                   }];
}

@end
