//
//  PTTableContentViewController.h
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXTableContentViewController : UIViewController

@property (nonatomic) NSArray<NSString *> *columnsArray;
@property (nonatomic) NSArray<NSDictionary<NSString *, id> *> *contentsArray;

@end
