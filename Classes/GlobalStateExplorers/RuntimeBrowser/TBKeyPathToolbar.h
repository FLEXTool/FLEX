//
//  TBKeyPathToolbar.h
//  TBTweakViewController
//
//  Created by Tanner on 6/11/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "TBKeyboardToolbar.h"
#import "TBKeyPath.h"


@interface TBKeyPathToolbar : TBKeyboardToolbar

+ (instancetype)toolbarWithHandler:(TBToolbarAction)tapHandler;

- (void)setKeyPath:(TBKeyPath *)keyPath animated:(BOOL)animated;

@end
