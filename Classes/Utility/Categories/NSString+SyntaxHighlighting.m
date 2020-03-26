//
//  NSString+SyntaxHighlighting.m
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "NSString+SyntaxHighlighting.h"

@implementation NSString (SyntaxHighlighting)
- (NSAttributedString *)attributedString {
    return [[NSAttributedString alloc] initWithString:self];
}
- (NSAttributedString *)mutableAttributedString {
    return [[NSMutableAttributedString alloc] initWithString:self];
}
- (NSAttributedString *)plainTextAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.plainTextColor }];
}
- (NSAttributedString *)commentsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.commentsColor }];
}
- (NSAttributedString *)documentationMarkupAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.documentationMarkupColor }];
}
- (NSAttributedString *)documentationMarkupKeywordsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.documentationMarkupKeywordsColor }];
}
- (NSAttributedString *)marksAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.marksColor }];
}
- (NSAttributedString *)stringsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.stringsColor }];
}
- (NSAttributedString *)charactersAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.charactersColor }];
}
- (NSAttributedString *)numbersAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.numbersColor }];
}
- (NSAttributedString *)keywordsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.keywordsColor }];
}
- (NSAttributedString *)preprocessorStatementsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.preprocessorStatementsColor }];
}
- (NSAttributedString *)URLsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.URLsColor }];
}
- (NSAttributedString *)attributesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.attributesColor }];
}
- (NSAttributedString *)typeDeclarationsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.typeDeclarationsColor }];
}
- (NSAttributedString *)otherDeclarationsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherDeclarationsColor }];
}
- (NSAttributedString *)projectClassNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectClassNamesColor }];
}
- (NSAttributedString *)projectFunctionAndMethodNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectFunctionAndMethodNamesColor }];
}
- (NSAttributedString *)projectConstantsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectConstantsColor }];
}
- (NSAttributedString *)projectTypeNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectTypeNamesColor }];
}
- (NSAttributedString *)projectInstanceVariablesAndGlobalsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectInstanceVariablesAndGlobalsColor }];
}
- (NSAttributedString *)projectPreprocessorMacrosAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.projectPreprocessorMacrosColor }];
}
- (NSAttributedString *)otherClassNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherClassNamesColor }];
}
- (NSAttributedString *)otherFunctionAndMethodNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherFunctionAndMethodNamesColor }];
}
- (NSAttributedString *)otherConstantsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherConstantsColor }];
}
- (NSAttributedString *)otherTypeNamesAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherTypeNamesColor }];
}
- (NSAttributedString *)otherInstanceVariablesAndGlobalsAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherInstanceVariablesAndGlobalsColor }];
}
- (NSAttributedString *)otherPreprocessorMacrosAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.otherPreprocessorMacrosColor }];
}
- (NSAttributedString *)headingAttributedString {
    return [[NSAttributedString alloc] initWithString:self attributes:@{ NSForegroundColorAttributeName: FLEXColor.headingColor }];
}
@end
