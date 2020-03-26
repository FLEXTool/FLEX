//
//  NSMutableAttributedString+FLEX.h
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSAttributedString+FLEX.h"

@interface NSMutableAttributedString (FLEX)
- (void)replaceOccurencesOfString:(NSAttributedString *)aString withString:(NSAttributedString *)replacement;
@end
