//
//  PTTableContentViewController.h
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXTableContentViewController : UIViewController

+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                   rows:(NSArray<NSArray<NSString *> *> *)rowData;

@end
