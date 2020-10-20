//
//  FLEXNetworkTransactionCell.m
//  Flipboard
//
//  Created by Ryan Olson on 2/8/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXNetworkTransactionCell.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"

NSString *const kFLEXNetworkTransactionCellIdentifier = @"kFLEXNetworkTransactionCellIdentifier";

@interface FLEXNetworkTransactionCell ()

@property (nonatomic) UIImageView *thumbnailImageView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *pathLabel;
@property (nonatomic) UILabel *transactionDetailsLabel;

@end

@implementation FLEXNetworkTransactionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.nameLabel = [UILabel new];
        self.nameLabel.font = UIFont.flex_defaultTableCellFont;
        [self.contentView addSubview:self.nameLabel];

        self.pathLabel = [UILabel new];
        self.pathLabel.font = UIFont.flex_defaultTableCellFont;
        self.pathLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        [self.contentView addSubview:self.pathLabel];

        self.thumbnailImageView = [UIImageView new];
        self.thumbnailImageView.layer.borderColor = UIColor.blackColor.CGColor;
        self.thumbnailImageView.layer.borderWidth = 1.0;
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.thumbnailImageView];

        self.transactionDetailsLabel = [UILabel new];
        self.transactionDetailsLabel.font = [UIFont systemFontOfSize:10.0];
        self.transactionDetailsLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        [self.contentView addSubview:self.transactionDetailsLabel];
    }
    return self;
}

- (void)setTransaction:(FLEXNetworkTransaction *)transaction {
    if (_transaction != transaction) {
        _transaction = transaction;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat kVerticalPadding = 8.0;
    const CGFloat kLeftPadding = 10.0;
    const CGFloat kImageDimension = 32.0;

    CGFloat thumbnailOriginY = round((self.contentView.bounds.size.height - kImageDimension) / 2.0);
    self.thumbnailImageView.frame = CGRectMake(kLeftPadding, thumbnailOriginY, kImageDimension, kImageDimension);
    self.thumbnailImageView.image = self.transaction.responseThumbnail;

    CGFloat textOriginX = CGRectGetMaxX(self.thumbnailImageView.frame) + kLeftPadding;
    CGFloat availableTextWidth = self.contentView.bounds.size.width - textOriginX;

    self.nameLabel.text = [self nameLabelText];
    CGSize nameLabelPreferredSize = [self.nameLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    self.nameLabel.frame = CGRectMake(textOriginX, kVerticalPadding, availableTextWidth, nameLabelPreferredSize.height);
    self.nameLabel.textColor = (self.transaction.error || [FLEXUtility isErrorStatusCodeFromURLResponse:self.transaction.response]) ? UIColor.redColor : FLEXColor.primaryTextColor;

    self.pathLabel.text = [self pathLabelText];
    CGSize pathLabelPreferredSize = [self.pathLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat pathLabelOriginY = ceil((self.contentView.bounds.size.height - pathLabelPreferredSize.height) / 2.0);
    self.pathLabel.frame = CGRectMake(textOriginX, pathLabelOriginY, availableTextWidth, pathLabelPreferredSize.height);

    self.transactionDetailsLabel.text = [self transactionDetailsLabelText];
    CGSize transactionLabelPreferredSize = [self.transactionDetailsLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat transactionDetailsOriginX = textOriginX;
    CGFloat transactionDetailsLabelOriginY = CGRectGetMaxY(self.contentView.bounds) - kVerticalPadding - transactionLabelPreferredSize.height;
    CGFloat transactionDetailsLabelWidth = self.contentView.bounds.size.width - transactionDetailsOriginX;
    self.transactionDetailsLabel.frame = CGRectMake(transactionDetailsOriginX, transactionDetailsLabelOriginY, transactionDetailsLabelWidth, transactionLabelPreferredSize.height);
}

- (NSString *)nameLabelText {
    NSURL *url = self.transaction.request.URL;
    NSString *name = [url lastPathComponent];
    if (name.length == 0) {
        name = @"/";
    }
    NSString *query = [url query];
    if (query) {
        name = [name stringByAppendingFormat:@"?%@", query];
    }
    return name;
}

- (NSString *)pathLabelText {
    NSURL *url = self.transaction.request.URL;
    NSMutableArray<NSString *> *mutablePathComponents = url.pathComponents.mutableCopy;
    if (mutablePathComponents.count > 0) {
        [mutablePathComponents removeLastObject];
    }
    NSString *path = [url host];
    for (NSString *pathComponent in mutablePathComponents) {
        path = [path stringByAppendingPathComponent:pathComponent];
    }
    return path;
}

- (NSString *)transactionDetailsLabelText {
    NSMutableArray<NSString *> *detailComponents = [NSMutableArray new];

    NSString *timestamp = [[self class] timestampStringFromRequestDate:self.transaction.startTime];
    if (timestamp.length > 0) {
        [detailComponents addObject:timestamp];
    }

    // Omit method for GET (assumed as default)
    NSString *httpMethod = self.transaction.request.HTTPMethod;
    if (httpMethod.length > 0) {
        [detailComponents addObject:httpMethod];
    }

    if (self.transaction.transactionState == FLEXNetworkTransactionStateFinished || self.transaction.transactionState == FLEXNetworkTransactionStateFailed) {
        NSString *statusCodeString = [FLEXUtility statusCodeStringFromURLResponse:self.transaction.response];
        if (statusCodeString.length > 0) {
            [detailComponents addObject:statusCodeString];
        }

        if (self.transaction.receivedDataLength > 0) {
            NSString *responseSize = [NSByteCountFormatter stringFromByteCount:self.transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
            [detailComponents addObject:responseSize];
        }

        NSString *totalDuration = [FLEXUtility stringFromRequestDuration:self.transaction.duration];
        NSString *latency = [FLEXUtility stringFromRequestDuration:self.transaction.latency];
        NSString *duration = [NSString stringWithFormat:@"%@ (%@)", totalDuration, latency];
        [detailComponents addObject:duration];
    } else {
        // Unstarted, Awaiting Response, Receiving Data, etc.
        NSString *state = [FLEXNetworkTransaction readableStringFromTransactionState:self.transaction.transactionState];
        [detailComponents addObject:state];
    }

    return [detailComponents componentsJoinedByString:@" ・ "];
}

+ (NSString *)timestampStringFromRequestDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm:ss";
    });
    return [dateFormatter stringFromDate:date];
}

+ (CGFloat)preferredCellHeight {
    return 65.0;
}

@end
