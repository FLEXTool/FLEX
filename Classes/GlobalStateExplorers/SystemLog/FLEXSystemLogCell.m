//
//  FLEXSystemLogCell.m
//  FLEX
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXSystemLogCell.h"
#import "FLEXSystemLogMessage.h"
#import "UIFont+FLEX.h"
#import "NSDateFormatter+FLEX.h"

NSString *const kFLEXSystemLogCellIdentifier = @"FLEXSystemLogCellIdentifier";

@interface FLEXSystemLogCell ()

@property (nonatomic) UILabel *logMessageLabel;
@property (nonatomic) NSAttributedString *logMessageAttributedText;

@end

@implementation FLEXSystemLogCell

- (void)postInit {
    [super postInit];
    
    self.logMessageLabel = [UILabel new];
    self.logMessageLabel.numberOfLines = 0;
    self.separatorInset = UIEdgeInsetsZero;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.logMessageLabel];
}

- (void)setLogMessage:(FLEXSystemLogMessage *)logMessage {
    if (![_logMessage isEqual:logMessage]) {
        _logMessage = logMessage;
        self.logMessageAttributedText = nil;
        [self setNeedsLayout];
    }
}

- (void)setHighlightedText:(NSString *)highlightedText {
    if (![_highlightedText isEqual:highlightedText]) {
        _highlightedText = highlightedText;
        self.logMessageAttributedText = nil;
        [self setNeedsLayout];
    }
}

- (NSAttributedString *)logMessageAttributedText {
    if (!_logMessageAttributedText) {
        _logMessageAttributedText = [[self class] attributedTextForLogMessage:self.logMessage highlightedText:self.highlightedText];
    }
    return _logMessageAttributedText;
}

static const UIEdgeInsets kFLEXLogMessageCellInsets = {10.0, 10.0, 10.0, 10.0};

- (void)layoutSubviews {
    [super layoutSubviews];

    self.logMessageLabel.attributedText = self.logMessageAttributedText;
    self.logMessageLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, kFLEXLogMessageCellInsets);
}


#pragma mark - Stateless helpers

+ (NSAttributedString *)attributedTextForLogMessage:(FLEXSystemLogMessage *)logMessage highlightedText:(NSString *)highlightedText {
    NSString *text = [self displayedTextForLogMessage:logMessage];
    NSDictionary<NSString *, id> *attributes = @{ NSFontAttributeName : UIFont.flex_codeFont };
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];

    if (highlightedText.length > 0) {
        NSMutableAttributedString *mutableAttributedText = attributedText.mutableCopy;
        NSMutableDictionary<NSString *, id> *highlightAttributes = attributes.mutableCopy;
        highlightAttributes[NSBackgroundColorAttributeName] = UIColor.yellowColor;
        
        NSRange remainingSearchRange = NSMakeRange(0, text.length);
        while (remainingSearchRange.location < text.length) {
            remainingSearchRange.length = text.length - remainingSearchRange.location;
            NSRange foundRange = [text rangeOfString:highlightedText options:NSCaseInsensitiveSearch range:remainingSearchRange];
            if (foundRange.location != NSNotFound) {
                remainingSearchRange.location = foundRange.location + foundRange.length;
                [mutableAttributedText setAttributes:highlightAttributes range:foundRange];
            } else {
                break;
            }
        }
        attributedText = mutableAttributedText;
    }

    return attributedText;
}

+ (NSString *)displayedTextForLogMessage:(FLEXSystemLogMessage *)logMessage {
    return [NSString stringWithFormat:@"%@: %@", [self logTimeStringFromDate:logMessage.date], logMessage.messageText];
}

+ (CGFloat)preferredHeightForLogMessage:(FLEXSystemLogMessage *)logMessage inWidth:(CGFloat)width {
    UIEdgeInsets insets = kFLEXLogMessageCellInsets;
    CGFloat availableWidth = width - insets.left - insets.right;
    NSAttributedString *attributedLogText = [self attributedTextForLogMessage:logMessage highlightedText:nil];
    CGSize labelSize = [attributedLogText boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    return labelSize.height + insets.top + insets.bottom;
}

+ (NSString *)logTimeStringFromDate:(NSDate *)date {
    return [NSDateFormatter flex_stringFrom:date format:FLEXDateFormatVerbose];
}

@end
