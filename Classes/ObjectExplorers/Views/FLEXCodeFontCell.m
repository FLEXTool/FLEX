//
//  FLEXCodeFontCell.m
//  FLEX
//
//  Created by Tanner on 12/27/19.
//  Copyright © 2019 Flipboard. All rights reserved.
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
    self.subtitleLabel.numberOfLines = 5;
}

@end
