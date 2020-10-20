//
//  FLEXCodeFontCell.m
//  FLEX
//
//  Created by Tanner on 12/27/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXCodeFontCell.h"
#import "UIFont+FLEX.h"

@implementation FLEXCodeFontCell

- (void)postInit {
    [super postInit];
    
    self.titleLabel.font = UIFont.flex_codeFont;
    self.subtitleLabel.font = UIFont.flex_codeFont;

    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.9;
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.minimumScaleFactor = 0.75;
    
    // Disable mutli-line pre iOS 11
    if (@available(iOS 11, *)) {
        self.subtitleLabel.numberOfLines = 5;
    } else {
        self.titleLabel.numberOfLines = 1;
        self.subtitleLabel.numberOfLines = 1;
    }
}

@end
