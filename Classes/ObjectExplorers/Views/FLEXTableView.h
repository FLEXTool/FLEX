//
//  FLEXTableView.h
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXTableView : UITableView

@property (nonatomic, readonly) NSString *defaultReuseIdentifier;
@property (nonatomic, readonly) NSString *subtitleReuseIdentifier;
@property (nonatomic, readonly) NSString *multilineReuseIdentifier;

@end
