//
//  UIPasteboard+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 12/9/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPasteboard (FLEX)

/// For copying an object which could be a string, data, or number
- (void)flex_copy:(id)unknownType;

@end
