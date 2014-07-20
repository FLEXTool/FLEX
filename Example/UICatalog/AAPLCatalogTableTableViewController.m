//
//  AAPLCatalogTableTableViewController.m
//  UICatalog
//
//  Created by Ryan Olson on 7/17/14.

#import "AAPLCatalogTableTableViewController.h"

#if DEBUG
// FLEX should only be compiled and used in debug builds.
#import "FLEXManager.h"
#endif

@interface AAPLCatalogTableTableViewController ()

@end

@implementation AAPLCatalogTableTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if DEBUG
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

@end
