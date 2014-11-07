//
//  FLEXInfoTableViewController.h
//  UICatalog
//
//  Created by Dal Rupnik on 07/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

@protocol FLEXViewControllerDelegate <NSObject>

- (void)viewControllerDidFinish:(UIViewController *)viewController;

@end

@interface FLEXInfoTableViewController : UITableViewController

@property (nonatomic, weak) id <FLEXViewControllerDelegate> delegate;

/// We pretend that one of the app's windows is still the key window, even though the explorer window may have become key.
/// We want to display debug state about the application, not about this tool.
+ (void)setApplicationWindow:(UIWindow *)applicationWindow;

@end

