//
//  AAPLCatalogTableTableViewController.m
//  UICatalog
//
//  Created by Ryan Olson on 7/17/14.

#import "AAPLCatalogTableTableViewController.h"
#import "FLEXManager.h"

@interface AAPLCatalogTableTableViewController ()

@end

@implementation AAPLCatalogTableTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"FLEX" style:UIBarButtonItemStylePlain target:self action:@selector(flexButtonTapped:)];
}

- (void)flexButtonTapped:(id)sender
{
    // This call shows the FLEX toolbar if it's not already shown.
    [[FLEXManager sharedManager] showExplorer];
}

@end
