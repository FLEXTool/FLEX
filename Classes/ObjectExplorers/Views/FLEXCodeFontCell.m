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
    self.subtitleLabel.font = UIFont.flex_smallCodeFont;
    self.subtitleLabel.alpha = 0.5;
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
}

@end
