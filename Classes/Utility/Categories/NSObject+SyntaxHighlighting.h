//
//  NSObject+SyntaxHighlighting.h
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+SyntaxHighlighting.h"

@interface NSObject (SyntaxHighlighting)
@property (readonly, copy) NSAttributedString *attributedDescription;
@property (readonly, copy) NSAttributedString *attributedDebugDescription;
@end
