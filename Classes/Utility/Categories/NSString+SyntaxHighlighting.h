//
//  NSString+SyntaxHighlighting.h
//  FLEX
//
//  Created by Jacob Clayden on 25/03/2020.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXColor.h"

@interface NSString (SyntaxHighlighting)
- (NSAttributedString *)attributedString;
- (NSMutableAttributedString *)mutableAttributedString;
- (NSAttributedString *)plainTextAttributedString;
- (NSAttributedString *)commentsAttributedString;
- (NSAttributedString *)documentationMarkupAttributedString;
- (NSAttributedString *)documentationMarkupKeywordsAttributedString;
- (NSAttributedString *)marksAttributedString;
- (NSAttributedString *)stringsAttributedString;
- (NSAttributedString *)charactersAttributedString;
- (NSAttributedString *)numbersAttributedString;
- (NSAttributedString *)keywordsAttributedString;
- (NSAttributedString *)preprocessorStatementsAttributedString;
- (NSAttributedString *)URLsAttributedString;
- (NSAttributedString *)attributesAttributedString;
- (NSAttributedString *)typeDeclarationsAttributedString;
- (NSAttributedString *)otherDeclarationsAttributedString;
- (NSAttributedString *)projectClassNamesAttributedString;
- (NSAttributedString *)projectFunctionAndMethodNamesAttributedString;
- (NSAttributedString *)projectConstantsAttributedString;
- (NSAttributedString *)projectTypeNamesAttributedString;
- (NSAttributedString *)projectInstanceVariablesAndGlobalsAttributedString;
- (NSAttributedString *)projectPreprocessorMacrosAttributedString;
- (NSAttributedString *)otherClassNamesAttributedString;
- (NSAttributedString *)otherFunctionAndMethodNamesAttributedString;
- (NSAttributedString *)otherConstantsAttributedString;
- (NSAttributedString *)otherTypeNamesAttributedString;
- (NSAttributedString *)otherInstanceVariablesAndGlobalsAttributedString;
- (NSAttributedString *)otherPreprocessorMacrosAttributedString;
- (NSAttributedString *)headingAttributedString;
@end
